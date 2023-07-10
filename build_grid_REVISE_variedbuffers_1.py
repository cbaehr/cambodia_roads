
#base_path = "/Users/christianbaehr/Box Sync/cambodia_roads_inputs/data"
#base_path="/sciclone/data10/aiddata20/projects/cambodia_roads"
#base_path = "/Users/christianbaehr/Downloads/cambodia_roads_inputs_REVISE/data"
base_path = "/scratch/network/cb8007/cambodia_roads_inputs_REVISE/data"

import os
import geopandas as gpd
import pandas as pd

from osgeo import gdal, gdalconst, ogr, osr
import numpy
import sys
import rasterio
import rioxarray as rxr
import xarray
### MUST BE USING RASTERSTATS VERSION 0.13.1 !!!!!
from rasterstats import zonal_stats


##########

empty_grid_path = os.path.join(base_path, "REVISE_trimmed/empty_grid_2.5km.geojson")
#empty_grid_path = os.path.join(base_path, "empty_grid_test.geojson")

empty_grid = gpd.read_file(empty_grid_path)
empty_grid = empty_grid.sample(200)
empty_grid["cell_area"]=empty_grid.area

distances_path = os.path.join(base_path, "REVISE_trimmed/empty_grid_distances.csv")
distances = pd.read_csv(distances_path)

distances2 = distances[['id', 'distance']].dropna()
distances2 = distances2.sort_values(by=['distance'], axis=0, ascending=True)
distances2 = distances2.drop_duplicates(subset='id', keep="first")

empty_grid = empty_grid.merge(distances2, on='id', how='left')

empty_grid.rename(columns={"distance":"min_dist_to_road"}, inplace=True)

#empty_grid = empty_grid.loc[0:20500,]

###

### PUT MORE THOUGHT into how to filter different treatment characteristics into the data,
### i.e. new vs. used construction, multiple construction projects nearby at once,
### do I really need to subset and reproduce an entire new treatment measure each time?

trt_path = os.path.join(base_path, "geocoded roads/geocoded roads w import edited 4326_MultiRingBuffer.geojson")
trt = gpd.read_file(trt_path)
trt[["country"]] = "Cambodia"
trt_dissolve = trt[["country", "geometry"]]
trt_dissolve = trt_dissolve.dissolve(by="country")

keep_rows = empty_grid.geometry.centroid.intersects(trt_dissolve.geometry[0])
empty_grid = empty_grid.loc[keep_rows, :]
empty_grid.reset_index(inplace=True, drop=True)

###

grid = empty_grid.copy()
cent = grid.geometry.centroid
coords = [(x,y) for x, y in zip(cent.x, cent.y)]


##########

empty_grid_cent = empty_grid.copy()
empty_grid_cent["geometry"]=empty_grid_cent.geometry.centroid

trt.loc[trt["end.date"]=="11/31/2016", "end.date"] = "11/30/16"
trt["end.date"] = pd.to_datetime(trt["end.date"], format="%m/%d/%y")

trt_grid = gpd.sjoin(empty_grid_cent, trt, op="intersects", how="left")

min_years = trt_grid.groupby("id")["end.date"].min()
#min_years = trt_grid.groupby("id")["end.date"].min().reset_index()

keep_grid = trt_grid.merge(min_years, left_on="id", right_index=True)
#keep_grid = trt_grid.merge(min_years, on="id")

keep_rows = keep_grid["end.date_x"]==keep_grid["end.date_y"]
trt_grid = trt_grid.loc[keep_rows, :].reset_index(drop=True)

trt_grid=trt_grid[~trt_grid["id"].duplicated()].reset_index(drop=True)

#grid = pd.concat([grid, trt_grid[["transactions_start_year", "end.date", "work.type"]]], axis=1)
grid = pd.concat([grid, trt_grid[["project_id", "transactions_start_year", "end.date", "work.type", "confidence", "mrb_dist"]]], axis=1)
grid.rename({"end.date":"end_date", "work.type":"work_type"}, axis=1, inplace=True)

#del empty_grid_cent, trt


###

adm_file = os.path.join(base_path, "gadm36_KHM_3.geojson")

adm = gpd.read_file(adm_file)

empty_grid_cent = empty_grid.copy()
empty_grid_cent.geometry=empty_grid_cent.geometry.centroid

adm_grid = gpd.sjoin(empty_grid_cent, adm, op="intersects", how="left").drop_duplicates().drop(["left", "top", "right", "bottom", "index_right", "geometry"],axis=1)

grid = grid.merge(adm_grid, on="id")

drop_rows = grid.GID_3.isnull().values

grid=grid[~drop_rows].reset_index(drop=True)

###

empty_grid_out = os.path.join(base_path, "empty_grid_trimmed_REVISE_variedbuffers_1.geojson")
grid[['left', 'top', 'right', 'bottom', 'id', 'geometry']].to_file(empty_grid_out, driver="GeoJSON")


##########

lc_file = os.path.join(base_path, "landconcessions.geojson")

landconcession= gpd.read_file(lc_file)

lc_dum = landconcession["contract_0"]=="Not found"
landconcession.loc[lc_dum, "contract_0"] = landconcession.loc[lc_dum, "sub_decree"]

landconcession = landconcession.to_crs("EPSG:4326")

lc_grid = gpd.sjoin(grid[["id","geometry"]], landconcession[["contract_0", "geometry"]], op="intersects", how="left")

min_years_lc = lc_grid.groupby("id")["contract_0"].min()

grid = grid.merge(min_years_lc, left_on="id", right_index=True)


###


pa_file = os.path.join(base_path, "protectedareas.geojson")

protectedarea= gpd.read_file(pa_file)

protectedarea.loc[protectedarea["issuedate"]=="01 Nov 1993", "issuedate"] = "01/11/1993"

protectedarea["issuedate"] = pd.to_datetime(protectedarea["issuedate"], format="%d/%m/%Y")

protectedarea = protectedarea.to_crs("EPSG:4326")

pa_grid = gpd.sjoin(grid[["id","geometry"]], protectedarea[["issuedate", "geometry"]], op="intersects", how="left")
#pa_grid.index.name = None

min_years_pa = pa_grid.groupby("id")["issuedate"].min()
min_years_pa.index.name = None

grid = grid.merge(min_years_pa, left_on="id", right_index=True)


# tree plantation data maybe not useful. Based on satellite imagery so endogenous

#tp_file = os.path.join(base_path, "treeplantations.geojson")

#plantation= gpd.read_file(tp_file)

###

plantation_path=os.path.join(base_path, "treeplantations.geojson")

plantation=gpd.read_file(plantation_path)
plantation[["country"]] = "Cambodia"

pl_dissolve = plantation[["country", "geometry"]]
pl_dissolve=pl_dissolve.dissolve(by="country")

pl_int = grid.geometry.intersects(pl_dissolve.geometry[0])
pl_int=pl_int*1

grid["plantation"]=pl_int

##########

for i in range(1999, 2021):
	file_name="landsatndvi_"+str(i)+".tif"
	path_name=os.path.join(base_path, "landsat", file_name)
	ndvi=rasterio.open(path_name)
	affine=ndvi.transform
	array=ndvi.read(1)
	array[array==-10000] = -9999
	stats=zonal_stats(grid, array, affine=affine, nodata=-9999)
	stats_df=pd.DataFrame(stats)
	stats_df.columns=["ndvi_"+str(j)+str(i) for j in stats_df.columns]
	grid=pd.concat([grid, stats_df], axis=1)

###

#bands = {1:"treecover", 2:"nontreeveg", 3:"nonveg"}

#for i in range(2000, 2020):
#	src_file="MODIS_VCF"+str(i)+"_FINAL.tif"
#	src_filename=os.path.join(base_path, "vcf/process/final", src_file)
#	dat = rasterio.open(src_filename)
#	cloud = (dat.read(4)>3)
#	quality = (dat.read(5)>2)
#	mask = numpy.logical_or(cloud, quality)
#	mid_filename = os.path.join(base_path, "temp1.tif")
#	for num, name in bands.items():
#		with rasterio.Env():
#			# Write an array as a raster band to a new 8-bit file. For
#			# the new file's profile, we start with the profile of the source
#			profile = dat.profile
#			array = dat.read(num)
#			array[mask]=200
#			# And then change the band count to 1, set the
#			# dtype to uint8, and specify LZW compression.
#			profile.update(dtype=rasterio.float32, count=1, compress='lzw')
#			with rasterio.open(mid_filename, 'w', **profile) as dst:
#				dst.write(array.astype(rasterio.float32), 1)
#		# Source
#		#src_filename = os.path.join(base_path, "vcf/process/final/MODIS_VCF"+str(i)+"_FINAL.tif")
#		src = gdal.Open(mid_filename, gdalconst.GA_ReadOnly)
#		src_proj = src.GetProjection()
#		src_geotrans = src.GetGeoTransform()
#		# We want a section of source that matches this:
#		match_filename = os.path.join(base_path, "landsat/landsatndvi_2010.tif")
#		match_ds = gdal.Open(match_filename, gdalconst.GA_ReadOnly)
#		match_proj = match_ds.GetProjection()
#		match_geotrans = match_ds.GetGeoTransform()
#		wide = match_ds.RasterXSize
#		high = match_ds.RasterYSize
#		# Output / destination
#		dst_filename = os.path.join(base_path, "temp2.tif")
#		dst = gdal.GetDriverByName('Gtiff').Create(dst_filename, wide, high, 1, gdalconst.GDT_Float32)
#		dst.SetGeoTransform( match_geotrans )
#		dst.SetProjection( match_proj)
#		# Do the work
#		dst.GetRasterBand(1).SetNoDataValue(200)
#		dst.GetRasterBand(1).Fill(200)
#		gdal.ReprojectImage(src, dst, src_proj, match_proj, gdalconst.GRA_Bilinear)
#		del dst # Flush
#		print ("finish")
#		vcf=rasterio.open(dst_filename)
#		affine=vcf.transform
#		array=vcf.read(1)
#		stats=zonal_stats(grid, array, affine=affine, nodata=200)
#		stats_df=pd.DataFrame(stats)
#		stats_df.columns=["vcf_"+name+"_"+str(j)+str(i) for j in stats_df.columns]
#		grid=pd.concat([grid, stats_df], axis=1)

###

treecover_path = os.path.join(base_path, "hansen/Hansen_GFC-2019-v1.7_treecover2000_20N_100E.tif")
treecover = rxr.open_rasterio(treecover_path)
treecover_array = treecover.values.squeeze()

mask_path = os.path.join(base_path, "hansen/Hansen_GFC-2019-v1.7_datamask_20N_100E.tif")
mask = rxr.open_rasterio(mask_path)
mask_array = mask.values.squeeze()

gain_path = os.path.join(base_path, "hansen/Hansen_GFC-2019-v1.7_gain_20N_100E.tif")
gain = rxr.open_rasterio(gain_path)
gain_array = gain.values.squeeze()

loss_path = os.path.join(base_path, "hansen/Hansen_GFC-2019-v1.7_lossyear_20N_100E.tif")
loss = rxr.open_rasterio(loss_path)
loss_array = loss.values.squeeze()

treecover_dum = (treecover_array>=25) * 1
tc_mask = numpy.logical_or(gain_array==1, mask_array!=1)
#temp_path = os.path.join(base_path, "temp.tif")


for year in range(2000, 2020):
	if year==2000:
		tc_temp=treecover_dum
	else:
		loss_dum = numpy.logical_and(loss_array==(year-2000), treecover_dum==1)
		loss_dum = loss_dum*1
		tc_temp = tc_temp-loss_dum
	tc_temp[tc_mask] = 5
	tc_out = numpy.expand_dims(tc_temp, axis=0)
	out_arr = xarray.DataArray(tc_out, coords=[treecover.band, treecover.y, treecover.x])
	mid_filename = os.path.join(base_path, "temp1.tif")
	out_arr.astype("int8").rio.set_crs(4326).rio.write_nodata(5).rio.to_raster(mid_filename)
	#src = gdal.Open(temp_filename, gdalconst.GA_ReadOnly)
	hansen=rasterio.open(mid_filename)
	affine=hansen.transform
	array=hansen.read(1)
	stats=zonal_stats(grid, array, affine=affine, nodata=5)
	stats_df=pd.DataFrame(stats)
	stats_df.columns=["hansen_"+str(j)+str(year) for j in stats_df.columns]
	grid=pd.concat([grid, stats_df], axis=1)


###


for i in range(2000, 2020):
	file_name="cru_precip_{}.tif".format(i)
	path_name=os.path.join(base_path, "cru_precip", file_name)
	src = gdal.Open(path_name, gdalconst.GA_ReadOnly)
	src_geotrans = src.GetGeoTransform()
	src_proj = src.GetProjection()
	# We want a section of source that matches this:
	match_filename = os.path.join(base_path, "landsat/landsatndvi_2010.tif")
	match_ds = gdal.Open(match_filename, gdalconst.GA_ReadOnly)
	match_proj = match_ds.GetProjection()
	match_geotrans = match_ds.GetGeoTransform()
	wide = match_ds.RasterXSize
	high = match_ds.RasterYSize
	dst_filename = os.path.join(base_path, "temp2.tif")
	dst = gdal.GetDriverByName('Gtiff').Create(dst_filename, wide, high, 1, gdalconst.GDT_Float32)
	dst.SetGeoTransform( match_geotrans )
	dst.SetProjection( match_proj)
	gdal.ReprojectImage(src, dst, src_proj, match_proj, gdalconst.GRA_NearestNeighbour)
	del dst # Flush
	precip=rasterio.open(dst_filename)
	affine=precip.transform
	array=precip.read(1)
	stats=zonal_stats(grid, array, affine=affine, nodata=0)
	stats_df=pd.DataFrame(stats)
	stats_df.columns=["precipitation_"+str(j)+str(i) for j in stats_df.columns]
	grid=pd.concat([grid, stats_df], axis=1)
	print(str(i))
	del array

###


for i in range(2000, 2021):
	file_name="modislst_temp_{}.tif".format(i)
	path_name=os.path.join(base_path, "modis_lst", file_name)
	src = gdal.Open(path_name, gdalconst.GA_ReadOnly)
	src_geotrans = src.GetGeoTransform()
	src_proj = src.GetProjection()
	# We want a section of source that matches this:
	match_filename = os.path.join(base_path, "landsat/landsatndvi_2010.tif")
	match_ds = gdal.Open(match_filename, gdalconst.GA_ReadOnly)
	match_proj = match_ds.GetProjection()
	match_geotrans = match_ds.GetGeoTransform()
	wide = match_ds.RasterXSize
	high = match_ds.RasterYSize
	dst_filename = os.path.join(base_path, "temp2.tif")
	dst = gdal.GetDriverByName('Gtiff').Create(dst_filename, wide, high, 1, gdalconst.GDT_Float32)
	dst.SetGeoTransform( match_geotrans )
	dst.SetProjection( match_proj)
	gdal.ReprojectImage(src, dst, src_proj, match_proj, gdalconst.GRA_Bilinear)
	del dst # Flush
	temperat=rasterio.open(dst_filename)
	affine=temperat.transform
	array=temperat.read(1)
	dum=numpy.isnan(array)
	array[dum] = 0
	stats=zonal_stats(grid, array, affine=affine, nodata=0)
	stats_df=pd.DataFrame(stats)
	stats_df.columns=["temperature_"+str(j)+str(i) for j in stats_df.columns]
	grid=pd.concat([grid, stats_df], axis=1)
	print(str(i))
	del array

###

for i in [2000,2005,2010,2015,2020]:
	file_name="gpw_density_{}.tif".format(i)
	path_name=os.path.join(base_path, "population_density", file_name)
	src = gdal.Open(path_name, gdalconst.GA_ReadOnly)
	src_geotrans = src.GetGeoTransform()
	src_proj = src.GetProjection()
	# We want a section of source that matches this:
	match_filename = os.path.join(base_path, "landsat/landsatndvi_2010.tif")
	match_ds = gdal.Open(match_filename, gdalconst.GA_ReadOnly)
	match_proj = match_ds.GetProjection()
	match_geotrans = match_ds.GetGeoTransform()
	wide = match_ds.RasterXSize
	high = match_ds.RasterYSize
	dst_filename = os.path.join(base_path, "temp2.tif")
	dst = gdal.GetDriverByName('Gtiff').Create(dst_filename, wide, high, 1, gdalconst.GDT_Float32)
	dst.SetGeoTransform( match_geotrans )
	dst.SetProjection( match_proj)
	gdal.ReprojectImage(src, dst, src_proj, match_proj, gdalconst.GRA_NearestNeighbour)
	del dst # Flush
	pop=rasterio.open(dst_filename)
	affine=pop.transform
	array=pop.read(1)
	stats=zonal_stats(grid, array, affine=affine, nodata=-9999)
	stats_df=pd.DataFrame(stats)
	stats_df.columns=["population_"+str(j)+str(i) for j in stats_df.columns]
	grid=pd.concat([grid, stats_df], axis=1)
	print(str(i))
	del array

###

dst_filename=os.path.join(base_path, "distance_to_road.tif")
roaddist=rasterio.open(dst_filename)
affine=roaddist.transform
array=roaddist.read(1)
stats=zonal_stats(grid, array, affine=affine, nodata=-9999)
stats_df=pd.DataFrame(stats)
stats_df.columns=["distance_to_road_" + str(i) for i in stats_df.columns]
grid=pd.concat([grid, stats_df], axis=1)

###

for i in range(2008, 2021):
	ma_path=os.path.join(base_path, "market_access/market_access_{}_merged_majorONLY.geojson".format(i))
	ma=gpd.read_file(ma_path)
	grid["ma_minutes_bigcity_{}".format(i)]=ma.shortest_distance /60

ma10_path=os.path.join(base_path, "market_access/market_access_2010_merged.geojson")
ma10=gpd.read_file(ma10_path)

ma15_path=os.path.join(base_path, "market_access/market_access_2015_merged.geojson")
ma15=gpd.read_file(ma15_path)

ma20_path=os.path.join(base_path, "market_access/market_access_2020_merged.geojson")
ma20=gpd.read_file(ma20_path)


grid["ma_minutes_2010"] = ma10.shortest_distance /60
grid["ma_minutes_2015"] = ma15.shortest_distance /60
grid["ma_minutes_2020"] = ma20.shortest_distance /60

###

mkt_polygon_path =os.path.join(base_path, "market_access/market_polygons_2000.geojson")
mkt_polygon=gpd.read_file(mkt_polygon_path)
mkt_polygon[["country"]]="Cambodia"

mkt_polygon_dissolve=mkt_polygon[["country", "geometry"]].dissolve(by="country")

mkt_polygon_int=grid.geometry.intersects(mkt_polygon_dissolve.geometry[0])

grid.loc[mkt_polygon_int, ["ma_minutes_2010", "ma_minutes_2015", "ma_minutes_2020"]] = 0

ma_names = ["ma_minutes_bigcity_{}".format(i) for i in range(2008, 2021)]
grid.loc[mkt_polygon_int, ma_names] = 0


###

minecas_path=os.path.join(base_path, "mine-and-erw-causality-2005-2013.geojson")
minecas = gpd.read_file(minecas_path)

minecas["incyear"]=minecas["Incident_D"].str.slice(stop=4)

minecas=minecas.to_crs("EPSG:4326")

x=gpd.sjoin(grid[["id", "geometry"]], minecas, op="intersects", how="left")
x["incyear"]=x["incyear"].astype("str")

y=x.pivot_table(values="incyear", index="id", aggfunc='|'.join)

z = y["incyear"].to_list()

def build(year_str):
	j = year_str.split('|')
	return {i:j.count(i) for i in set(j)}

z = list(map(build, z))
z = pd.DataFrame(z)

z.drop(["nan"], axis=1, inplace=True)

#for i in range(2005, 2014):
#	z.loc[z[str(i)].isnull(), str(i)] = 0

for i in sorted(z.columns.tolist()):
	z.loc[z[str(i)].isnull(), str(i)] = 0

z.columns=["minecasualty"+str(i) for i in z.columns]

grid = pd.concat([grid, z], axis=1)

###

for i in range(2008, 2021):
	ma_path = os.path.join(base_path, "market_access/market_access_{}_majorONLY_2008roadsonly.geojson".format(i))
	ma = gpd.read_file(ma_path)
	if "shortest_distance_min" not in ma.columns:
		ma["shortest_distance_min"] = ma["shortest_distance"] / 60
	col_name = "ma_minutes_2008roadsonly_{}".format(i)
	grid[col_name] = ma["shortest_distance_min"]

for i in range(2008, 2021):
	grid["ma_minutes_2008roadsonly_{}".format(i)].describe()

##########

grid.drop(["left", "top", "right", "bottom"], axis=1, inplace=True)

a=grid.geometry.centroid
grid["x"]=a.x
grid["y"]=a.y


csv_out=os.path.join(base_path, "cambodia_roads_grid_REVISE_variedbuffers_1.csv")
grid.drop(["geometry"],axis=1).to_csv(csv_out, index=False)


geo_out=os.path.join(base_path, "cambodia_roads_grid_REVISE_variedbuffers_1.geojson")
grid.to_file(geo_out, driver="GeoJSON")



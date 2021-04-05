
base_path = "/Users/christianbaehr/Desktop/cambodia roads/data"

import os
import geopandas as gpd
import pandas as pd

from osgeo import gdal, gdalconst, ogr, osr
import numpy
import sys
import rasterio
import rioxarray as rxr
import xarray

#https://gist.github.com/cbaehr/bcdec33c490ac6162f37c53fa92d3d9c - this is my zonal statistics implementation 
#sys.path.append("/Users/christianbaehr/Github/zonal_stats")
#from zonal_stats import zonal_stats

##########

#khm_extent = gpd.read_file(os.path.join(base_path, "sample_extent.geojson"))

#empty_grid_path = os.path.join(base_path, "empty_grid_32648.geojson")
empty_grid_path = os.path.join(base_path, "empty_grid_32648_test.geojson")

empty_grid = gpd.read_file(empty_grid_path)

#keep_rows = empty_grid.geometry.intersects(khm_extent.geometry[0])
#empty_grid = empty_grid.loc[keep_rows, :]
#empty_grid.reset_index(inplace=True, drop=True)
#empty_grid.to_file("/Users/christianbaehr/Desktop/cambodia roads/data/empty_grid_test.geojson", driver="GeoJSON")

###

### PUT MORE THOUGHT into how to filter different treatment characteristics into the data,
### i.e. new vs. used construction, multiple construction projects nearby at once,
### do I really need to subset and reproduce an entire new treatment measure each time?

trt_path = os.path.join(base_path, "geocoded roads/geocoded roads w import edited.geojson")
trt = gpd.read_file(trt_path)

trt["geometry"] = trt["geometry"].buffer(0.1)

trt[["country"]] = "Cambodia"

trt=trt.to_crs("EPSG:32648")

trt_dissolve = trt[["country", "geometry"]]
trt_dissolve = trt_dissolve.dissolve(by="country")

keep_rows = empty_grid.intersects(trt_dissolve.geometry[0])
empty_grid = empty_grid.loc[keep_rows, :]
empty_grid.reset_index(inplace=True, drop=True)

###

grid = empty_grid.copy()
cent = grid.geometry.centroid
coords = [(x,y) for x, y in zip(cent.x, cent.y)]

##########

#trt[["transactions_start_year", "end.date", ""]]

trt["end.date"] = pd.to_datetime(trt["end.date"], format="%m/%d/%y")

trt_grid = gpd.sjoin(empty_grid, trt, op="intersects", how="left")

min_years = trt_grid.groupby("id")["end.date"].min()

keep_grid = trt_grid.merge(min_years, left_on="id", right_index=True)

keep_rows = keep_grid["end.date_x"]==keep_grid["end.date_y"]

trt_grid = trt_grid.loc[keep_rows, :].reset_index(drop=True)

grid = pd.concat([grid, trt_grid[["transactions_start_year", "end.date", "work.type"]]], axis=1)
grid.rename({"end.date":"end_date", "work.type":"work_type"}, axis=1, inplace=True)

##########

lc_file = os.path.join(base_path, "landconcessions.geojson")

landconcession= gpd.read_file(lc_file)
landconcession=landconcession.to_crs("EPSG:32648")

lc_dum = landconcession["contract_0"]=="Not found"
landconcession.loc[lc_dum, "contract_0"] = landconcession.loc[lc_dum, "sub_decree"]

#landconcession = landconcession.to_crs("EPSG:4326")

lc_grid = gpd.sjoin(empty_grid, landconcession[["contract_0", "geometry"]], op="intersects", how="left")

min_years_lc = lc_grid.groupby("id")["contract_0"].min()

grid = grid.merge(min_years_lc, left_on="id", right_index=True)


###


pa_file = os.path.join(base_path, "protectedareas.geojson")

protectedarea= gpd.read_file(pa_file)

protectedarea.loc[protectedarea["issuedate"]=="01 Nov 1993", "issuedate"] = "01/11/1993"

protectedarea["issuedate"] = pd.to_datetime(protectedarea["issuedate"], format="%d/%m/%Y")

#protectedarea = protectedarea.to_crs("EPSG:4326")

protectedarea = protectedarea.to_crs("EPSG:32648")

pa_grid = gpd.sjoin(empty_grid, protectedarea[["issuedate", "geometry"]], op="intersects", how="left")

min_years_pa = pa_grid.groupby("id")["issuedate"].min()
min_years_pa.index.name = None

grid = grid.merge(min_years_pa, left_on="id", right_index=True)

###

adm_file = os.path.join(base_path, "gadm36_KHM_3.geojson")

adm = gpd.read_file(adm_file)

adm =adm.to_crs("EPSG:32648")

empty_grid_cent = empty_grid.copy()
empty_grid_cent.geometry=empty_grid_cent.geometry.centroid

adm_grid = gpd.sjoin(empty_grid_cent, adm, op="intersects", how="left").drop_duplicates().drop(["left", "top", "right", "bottom", "index_right", "geometry"],axis=1)

grid = grid.merge(adm_grid, on="id")


###

# tree plantation data maybe not useful. Based on satellite imagery so endogenous

#tp_file = os.path.join(base_path, "treeplantations.geojson")

#plantation= gpd.read_file(tp_file)

##########

match_filename = os.path.join(base_path, "raster_template.tif")
temp_filename = os.path.join(base_path, "temp1.tif")
dst_filename = os.path.join(base_path, "temp2.tif")

bands = {1:"treecover", 2:"nontreeveg", 3:"nonveg"}
stats = {"mean":gdalconst.GRA_Bilinear, "min":gdalconst.GRA_Min, "max":gdalconst.GRA_Max}


match_ds=gdal.Open(match_filename, gdalconst.GA_ReadOnly)
match_proj = match_ds.GetProjection()
match_geotrans = match_ds.GetGeoTransform()
wide = match_ds.RasterXSize
high = match_ds.RasterYSize

for i in range(2000, 2005):
	src_file="MODIS_VCF"+str(i)+"_FINAL.tif"
	src_filename=os.path.join(base_path, "vcf/process/final", src_file)
	dat = rasterio.open(src_filename)
	cloud = (dat.read(4)>3)
	quality = (dat.read(5)>2)
	mask = numpy.logical_or(cloud, quality)
	for num, name in bands.items():
		with rasterio.Env():
			# Write an array as a raster band to a new 8-bit file. For
			# the new file's profile, we start with the profile of the source
			profile = dat.profile
			array = dat.read(num)
			array[mask]=200
			# And then change the band count to 1, set the
			# dtype to uint8, and specify LZW compression.
			profile.update(dtype=rasterio.float32, count=1, compress='lzw')
			with rasterio.open(temp_filename, 'w', **profile) as dst:
				dst.write(array.astype(rasterio.float32), 1)
		src = gdal.Open(temp_filename, gdalconst.GA_ReadOnly)
		src_proj = src.GetProjection()
		src_geotrans = src.GetGeoTransform()
		for stat_name, stat in stats.items():
			#src_file="MODIS_VCF"+str(i)+"_FINAL.tif"
			#src_filename=os.path.join(base_path, "vcf/process/final", src_file)
			#dat = rasterio.open(src_filename)
			#with rasterio.Env():
				# Write an array as a raster band to a new 8-bit file. For
				# the new file's profile, we start with the profile of the source
				#profile = dat.profile
				#array = dat.read(num)
				# And then change the band count to 1, set the
				# dtype to uint8, and specify LZW compression.
				#profile.update(dtype=rasterio.float32, count=1, compress='lzw')
				#with rasterio.open(temp_filename, 'w', **profile) as dst:
					#dst.write(array.astype(rasterio.float32), 1)
			#src = gdal.Open(temp_filename, gdalconst.GA_ReadOnly)
			#src_proj = src.GetProjection()
			#src_geotrans = src.GetGeoTransform()
			dst = gdal.GetDriverByName('GTiff').Create(dst_filename, wide, high, 1, gdalconst.GDT_Float32)
			dst.SetGeoTransform( match_geotrans )
			dst.SetProjection( match_proj)
			#gdal.ReprojectImage(src, dst, src_proj, match_proj, gdalconst.GRA_Bilinear)
			gdal.ReprojectImage(src, dst, src_proj, match_proj, stat)
			del dst # Flush
			ras = rasterio.open(dst_filename)
			#colname = "vcf_"+name+str(i)
			colname = "vcf_"+name+"_"+stat_name+str(i)
			grid[colname] = [x[0] for x in ras.sample(coords)]

###

stats = {"mean":gdalconst.GRA_Average, "min":gdalconst.GRA_Min, "max":gdalconst.GRA_Max}

for i in range(1999, 2021):
	src_file = "landsatndvi_"+str(i)+".tif"
	src_filename=os.path.join(base_path, "landsat", src_file)
	src = rxr.open_rasterio(src_filename)
	src_masked=src.where(~src.isin([-10000, -9999]))
	# Note that I'm going to use `ds` instead of the OP's `da`
	# replace all values equal to -9999 with np.nan
	src_masked.astype("int16").rio.write_nodata(0).rio.to_raster(temp_filename)
	for stat_name, stat in stats.items():
		#src_file = "landsatndvi_"+str(i)+".tif"
		#src_filename=os.path.join(base_path, "landsat", src_file)
		temp = gdal.Open(temp_filename, gdalconst.GA_ReadOnly)
		temp_proj = temp.GetProjection()
		temp_geotrans = temp.GetGeoTransform()
		dst = gdal.GetDriverByName('GTiff').Create(dst_filename, wide, high, 1, gdalconst.GDT_Float32)
		dst.SetGeoTransform( match_geotrans )
		dst.SetProjection( match_proj)
		gdal.ReprojectImage(temp, dst, temp_proj, match_proj, stat)
		del dst # Flush
		ras = rasterio.open(dst_filename)
		colname = "landsat_ndvi_"+stat_name+str(i)
		grid[colname] = [x[0] for x in ras.sample(coords)]




###

#HANSEN - zero is no loss

treecover_path = os.path.join(base_path, "hansen/Hansen_GFC-2019-v1.7_treecover2000_20N_100E.tif")
treecover = xarray.open_rasterio(treecover_path)
treecover_array = treecover.values.squeeze()

mask_path = os.path.join(base_path, "hansen/Hansen_GFC-2019-v1.7_datamask_20N_100E.tif")
mask = xarray.open_rasterio(mask_path)
mask_array = mask.values.squeeze()

gain_path = os.path.join(base_path, "hansen/Hansen_GFC-2019-v1.7_gain_20N_100E.tif")
gain = xarray.open_rasterio(gain_path)
gain_array = gain.values.squeeze()

loss_path = os.path.join(base_path, "hansen/Hansen_GFC-2019-v1.7_lossyear_20N_100E.tif")
loss = xarray.open_rasterio(loss_path)
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
	out_arr.astype("int8").rio.set_crs(4326).rio.write_nodata(5).rio.to_raster(temp_filename)
	src = gdal.Open(temp_filename, gdalconst.GA_ReadOnly)
	src.SetProjection("EPSG:4326")
	src_proj = src.GetProjection()
	src_geotrans = src.GetGeoTransform()
	dst = gdal.GetDriverByName('GTiff').Create(dst_filename, wide, high, 1, gdalconst.GDT_Float32)
	dst.SetGeoTransform( match_geotrans )
	dst.SetProjection( match_proj)
	gdal.ReprojectImage(src, dst, src_proj, match_proj, gdalconst.GRA_Average)
	del dst # Flush
	ras = rasterio.open(dst_filename)
	colname = "hansen_treecover_"+str(year)
	grid[colname] = [x[0] for x in ras.sample(coords)]







#vcf_name = ["pct_treecover_", "pct_nontreeveg_", "pct_bare_"]

#for i in range(2000, 2020):
#	tif_file = "MODIS_VCF"+str(i)+"_FINAL.tif"
#	tif_path = os.path.join(base_path, "vcf/process/final/", tif_file)
#	for num, name in enumerate(vcf_name):
#		band = num+1
#		stats = zonal_stats(empty_grid_path, tif_path, band=band)
#		stats_df = pd.DataFrame(stats)
#		if i==2000:
#			stats_df.drop(["std", "sum"], axis=1, inplace=True)
#		else:
#			stats_df.drop(["std", "sum", "count"], axis=1, inplace=True)
#		stats_df.columns=[name+j+str(i) for j in stats_df.columns[:-1]]+["fid"]
#		grid = grid.merge(stats_df, left_on="id", right_on="fid").drop(["fid"], axis=1)

cent_4326 = grid.to_crs("EPSG:4326").geometry.centroid

coords_4326 = [(x,y) for x, y in zip(cent_4326.x, cent_4326.y)]

for i in range(2000, 2020):
	precip_path = os.path.join(base_path, "cru_precip/cru_precip_{}.tif".format(i))
	precip = rasterio.open(precip_path, "r")
	grid["precip_{}".format(i)] = [x[0] for x in precip.sample(coords_4326)]

for i in range(2000, 2021):
	temper_path = os.path.join(base_path, "modis_lst/modislst_temp_{}.tif".format(i))
	temper = rasterio.open(temper_path, "r")
	grid["temper_{}".format(i)] = [x[0] for x in temper.sample(coords_4326)]



##########



#keep_rows = empty_grid.geometry.intersects(khm_extent.geometry[0])
#empty_grid = empty_grid.loc[keep_rows, :]
#empty_grid.reset_index(inplace=True, drop=True)
#empty_grid.to_file("/Users/christianbaehr/Desktop/cambodia roads/data/empty_grid_test.geojson", driver="GeoJSON")




#trt.to_file("/Users/christianbaehr/Downloads/treatment_roads.geojson", driver="GeoJSON")
#trt_dissolve.to_file("/Users/christianbaehr/Downloads/treatment_roads_dissolve.geojson", driver="GeoJSON")



##########

grid.drop(["left", "top", "right", "bottom"], axis=1, inplace=True)


geo_out=os.path.join(base_path, "cambodia_roads_grid.geojson")
grid.to_file(geo_out, driver="GeoJSON")

csv_out=os.path.join(base_path, "cambodia_roads_grid.csv")
grid.drop(["geometry"],axis=1).to_csv(csv_out, index=False)















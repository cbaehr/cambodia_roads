
base_path = "/Users/christianbaehr/Desktop/cambodia roads/data"

import os
import geopandas as gpd
#from rasterstats import zonal_stats
import pandas as pd

from osgeo import gdal, ogr, osr
import numpy
import sys

#https://gist.github.com/cbaehr/bcdec33c490ac6162f37c53fa92d3d9c - this is my zonal statistics implementation 
sys.path.append("/Users/christianbaehr/Github/zonal_stats")
from zonal_stats import zonal_stats

##########

trt_path = os.path.join(base_path, "geocoded roads/geocoded roads w import edited.geojson")
trt = gpd.read_file(trt_path)


trt["geometry"] = trt["geometry"].buffer(0.1)

##########

khm_extent = gpd.read_file(os.path.join(base_path, "sample_extent.geojson"))

#empty_grid_path = os.path.join(base_path, "empty_grid.geojson")
empty_grid_path = os.path.join(base_path, "empty_grid_test.geojson")

empty_grid = gpd.read_file(empty_grid_path) 

#keep_rows = empty_grid.geometry.intersects(khm_extent.geometry[0])
#empty_grid = empty_grid.loc[keep_rows, :]
#empty_grid.reset_index(inplace=True, drop=True)
#empty_grid.to_file("/Users/christianbaehr/Desktop/cambodia roads/data/empty_grid_test.geojson", driver="GeoJSON")

grid = empty_grid.copy()

##########

vcf_name = ["pct_treecover_", "pct_nontreeveg_", "pct_bare_"]

for i in range(2000, 2003):
	tif_file = "MODIS_VCF"+str(i)+"_FINAL.tif"
	tif_path = os.path.join(base_path, "vcf/process/final/", tif_file)
	for num, name in enumerate(vcf_name):
		band = num+1
		stats = zonal_stats(empty_grid_path, tif_path, band=band)
		stats_df = pd.DataFrame(stats)
		if i==2000:
			stats_df.drop(["std", "sum"], axis=1, inplace=True)
		else:
			stats_df.drop(["std", "sum", "count"], axis=1, inplace=True)
		stats_df.columns=[name+j+str(i) for j in stats_df.columns[:-1]]+["fid"]
		grid = grid.merge(stats_df, left_on="id", right_on="fid").drop(["fid"], axis=1)









grid.to_file("/Users/christianbaehr/Downloads/cambodia_roads_grid.geojson", driver="GeoJSON")

#trt.to_file("/Users/christianbaehr/Downloads/temp.geojson", driver="GeoJSON")















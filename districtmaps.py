

base_path = "/Users/christianbaehr/Desktop/cambodia roads/data"

import os
import geopandas as gpd
import pandas as pd
import numpy as np
import rasterio

from rasterstats import zonal_stats


adm2_path=os.path.join(base_path, "gadm36_KHM_shp/gadm36_KHM_3.shp")
adm2 = gpd.read_file(adm2_path)

tif_path=os.path.join(base_path, "landsat/landsatndvi_2000.tif")

ndvi=rasterio.open(tif_path)
affine=ndvi.transform
array=ndvi.read(1)
array[array==-10000] = -9999

district_ndvi_2000=zonal_stats(adm2, array, affine=affine, stats=["mean"], nodata=-9999)
district_ndvi_2000_df = pd.DataFrame(district_ndvi_2000)
district_ndvi_2000_df["mean"]=district_ndvi_2000_df["mean"]*0.0001
district_out=pd.concat([adm2, district_ndvi_2000_df], axis=1)


tif_path=os.path.join(base_path, "hansen/Hansen_GFC-2019-v1.7_treecover2000_20N_100E.tif")

ndvi=rasterio.open(tif_path)
affine=ndvi.transform
array=ndvi.read(1)

district_ndvi_2000=zonal_stats(adm2, array, affine=affine, stats=["mean"])
district_ndvi_2000_df = pd.DataFrame(district_ndvi_2000)
district_ndvi_2000_df.columns=["hansen"]
district_out=pd.concat([district_out, district_ndvi_2000_df], axis=1)

district_out["hansen"]=district_out["hansen"]*0.01
district_out["hansen2"] = district_out["hansen"].apply(np.ceil)

#for i in district_out["hansen"]:
#	print(i)


district_out_file=os.path.join(base_path, "district_stats.geojson")
district_out.to_file(district_out_file, driver="GeoJSON")






for i in district_ndvi_2000_df["hansen"]:
	print(i)

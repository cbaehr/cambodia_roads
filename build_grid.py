
path = "/Users/christianbaehr/Desktop/cambodia roads/data"

import pandas as pd
import geopandas as gpd

trt = gpd.read_file(path+"/geocoded roads/geocoded roads w import edited.geojson")


trt["geometry"] = trt["geometry"].buffer(0.1)



#trt.to_file("/Users/christianbaehr/Downloads/temp.geojson", driver="GeoJSON")





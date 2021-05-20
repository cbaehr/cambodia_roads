
year = 2000

###

base_path = "/Users/christianbaehr/Desktop/cambodia roads/data"

import geopandas as gpd
import os
import numpy as np
from shapely.prepared import prep
from osgeo import gdal, ogr, osr

roads_path = os.path.join(base_path, "market_access/road_network_traveltime.geojson")
roads = gpd.read_file(roads_path)

###

geocoded_roads_path = os.path.join(base_path, "geocoded roads/geocoded roads w import edited.geojson")
geocoded_roads = gpd.read_file(geocoded_roads_path)
geocoded_roads["year"] = geocoded_roads["year"].astype(int)

geocoded_roads["geometry"] = geocoded_roads.to_crs("EPSG:32648")["geometry"].buffer(10)
geocoded_roads = geocoded_roads.to_crs("EPSG:4326")


geocoded_roads_trimmed = geocoded_roads.loc[(geocoded_roads["year"]>=year), ]

###

geocoded_roads_trimmed["country"] = "cambodia"
geocoded_roads_trimmed_dissolve=geocoded_roads_trimmed.dissolve(by="country")["geometry"][0]

prep_geocoded_roads_trimmed_dissolve = prep(geocoded_roads_trimmed_dissolve)

int_col = [prep_geocoded_roads_trimmed_dissolve.intersects(i) for i in roads.geometry]
x = [not i for i in int_col]

roads_keep = roads.loc[x, ]

out_file = "road_network_" +str(year)+".geojson"
out_path = os.path.join(base_path, out_file)

roads_keep.to_file(out_path, driver="GeoJSON")










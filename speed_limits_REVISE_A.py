
base_path="/Users/christianbaehr/Downloads/cambodia_roads_inputs_REVISE/data"

import os
import geopandas as gpd
from shapely.geometry import Point

###

#dat_path=os.path.join(base_path, "market_access/cambodia_highway_trimmed.geojson")
dat_path=os.path.join(base_path, "market_access/cambodia_highway_trimmed_withnewroads_32648.geojson")

dat = gpd.read_file(dat_path)

dat.loc[dat["TYPE"].isnull(), "TYPE"] = "secondary"

dat["speed_limit"] = 40

dat.loc[dat["TYPE"]=="primary", "speed_limit"] = 100
dat.loc[dat["TYPE"]=="primary_link", "speed_limit"] = 100
dat.loc[dat["TYPE"]=="trunk", "speed_limit"] = 100
dat.loc[dat["TYPE"]=="trunk_link", "speed_limit"] = 100

dat.loc[dat["TYPE"]=="secondary", "speed_limit"] = 90
dat.loc[dat["TYPE"]=="secondary_link", "speed_limit"] = 90

dat.loc[dat["TYPE"]=="tertiary", "speed_limit"] = 40
dat.loc[dat["TYPE"]=="tertiary_link", "speed_limit"] = 40

dat.loc[dat["TYPE"]=="track", "speed_limit"] = 40
dat.loc[dat["TYPE"]=="unclassified", "speed_limit"] = 40

dat=dat.to_crs("EPSG:32648")

dat_path = os.path.join(base_path, "market_access/cambodia_highway_trimmed_withnewroads_32648_REVISE_A.geojson")
dat.to_file(dat_path, driver="GeoJSON")

##################################################

#dat_path=os.path.join(base_path, "market_access/road_network_2008roadsonly_32648.geojson")
dat_path=os.path.join(base_path, "market_access/cambodia_highway_trimmed_2008roadsonly.geojson")

dat = gpd.read_file(dat_path)

dat["TYPE"] = dat["road_type"]

#dat.loc[dat["TYPE"].isnull(), "TYPE"] = "secondary"

dat["speed_limit"] = 40

dat.loc[dat["TYPE"]=="primary", "speed_limit"] = 100
dat.loc[dat["TYPE"]=="primary_link", "speed_limit"] = 100
dat.loc[dat["TYPE"]=="trunk", "speed_limit"] = 100
dat.loc[dat["TYPE"]=="trunk_link", "speed_limit"] = 100

dat.loc[dat["TYPE"]=="secondary", "speed_limit"] = 90
dat.loc[dat["TYPE"]=="secondary_link", "speed_limit"] = 90

dat.loc[dat["TYPE"]=="tertiary", "speed_limit"] = 40
dat.loc[dat["TYPE"]=="tertiary_link", "speed_limit"] = 40

dat.loc[dat["TYPE"]=="track", "speed_limit"] = 40
dat.loc[dat["TYPE"]=="unclassified", "speed_limit"] = 40

dat = dat.to_crs("EPSG:32648")

dat_path=os.path.join(base_path, "market_access/cambodia_highway_trimmed_2008roadsonly_REVISE_A.geojson")

dat.to_file(dat_path, driver="GeoJSON")

##################################################








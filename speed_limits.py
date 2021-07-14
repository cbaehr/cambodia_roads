
base_path="/Users/christianbaehr/Box Sync/cambodia roads/data"

import os
import geopandas as gpd
from shapely.geometry import Point

###

#dat_path=os.path.join(base_path, "market_access/cambodia_highway_trimmed.geojson")
dat_path=os.path.join(base_path, "market_access/cambodia_highway_trimmed_withnewroads_32648.geojson")

dat = gpd.read_file(dat_path)

dat.loc[dat["TYPE"].isnull(), "TYPE"] = "secondary"

dat["speed_limit"] = 50

dat.loc[dat["TYPE"]=="primary", "speed_limit"] = 100
dat.loc[dat["TYPE"]=="primary_link", "speed_limit"] = 60
dat.loc[dat["TYPE"]=="trunk", "speed_limit"] = 100
dat.loc[dat["TYPE"]=="trunk_link", "speed_limit"] = 60

dat.loc[dat["TYPE"]=="secondary", "speed_limit"] = 80
dat.loc[dat["TYPE"]=="secondary_link", "speed_limit"] = 60

dat.loc[dat["TYPE"]=="tertiary", "speed_limit"] = 80
dat.loc[dat["TYPE"]=="tertiary_link", "speed_limit"] = 60

dat.loc[dat["TYPE"]=="track", "speed_limit"] = 60
dat.loc[dat["TYPE"]=="unclassified", "speed_limit"] = 50

dat=dat.to_crs("EPSG:32648")

dat.to_file(dat_path, driver="GeoJSON")

##################################################

#dat_path=os.path.join(base_path, "market_access/road_network_2008roadsonly_32648.geojson")
dat_path=os.path.join(base_path, "market_access/cambodia_highway_trimmed_2008roadsonly.geojson")

dat = gpd.read_file(dat_path)

dat["TYPE"] = dat["road_type"]

#dat.loc[dat["TYPE"].isnull(), "TYPE"] = "secondary"

dat["speed_limit"] = 50

dat.loc[dat["TYPE"]=="primary", "speed_limit"] = 100
dat.loc[dat["TYPE"]=="primary_link", "speed_limit"] = 60

dat.loc[dat["TYPE"]=="trunk", "speed_limit"] = 100
dat.loc[dat["TYPE"]=="trunk_link", "speed_limit"] = 60

dat.loc[dat["TYPE"]=="secondary", "speed_limit"] = 80
dat.loc[dat["TYPE"]=="secondary_link", "speed_limit"] = 60

dat.loc[dat["TYPE"]=="tertiary", "speed_limit"] = 80
dat.loc[dat["TYPE"]=="tertiary_link", "speed_limit"] = 60

dat.loc[dat["TYPE"]=="track", "speed_limit"] = 60
dat.loc[dat["TYPE"]=="unclassified", "speed_limit"] = 50

dat = dat.to_crs("EPSG:32648")

dat.to_file(dat_path, driver="GeoJSON")

##################################################








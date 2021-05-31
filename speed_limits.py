
base_path="/Users/christianbaehr/Desktop/cambodia roads/data"

import os
import geopandas as gpd
from shapely.geometry import Point

dat_path=os.path.join(base_path, "market_access/cambodia_highway_trimmed.geojson")

dat = gpd.read_file(dat_path)

#dat["geometry"].length

dat["speed_limit"] = 50

dat.loc[dat["TYPE"]=="primary", "speed_limit"] = 100
dat.loc[dat["TYPE"]=="primary_link", "speed_limit"] = 60
dat.loc[dat["TYPE"]=="secondary", "speed_limit"] = 80
dat.loc[dat["TYPE"]=="tertiary", "speed_limit"] = 80
dat.loc[dat["TYPE"]=="track", "speed_limit"] = 60
dat.loc[dat["TYPE"]=="unclassified", "speed_limit"] = 50

dat.to_file(dat_path, driver="GeoJSON")

#dat.loc[0, "geometry"][0]


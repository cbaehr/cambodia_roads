
base="/Users/christianbaehr/Desktop/cambodia roads/data"

import os
import numpy as np
import geopandas as gpd
from shapely.prepared import prep

gcdroads_path=os.path.join(base, "geocoded roads/geocoded roads w import edited 32648.geojson")
gcdroads = gpd.read_file(gcdroads_path)

gcdroads["country"]="Cambodia"
gcdroads["year"] = gcdroads["year"].astype(int)


#network_path=os.path.join(base, "market_access/cambodia_highway_trimmed_32648.geojson")
network_path=os.path.join(base, "market_access/cambodia_highway_trimmed_withnewroads_32648.geojson")
network=gpd.read_file(network_path)
network.loc[np.isnan(network.speed_limit), "speed_limit"] = 0

for i in [2005, 2010, 2015, 2020]:
	print(i)
	gcdroads_dum=gcdroads["year"] > i
	gcdroads_i = gcdroads.loc[gcdroads_dum, ]
	network_i= network.copy()
	if len(gcdroads_i.index)!=0:
		gcdroads_buf = gpd.GeoDataFrame(gcdroads_i, geometry=gcdroads_i.buffer(50)).dissolve(by="country")["geometry"][0]
		prep_gcdroads_buf=prep(gcdroads_buf)
		roads_dum=[prep_gcdroads_buf.intersects(i) for i in network.geometry]
		network_i.loc[roads_dum, "speed_limit"] = 50
	gcdroads_i_finished=gcdroads.loc[~gcdroads_dum, "geometry"]
	for j in gcdroads_i_finished:
		network_add=network.iloc[1]
		network_add["geometry"]=j
		network_add["speed_limit"]=100
		network_i.loc[len(network_i.index)]=network_add
	network_out=os.path.join(base, "market_access/road_network_{}_32648.geojson".format(str(i)))
	network_i.set_crs("EPSG:32648").to_file(network_out, driver="GeoJSON")

###

chunks=10

grid_path = os.path.join(base, "empty_grid_trimmed_points_32648.geojson")
grid=gpd.read_file(grid_path)


grid_split=np.array_split(grid, chunks)

for i in range(chunks):
	out_path= os.path.join(base, "market_access/empty_grid_trimmed_points_32648_{}.geojson".format(i))
	grid_split[i].to_file(out_path, driver="GeoJSON")































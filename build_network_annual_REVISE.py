
#base="/Users/christianbaehr/Desktop/cambodia roads/data"
base="/Users/christianbaehr/Downloads/cambodia_roads_inputs_REVISE/data"

import os
import numpy as np
import geopandas as gpd
from shapely.prepared import prep

gcdroads_path=os.path.join(base, "geocoded roads/geocoded roads w import edited 32648 REVISE.geojson")
gcdroads = gpd.read_file(gcdroads_path)

gcdroads["country"]="Cambodia"
gcdroads["year"] = gcdroads["year"].astype(int)

##################################################

#network_path=os.path.join(base, "market_access/cambodia_highway_trimmed_32648.geojson")
network_path=os.path.join(base, "market_access/cambodia_highway_trimmed_withnewroads_32648_REVISE_A.geojson")
#network_path=os.path.join(base, "market_access/cambodia_highway_trimmed_withnewroads_32648_exploded.geojson")
#network_path=os.path.join(base, "market_access/road_network_2008roadsonly_32648.geojson")
network=gpd.read_file(network_path)
network.loc[np.isnan(network.speed_limit), "speed_limit"] = 20

for i in range(2008, 2021):
	print(i)
	gcdroads_dum=gcdroads["year"] > i
	gcdroads_i = gcdroads.loc[gcdroads_dum, ]
	network_i= network.copy()
	if len(gcdroads_i.index)!=0:
		gcdroads_buf = gpd.GeoDataFrame(gcdroads_i, geometry=gcdroads_i.buffer(50)).dissolve(by="country")["geometry"][0]
		prep_gcdroads_buf=prep(gcdroads_buf)
		roads_dum=[prep_gcdroads_buf.intersects(i) for i in network.geometry]
		network_i.loc[roads_dum, "speed_limit"] = 50
	###
	network_i.loc[network_i["TYPE"].isnull(), "speed_limit"]=20
	#network_i.loc[network_i["ntlclass"].isnull(), "speed_limit"]=20
	gcdroads_i_finished=gcdroads.loc[~gcdroads_dum,]
	gcdroads_finished_buf=gpd.GeoDataFrame(gcdroads_i_finished, geometry=gcdroads_i_finished.buffer(50)).dissolve(by="country")["geometry"][0]
	prep_gcdroads_finished_buf=prep(gcdroads_finished_buf)
	finished_roads_dum=[prep_gcdroads_finished_buf.intersects(i) for i in network.geometry]
	network_i.loc[finished_roads_dum, "speed_limit"]=100
	#for j in gcdroads_i_finished:
	#	network_add=network.iloc[1]
	#	network_add["geometry"]=j
	#	network_add["speed_limit"]=100
	#	network_i.loc[len(network_i.index)]=network_add
	network_i["merging_id"] = network_i["unique_id"].astype(str) + network_i["speed_limit"].astype(str)
	network_i=network_i.dissolve("merging_id")
	network_out=os.path.join(base, "market_access/road_network_{}_32648_REVISE_A.geojson".format(str(i)))
	network_i.set_crs("EPSG:32648").to_file(network_out, driver="GeoJSON")

##################################################

#network_path=os.path.join(base, "market_access/cambodia_highway_trimmed_32648.geojson")
#network_path=os.path.join(base, "market_access/cambodia_highway_trimmed_withnewroads_32648.geojson")
network_path=os.path.join(base, "market_access/cambodia_highway_trimmed_2008roadsonly_REVISE_A.geojson")
#network_path=os.path.join(base, "market_access/cambodia_highway_trimmed_2008roadsonly_exploded.geojson")
network=gpd.read_file(network_path)
network.loc[np.isnan(network.speed_limit), "speed_limit"] = 20


for i in range(2008, 2021):
	print(i)
	gcdroads_dum=gcdroads["year"] > i
	gcdroads_i = gcdroads.loc[gcdroads_dum, ]
	network_i= network.copy()
	if len(gcdroads_i.index)!=0:
		gcdroads_buf = gpd.GeoDataFrame(gcdroads_i, geometry=gcdroads_i.buffer(50)).dissolve(by="country")["geometry"][0]
		prep_gcdroads_buf=prep(gcdroads_buf)
		roads_dum=[prep_gcdroads_buf.intersects(i) for i in network.geometry]
		network_i.loc[roads_dum, "speed_limit"] = 50
	###
	network_i.loc[network_i["TYPE"].isnull(), "speed_limit"]=20
	#network_i.loc[network_i["ntlclass"].isnull(), "speed_limit"]=20
	gcdroads_i_finished=gcdroads.loc[~gcdroads_dum,]
	gcdroads_finished_buf=gpd.GeoDataFrame(gcdroads_i_finished, geometry=gcdroads_i_finished.buffer(50)).dissolve(by="country")["geometry"][0]
	prep_gcdroads_finished_buf=prep(gcdroads_finished_buf)
	finished_roads_dum=[prep_gcdroads_finished_buf.intersects(i) for i in network.geometry]
	network_i.loc[finished_roads_dum, "speed_limit"]=100
	#for j in gcdroads_i_finished:
	#	network_add=network.iloc[1]
	#	network_add["geometry"]=j
	#	network_add["speed_limit"]=100
	#	network_i.loc[len(network_i.index)]=network_add
	network_i["merging_id"] = network_i["unique_id"].astype(str) + network_i["speed_limit"].astype(str)
	network_i=network_i.dissolve("merging_id")
	network_out=os.path.join(base, "market_access/road_network_{}_32648_2008roadsonly_REVISE_A.geojson".format(str(i)))
	network_i.set_crs("EPSG:32648").to_file(network_out, driver="GeoJSON")
























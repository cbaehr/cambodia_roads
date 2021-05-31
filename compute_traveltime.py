
chunks=10

base = "/Users/christianbaehr/Desktop/cambodia roads/data"

import os

#for i in [2005, 2010, 2015, 2020]:
for i in [2015]:
	print(i)
	###
	#inp=os.path.join(base, "market_access/road_network_{}_32648.geojson".format(i))
	#inter=os.path.join(base, "market_access/market_lines_2000_32648.geojson")
	#out=os.path.join(base, "market_access/market_points_{}_32648.geojson".format(i))
	#processing.run("native:lineintersections", {'INPUT':inp,'INTERSECT':inter,'INPUT_FIELDS':[],'INTERSECT_FIELDS':[],'OUTPUT':out})
	###
	#network=os.path.join(base, "market_access/cambodia_highway_trimmed_32648.geojson")
	for j in range(chunks):
	#for j in range(7, chunks):
	#for j in range(5, 8):
	#for j in [9]:
		inp=os.path.join(base, "market_access/road_network_{}_32648.geojson".format(i))
		inter=os.path.join(base, "market_access/market_lines_2000_32648.geojson")
		out=os.path.join(base, "market_access/market_points_{}_32648.geojson".format(i))
		processing.run("native:lineintersections", {'INPUT':inp,'INTERSECT':inter,'INPUT_FIELDS':[],'INTERSECT_FIELDS':[],'OUTPUT':out})
		###
		#network=os.path.join(base, "market_access/cambodia_highway_trimmed_32648.geojson")
		network=os.path.join(base, "market_access/road_network_{}_32648.geojson".format(i))
		###
		from_pts=os.path.join(base, "market_access/empty_grid_trimmed_points_32648_{}.geojson".format(j))
		#from_pts=os.path.join(base, "empty_grid_trimmed_points_32648_sample.geojson")
		to_pts=out
		out_tt = os.path.join(base, "market_access/market_access_{}.geojson".format(i))
		processing.run("qneat3:OdMatrixFromLayersAsLines", {'INPUT':network,'FROM_POINT_LAYER':from_pts,'FROM_ID_FIELD':'id','TO_POINT_LAYER':to_pts,'TO_ID_FIELD':'NAME','STRATEGY':1,'ENTRY_COST_CALCULATION_METHOD':1,'DIRECTION_FIELD':None,'VALUE_FORWARD':'','VALUE_BACKWARD':'','VALUE_BOTH':'','DEFAULT_DIRECTION':2,'SPEED_FIELD':'speed_limit','DEFAULT_SPEED':20,'TOLERANCE':0.01,'OUTPUT':out_tt})
		###
		inp=out_tt
		out=os.path.join(base, "market_access/market_access_{}_trimmed_{}.geojson".format(i, j))
		processing.run("qgis:executesql", {'INPUT_DATASOURCES':out_tt,'INPUT_QUERY':'select origin_id, destination_id, min(total_cost) as shortest_distance, geometry from input1 group by origin_id','INPUT_UID_FIELD':'','INPUT_GEOMETRY_FIELD':'geometry','INPUT_GEOMETRY_TYPE':3,'INPUT_GEOMETRY_CRS':'EPSG:32648','OUTPUT':out})

















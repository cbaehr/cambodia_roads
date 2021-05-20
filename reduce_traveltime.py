
year=2000

import geopandas as gpd
import pandas as pd
import os
from shapely.geometry import LineString
from shapely import wkt

base_path = "/Users/christianbaehr/Desktop/cambodia roads/data"


dat=pd.read_csv("/Users/christianbaehr/Desktop/test.csv")
#dat=dat.loc[dat.origin_id==24821, ]

dat = dat.loc[~dat["origin_id"].isnull()]
dat = dat.loc[~dat["total_cost"].isnull()]

a=dat.groupby('origin_id').network_cost.std()
b=a[a==0].index.values

dat=dat.loc[~dat["origin_id"].isin(b), ]

dat2=dat.loc[dat.groupby('origin_id').total_cost.idxmin(), ].reset_index(drop=True)

dat2.to_csv("/Users/christianbaehr/Desktop/test2.csv", index=False)

###

dat2

roads_path=os.path.join(base_path, "market_points_2000.geojson")
roads = gpd.read_file(roads_path)

empty_grid_path=os.path.join(base_path, "empty_grid_trimmed_points.geojson")
empty_grid=gpd.read_file(empty_grid_path)

dat3=dat2.merge(empty_grid[["id", "geometry"]], left_on="origin_id", right_on="id")

roads2=roads[["ID", "geometry"]]
roads2["ID"] = roads2["ID"].astype(int)

roads2 = roads2.drop_duplicates(subset='ID', keep="first")

dat3=dat3.merge(roads2, left_on="destination_id", right_on="ID")



def g(x):
	return LineString([x[0], x[1]]).wkt

dat3[["geometry"]]=dat3[['geometry_x', 'geometry_y']].apply(g, axis=1)

dat3.drop(['geometry_x', 'geometry_y'], axis=1, inplace=True)

dat3['geometry'] = dat3['geometry'].apply(wkt.loads)

dat4 =gpd.GeoDataFrame(dat3, geometry='geometry')

dat4.to_file("/Users/christianbaehr/Desktop/test_traveltime.geojson", driver="GeoJSON")








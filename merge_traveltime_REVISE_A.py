
chunks=5

#base="/Users/christianbaehr/Desktop/cambodia roads/data"
base="/Users/christianbaehr/Downloads/cambodia_roads_inputs_REVISE/data"

import os
import geopandas as gpd
import pandas as pd

for i in range(2008, 2021):
	for j in range(1, chunks):
		#dat_pat=os.path.join(base, "market_access/{}/market_access_{}_trimmed_{}.geojson".format(i,i,j))
		dat_pat=os.path.join(base, "market_access/market_access_{}_trimmed_{}_REVISE_A.geojson".format(i,j))
		dat=gpd.read_file(dat_pat)
		if i==2008 and j==1:
			dat_out=dat
		else:
			#dat_out=dat_out.append(dat)
			dat_out = pd.concat([dat_out, dat])


dat_out.loc[dat_out.groupby("origin_id").shortest_distance.idxmin()]

a=dat_out.shortest_distance.duplicated()

dat_out_path=os.path.join(base, "market_access/market_access_{}_merged_REVISE_A.geojson".format(i))
dat_out.to_file(dat_out_path, driver="GeoJSON")



chunks=10

base="/Users/christianbaehr/Desktop/cambodia roads/data"

import os
import geopandas as gpd

i=2020
for j in range(chunks):
	dat_pat=os.path.join(base, "market_access/{}/market_access_{}_trimmed_{}.geojson".format(i,i,j))
	#dat_pat=os.path.join(base, "market_access/market_access_{}_trimmed_{}.geojson".format(i,j))
	dat=gpd.read_file(dat_pat)
	if j==0:
		dat_out=dat
	else:
		dat_out=dat_out.append(dat)


dat_out.loc[dat_out.groupby("origin_id").shortest_distance.idxmin()]

a=dat_out.shortest_distance.duplicated()

dat_out_path=os.path.join(base, "market_access/market_access_{}_merged.geojson".format(i))
dat_out.to_file(dat_out_path, driver="GeoJSON")


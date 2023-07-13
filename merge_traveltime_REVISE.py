
chunks=10

#base="/Users/christianbaehr/Desktop/cambodia roads/data"
base="/Users/christianbaehr/Downloads/cambodia_roads_inputs_REVISE/data"

import os
import geopandas as gpd
import pandas as pd

##########

#for i in range(2008, 2021):
for i in [2010, 2015, 2020]:
	for j in range(0, chunks):
		#dat_pat=os.path.join(base, "market_access/{}/market_access_{}_trimmed_{}.geojson".format(i,i,j))
		dat_pat=os.path.join(base, "market_access/market_access_{}_trimmed_{}_REVISE_A.geojson".format(i,j))
		dat=gpd.read_file(dat_pat)
		#dat = dat.dropna(subset=["destination_id"])
		dat["year"] = i
		#if i==2008 and j==1:
		if i==2010 and j==0:
			dat_out=dat
		else:
			#dat_out=dat_out.append(dat)
			dat_out = pd.concat([dat_out, dat])


#dat_out.loc[dat_out.groupby("origin_id").shortest_distance.idxmin()]

#a=dat_out.shortest_distance.duplicated()

dat_out_path=os.path.join(base, "market_access/market_access_merged_REVISE_A.geojson")
dat_out.to_file(dat_out_path, driver="GeoJSON")

dat_out = dat_out.drop(["geometry"], axis=1)
dat_out = dat_out.rename({"shortest_distance":"ma_minutes"}, axis=1)
dat_out["ma_minutes"] = dat_out["ma_minutes"] / 60
dat_out = pd.DataFrame(dat_out)

dat_out_path=os.path.join(base, "market_access/market_access_merged_REVISE_A.csv")
dat_out.to_csv(dat_out_path, index=False)

##########

#for i in range(2008, 2021):
for i in [2010, 2015, 2020]:
	for j in range(0, chunks):
		#dat_pat=os.path.join(base, "market_access/{}/market_access_{}_trimmed_{}.geojson".format(i,i,j))
		dat_pat=os.path.join(base, "market_access/market_access_{}_trimmed_{}_REVISE_B.geojson".format(i,j))
		dat=gpd.read_file(dat_pat)
		#dat = dat.dropna(subset=["destination_id"])
		dat["year"] = i
		#if i==2008 and j==1:
		if i==2010 and j==0:
			dat_out=dat
		else:
			#dat_out=dat_out.append(dat)
			dat_out = pd.concat([dat_out, dat])

#dat_out.loc[dat_out.groupby("origin_id").shortest_distance.idxmin()]

#a=dat_out.shortest_distance.duplicated()

dat_out_path=os.path.join(base, "market_access/market_access_merged_REVISE_B.geojson")
dat_out.to_file(dat_out_path, driver="GeoJSON")

dat_out = dat_out.drop(["geometry"], axis=1)
dat_out = dat_out.rename({"shortest_distance":"ma_minutes"}, axis=1)
dat_out["ma_minutes"] = dat_out["ma_minutes"] / 60
dat_out = pd.DataFrame(dat_out)

dat_out_path=os.path.join(base, "market_access/market_access_merged_REVISE_B.csv".format(i))
dat_out.to_csv(dat_out_path, index=False)

##########

#for i in range(2008, 2021):
for i in [2010, 2015, 2020]:
	for j in range(0, chunks):
		#dat_pat=os.path.join(base, "market_access/{}/market_access_{}_trimmed_{}.geojson".format(i,i,j))
		dat_pat=os.path.join(base, "market_access/market_access_{}_trimmed_{}_REVISE_C.geojson".format(i,j))
		dat=gpd.read_file(dat_pat)
		#dat = dat.dropna(subset=["destination_id"])
		dat["year"] = i
		#if i==2008 and j==1:
		if i==2010 and j==0:
			dat_out=dat
		else:
			#dat_out=dat_out.append(dat)
			dat_out = pd.concat([dat_out, dat])

#dat_out.loc[dat_out.groupby("origin_id").shortest_distance.idxmin()]

#a=dat_out.shortest_distance.duplicated()

dat_out_path=os.path.join(base, "market_access/market_access_merged_REVISE_C.geojson")
dat_out.to_file(dat_out_path, driver="GeoJSON")

dat_out = dat_out.drop(["geometry"], axis=1)
dat_out = dat_out.rename({"shortest_distance":"ma_minutes"}, axis=1)
dat_out["ma_minutes"] = dat_out["ma_minutes"] / 60
dat_out = pd.DataFrame(dat_out)

dat_out_path=os.path.join(base, "market_access/market_access_merged_REVISE_C.csv".format(i))
dat_out.to_csv(dat_out_path, index=False)


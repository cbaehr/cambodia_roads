
base_path = "/Users/christianbaehr/Desktop/cambodia roads/data"

import geopandas as gpd
import os
from rasterstats import zonal_stats
import pandas as pd

#road_path = os.path.join(base_path, "sas/trans-road-l_cambodia.shp")
road_path = os.path.join(base_path, "market_access/cambodia_roads_sas.geojson")
roads = gpd.read_file(road_path)


roads_geo=roads.to_crs("EPSG:32648")

roads_geo["geometry"] = roads_geo["geometry"].buffer(10)

roads_geo=roads_geo.to_crs("EPSG:4326")

###

friction_path = os.path.join(base_path, "market_access/2015_friction_surface_v1_cambodia.tif")

### WORKS
stats = zonal_stats(roads_geo, friction_path, all_touched=True)
stats_df=pd.DataFrame(stats)
stats_df.columns = ["friction_"+str(i) for i in stats_df.columns]

out = pd.concat([roads[["ID", "EXS_DESCRI", "RTT_DESCRI", "geometry"]], stats_df], axis=1)

out["friction_mean_inverse"] = out["friction_mean"] * -1

out_path = os.path.join(base_path, "market_access/road_network_traveltime.geojson")
out.to_file(out_path, driver="GeoJSON")

##########

#empty_grid = gpd.read_file("/Users/christianbaehr/Desktop/cambodia roads/data/empty_grid.geojson")
#empty_grid = gpd.clip(empty_grid, gpd.read_file(os.path.join(base_path, "sample_extent.geojson")))
#empty_grid.reset_index(drop=True, inplace=True)
#empty_grid.to_file("/Users/christianbaehr/Desktop/cambodia roads/data/empty_grid_sample.geojson", driver="GeoJSON")


















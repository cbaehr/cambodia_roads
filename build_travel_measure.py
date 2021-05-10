
base_path = "/Users/christianbaehr/Desktop/cambodia roads/data"

import geopandas as gpd
import os
from rasterstats import zonal_stats
import pandas as pd

road_path = os.path.join(base_path, "sas/trans-road-l_cambodia.shp")
roads = gpd.read_file(road_path)

#roads=roads.to_crs("EPSG:32648")

roads["geometry"] = roads["geometry"].buffer(0.01)

friction_path = os.path.join(base_path, "2015_friction_surface_v1_cambodia.tif")

### WORKS
stats = zonal_stats(roads, friction_path)
stats_df=pd.DataFrame(stats)
stats_df.columns = ["friction_"+str(i) for i in stats_df.columns]

out = pd.concat([roads, stats_df], axis=1)


out.to_file("/Users/christianbaehr/Desktop/temp.geojson", driver="GeoJSON")


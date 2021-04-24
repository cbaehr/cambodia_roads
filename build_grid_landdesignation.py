
base_path = "/Users/christianbaehr/Desktop/cambodia roads/data"
#base_path="/sciclone/data10/aiddata20/projects/cambodia_roads"

import os
import geopandas as gpd
import pandas as pd

from osgeo import gdal, gdalconst, ogr, osr
import numpy
import sys
import rasterio
import rioxarray as rxr
import xarray
### MUST BE USING RASTERSTATS VERSION 0.13.1 !!!!!
from rasterstats import zonal_stats

##########

pa_file = os.path.join(base_path, "protectedareas.geojson")
protectedarea= gpd.read_file(pa_file)

lc_file = os.path.join(base_path, "landconcessions.geojson")
landconcession= gpd.read_file(lc_file)

plantation_path=os.path.join(base_path, "treeplantations.geojson")
plantation=gpd.read_file(plantation_path)































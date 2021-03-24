

path = "/Users/christianbaehr/Desktop/cambodia roads/data"
#in_path="/sciclone/home20/cbaehr/demining/inputData"
#out_path = "/sciclone/scr20/cbaehr"

#import os

from distancerasters import build_distance_array, rasterize, export_raster

from affine import Affine
# import numpy as np
import fiona
from shapely.geometry import shape

# -----------------------------------------------------------------------------

### Distance to border

pixel_size = 0.00026949999

# canal_path = os.path.expanduser("~/git/afghanistan_gie/canal_data/canal_lines.geojson")
#border = in_path+"/afg_border.geojson"

#with fiona.open(canal_path) as canal_src:
#    bounds = canal_src.bounds

#grid_extent = fiona.open(path+"/afg_border.geojson")
#grid_feature = grid_extent[0]
#grid_shape = shape(grid_feature['geometry'])
#bounds = grid_shape.bounds
#bounds = (60, 29, 75, 39)

#rv_array, affine = rasterize(border, pixel_size=pixel_size, bounds=bounds)

#binary_raster_path = out_path+"/binary_starts.tif"

#export_raster(rv_array, affine, binary_raster_path)

#distance_raster_path = out_path+"/distance_starts_border.tif"

#def raster_conditional(rarray):
#    return (rarray == 1)

#dist = build_distance_array(rv_array, affine=affine,
#                            output=distance_raster_path,
#                            conditional=raster_conditional)


# make_tarfile(dst=distance_raster_path + ".tar.gz" , src=distance_raster_path)

# -----------------------------------------------------------------------------

### Distance to road

#pixel_size = 0.00026949999

# canal_path = os.path.expanduser("~/git/afghanistan_gie/canal_data/canal_lines.geojson")
#border = path+"/afg_roads_ocha.geojson"
border = path+"/sample_osm_roads_cambodia.geojson"

#with fiona.open(canal_path) as canal_src:
#    bounds = canal_src.bounds

#grid_extent = fiona.open(path+"/afg_border.geojson")
#grid_feature = grid_extent[0]
#grid_shape = shape(grid_feature['geometry'])
#bounds = grid_shape.bounds
bounds = (102.5, 12.5, 103, 13)

rv_array, affine = rasterize(border, pixel_size=pixel_size, bounds=bounds)

binary_raster_path = path+"/binary_starts.tif"

export_raster(rv_array, affine, binary_raster_path)

distance_raster_path = path+"/distance_starts_roads.tif"

def raster_conditional(rarray):
    return (rarray == 1)

dist = build_distance_array(rv_array, affine=affine,
                            output=distance_raster_path,
                            conditional=raster_conditional)




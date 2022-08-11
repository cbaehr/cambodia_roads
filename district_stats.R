
setwd("/Users/christianbaehr/Downloads/christian_cambodia/")

library(sf)

# read in district shapefile
district <- st_read("gadm36_KHM_2/gadm36_KHM_2.shp")
district <- st_transform(district, crs=32648)
# compute total district area
district$total_area <- as.numeric(st_area(district$geometry)) / 1000

# read LC data
concessions <- st_read("district_concessions_overlap.geojson")

# LC data contains the corresponding district name. Matching the district name from
# district object with LC data
district$concession_area <- concessions$area[match(district$GID_2, concessions$GID_2)]

district$concession_area <- as.numeric(district$concession_area) / 1000

# NA areas do not have any LCs
district$concession_area[is.na(district$concession_area)] <- 0

# calculate percent of district that is LC
district$pct_concession <- as.numeric(district$concession_area / district$total_area)

###

# read plantation data
plantations <- st_read("district_plantations_overlap.geojson")

# plantation data contains the corresponding district name. Matching the district name from
# district object with plantation data
district$plantation_area <- plantations$area [match(district$GID_2, plantations$GID_2)]

district$plantation_area <- as.numeric(district$plantation_area) / 1000

# NA areas do not have any plantations
district$plantation_area[is.na(district$plantation_area)] <- 0

# calculate percent of district that is plantation
district$pct_plantation <- as.numeric(district$plantation_area / district$total_area)

###

# read roads data
roads <- st_read("chinese_roads_dissolve.geojson")
roads <- st_transform(roads, crs=32648)

# loop thru each district polygon
for(i in 1:nrow(district)) {
  # generate NA road length variable
  if(i==1) {district$road_length=NA}
  # retrieve the geometry of district i
  poly <- district$geometry[i]
  
  # retain only the Chinese roads which are within district i
  int <- st_intersection(roads, poly)
  
  if(nrow(int) > 0) {
    # store the length of roads in district i
    district$road_length[i] <- st_length(int)
  } else {
    # if no roads in district i, then 0
    district$road_length[i] <- 0
  }
  
}

# convert from m^2to km^2
district$road_length <- district$road_length / 1000

district <- data.frame(district)
district <- district[ , names(district)!="geometry"]

# write to csv
write.csv(district, "district_statistics.csv", row.names=F)





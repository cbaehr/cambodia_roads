
library(gmapsdistance)
library(stringr)
library(dplyr)
library(sf)


points <- st_read("/Users/christianbaehr/Desktop/cambodia roads/data/sample_census_villages.geojson", stringsAsFactors=F)


coords <- as(points$geometry, "Spatial")@coords
coords_mat <- matrix(unlist(coords), ncol = 2, byrow = TRUE)

#latitude+longitude which looks like this: 40.589779+-73.79928
points$end <- paste0(coords_mat[,2], "+", coords_mat[,1])

#picked a random point
points$start <- c("12.9752+103.3691")

###

origin <- points$start

destination <- points$end

tt_results <- as.data.frame(gmapsdistance(origin=origin,
                                          destination=destination,
                                          mode="driving",
                                          combinations="pairwise",
                                          traffic_model="None",
                                          dep_date="2022-04-01",
                                          dep_time="9:00:00",
                                          key="AIzaSyC6QA8V0b4Xw9sZBV-9LZPc2kmMyujktoU"),
                            stringsAsFactors=F)
#maps_api_key <- "AIzaSyC6QA8V0b4Xw9sZBV-9LZPc2kmMyujktoU"

tt_results_temp <- data.frame(tt_results, stringsAsFactors = F)

tt_results_temp[] <- lapply(tt_results_temp, as.character)

#class(tt_results_temp$Time.de)

tt_results_temp$Time.de

tt_results_merge <- merge(points, tt_results_temp, by.x="end", by.y="Time.de")
tt_results_merge$Time.Time <- as.numeric(tt_results_merge$Time.Time)
tt_results_merge$Distance.Distance <- as.numeric(tt_results_merge$Distance.Distance)


write_sf(tt_results_merge, "/Users/christianbaehr/Downloads/tt.geojson", driver="GeoJSON", delete_dsn=T)














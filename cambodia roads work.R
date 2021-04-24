
library(sf)

setwd("/Users/christianbaehr/Desktop/cambodia roads/data/geocoded roads")

#dat <- read.csv("/Users/christianbaehr/Desktop/cambodia roads/data/geocoded roads/geocoded roads.csv",
#                stringsAsFactors = F)

#import <- read.csv("/Users/christianbaehr/Desktop/cambodia roads/data/geocoded roads/Cambodia Roads 2 - Import.csv",
#                   stringsAsFactors = F)

#mrg <- merge(import, dat, by = "project_id")

#write.csv(mrg, "geocoded roads w import.csv", row.names = F)

##########

dat <- read.csv("geocoded roads w import edited.csv", stringsAsFactors = F)

for(i in 1:nrow(dat)) {

  if(i==1) { geom <- list() }

  x <- st_read(dat$new.gist[i])
  y <- x$geometry[[1]]

  if("LINESTRING" %in% class(y)) {
    geom[i] <- st_combine(st_multilinestring(x$geometry))
  } else if (length(y)>1) {
    z <- st_combine(y)
    geom[i] <- z
  } else {
    geom[i] <- st_combine(y)
  }

}

geom_sfc <- st_sfc(geom)
dat_new <- st_sf(dat, geometry=geom_sfc)

dat_new$year <- format(as.Date(dat_new$end.date, format = "%m/%d/%y"), "%Y")

names(dat_new)

write_sf(dat_new, "geocoded roads w import edited.geojson", delete_dsn=T)

##########








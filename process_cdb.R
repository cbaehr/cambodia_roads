
cdb_path <- "/Users/christianbaehr/Desktop/cambodia roads/data/CDB"

library(readxl)
library(sf)

##########

# 2008

cdb_2008_1 <- read_xls(paste0(cdb_path, "/CDB 2008.xls"), sheet=2)
sum(duplicated(cdb_2008_1$VillGis))

cdb_2008_1 <- data.frame(cdb_2008_1)
#View(cdb_2008_1[1:1000, ])

cdb_2008_2 <- read_xls(paste0(cdb_path, "/CDB 2008.xls"), sheet=3)
cdb_2008_2 <- data.frame(cdb_2008_2)
#View(cdb_2008_2[1:1000, ])


cdb_2008 <- merge(cdb_2008_1, cdb_2008_2, by="VillGis", all=T)
rm(list = c("cdb_2008_1", "cdb_2008_2"))

questions_dat <- data.frame(read_xls(paste0(cdb_path, "/CDB 2008.xls"), sheet=1))
name_vec <- paste0("code_", questions_dat$Code[match(names(cdb_2008),questions_dat$Short.Question)])
names(cdb_2008) <- ifelse(name_vec=="code_NA", names(cdb_2008), name_vec)

##########

#2009

cdb_2009_1 <- read_xls(paste0(cdb_path, "/CDB 2009.xls"), sheet=2)
cdb_2009_1 <- data.frame(cdb_2009_1)
names(cdb_2009_1) <- cdb_2009_1[4,]
cdb_2009_1 <- cdb_2009_1[-(1:4),]
#View(cdb_2009_1[1:1000, ])

cdb_2009_2 <- read_xls(paste0(cdb_path, "/CDB 2009.xls"), sheet=3)
cdb_2009_2 <- data.frame(cdb_2009_2)
names(cdb_2009_2) <- cdb_2009_2[4,]
cdb_2009_2 <- cdb_2009_2[-(1:4),]
#View(cdb_2009_2[1:1000, ])

cdb_2009 <- merge(cdb_2009_1, cdb_2009_2, by="VillGis", all=T)
rm(list = c("cdb_2009_1", "cdb_2009_2"))

questions_dat <- data.frame(read_xls(paste0(cdb_path, "/CDB 2009.xls"), sheet=1))
names(questions_dat) <- questions_dat[4,]
questions_dat <- questions_dat[-(1:4),]
name_vec <- paste0("code_", questions_dat$Code[match(names(cdb_2009),questions_dat$`Short Question`)])
names(cdb_2009) <- ifelse(name_vec=="code_NA", names(cdb_2009), name_vec)

##########

cdb_2010_1 <- read_xlsx(paste0(cdb_path, "/CDB 2010.xlsx"), sheet=2)
cdb_2010_1 <- data.frame(cdb_2010_1)
names(cdb_2010_1) <- cdb_2010_1[4,]
cdb_2010_1 <- cdb_2010_1[-(1:4),]
#View(cdb_2010_1[1:1000, ])

cdb_2010_2 <- read_xlsx(paste0(cdb_path, "/CDB 2010.xlsx"), sheet=3)
cdb_2010_2 <- data.frame(cdb_2010_2)
names(cdb_2010_2) <- cdb_2010_2[4,]
cdb_2010_2 <- cdb_2010_2[-(1:4),]
#View(cdb_2010_2[1:1000, ])

cdb_2010 <- merge(cdb_2010_1, cdb_2010_2, by="VillGis", all=T)
rm(list = c("cdb_2010_1", "cdb_2010_2"))

questions_dat <- data.frame(read_xlsx(paste0(cdb_path, "/CDB 2010.xlsx"), sheet=1))
#names(questions_dat) <- questions_dat[4,]
#questions_dat <- questions_dat[-(1:4),]
name_vec <- paste0("code_", questions_dat$Code[match(names(cdb_2010),questions_dat$Short.Question)])
names(cdb_2010) <- ifelse(name_vec=="code_NA", names(cdb_2010), name_vec)

##########

cdb_2011_1 <- read_xlsx(paste0(cdb_path, "/CDB 2011.xlsx"), sheet=2)
cdb_2011_1 <- data.frame(cdb_2011_1)
names(cdb_2011_1) <- cdb_2011_1[4,]
# change_names <- function(x) {
#   a <- gregexpr('([0-9]+-)', x)
#   b <- regmatches(x, a)
#   return(gsub(b, "", x))
# }
#names(cdb_2011_1) <- sapply(names(cdb_2011_1), change_names)
cdb_2011_1 <- cdb_2011_1[-(1:4),]
#View(cdb_2011_1[1:100,])

###

cdb_2011_2 <- read_xlsx(paste0(cdb_path, "/CDB 2011.xlsx"), sheet=3)
cdb_2011_2 <- data.frame(cdb_2011_2)
names(cdb_2011_2) <- cdb_2011_2[4,]
#names(cdb_2011_2) <- sapply(names(cdb_2011_2), change_names)
cdb_2011_2 <- cdb_2011_2[-(1:4),]
#View(cdb_2011_2[1:100,])

###

cdb_2011_3 <- read_xlsx(paste0(cdb_path, "/CDB 2011.xlsx"), sheet=4)
cdb_2011_3 <- data.frame(cdb_2011_3)
names(cdb_2011_3) <- cdb_2011_3[4,]
#names(cdb_2011_3) <- sapply(names(cdb_2011_3), change_names)
cdb_2011_3 <- cdb_2011_3[-(1:4),]
#View(cdb_2011_3[1:100,])

###

cdb_2011_4 <- read_xlsx(paste0(cdb_path, "/CDB 2011.xlsx"), sheet=5)
cdb_2011_4 <- data.frame(cdb_2011_4)
names(cdb_2011_4) <- cdb_2011_4[4,]
#names(cdb_2011_4) <- sapply(names(cdb_2011_4), change_names)
cdb_2011_4 <- cdb_2011_4[-(1:4),]
#View(cdb_2011_4[1:100,])

###

cdb_2011 <- merge(cdb_2011_1, cdb_2011_2, by="VillGis", all=T)
cdb_2011 <- merge(cdb_2011, cdb_2011_3, by="VillGis", all=T)
cdb_2011 <- merge(cdb_2011, cdb_2011_4, by="VillGis", all=T)
rm(list = c("cdb_2011_1", "cdb_2011_2", "cdb_2011_3", "cdb_2011_4"))

questions_dat <- data.frame(read_xlsx(paste0(cdb_path, "/CDB 2011.xlsx"), sheet=1))
names(questions_dat) <- questions_dat[4,]
questions_dat <- questions_dat[-(1:4),]
questions_dat$actual <- paste0(questions_dat$Code, "-", questions_dat$`Short Question`)
name_vec <- paste0("code_", questions_dat$Code[match(names(cdb_2011),questions_dat$actual)])
names(cdb_2011) <- ifelse(name_vec=="code_NA", names(cdb_2011), name_vec)

##########

cdb_2012_1 <- read_xlsx(paste0(cdb_path, "/CDB 2012.xlsx"), sheet=2)
cdb_2012_1 <- data.frame(cdb_2012_1)
names(cdb_2012_1) <- cdb_2012_1[4,]
#names(cdb_2012_1) <- sapply(names(cdb_2012_1), change_names)
cdb_2012_1 <- cdb_2012_1[-(1:4),]
#View(cdb_2012_1[1:100,])

###

cdb_2012_2 <- read_xlsx(paste0(cdb_path, "/CDB 2012.xlsx"), sheet=3)
cdb_2012_2 <- data.frame(cdb_2012_2)
names(cdb_2012_2) <- cdb_2012_2[4,]
#names(cdb_2012_2) <- sapply(names(cdb_2012_2), change_names)
cdb_2012_2 <- cdb_2012_2[-(1:4),]
#View(cdb_2012_2[1:100,])

###

cdb_2012_3 <- read_xlsx(paste0(cdb_path, "/CDB 2012.xlsx"), sheet=4)
cdb_2012_3 <- data.frame(cdb_2012_3)
names(cdb_2012_3) <- cdb_2012_3[4,]
#names(cdb_2012_3) <- sapply(names(cdb_2012_3), change_names)
cdb_2012_3 <- cdb_2012_3[-(1:4),]
#View(cdb_2012_3[1:100,])

###

cdb_2012 <- merge(cdb_2012_1, cdb_2012_2, by="VillGis", all=T)
cdb_2012 <- merge(cdb_2012, cdb_2012_3, by="VillGis", all=T)
rm(list = c("cdb_2012_1", "cdb_2012_2", "cdb_2012_3"))

questions_dat <- data.frame(read_xlsx(paste0(cdb_path, "/CDB 2012.xlsx"), sheet=1))
names(questions_dat) <- questions_dat[4,]
questions_dat <- questions_dat[-(1:4),]
questions_dat$actual <- paste0(questions_dat$Code, "-", questions_dat$`Short Question`)

name_vec <- paste0("code_", questions_dat$Code[match(names(cdb_2012),questions_dat$actual)])
names(cdb_2012) <- ifelse(name_vec=="code_NA", names(cdb_2012), name_vec)

##########

cdb_2013 <- read_xlsx(paste0(cdb_path, "/CDB 2013.xlsx"), sheet=2)
cdb_2013 <- data.frame(cdb_2013)
names(cdb_2013) <- cdb_2013[4,]
#names(cdb_2013) <- sapply(names(cdb_2013), change_names)
cdb_2013 <- cdb_2013[-(1:4),]
#View(cdb_2013[1:100,])

questions_dat <- data.frame(read_xlsx(paste0(cdb_path, "/CDB 2013.xlsx"), sheet=1))
names(questions_dat) <- questions_dat[4,]
questions_dat <- questions_dat[-(1:4),]
questions_dat$actual <- paste0(questions_dat$Code, "-", questions_dat$`Short Question`)

name_vec <- paste0("code_", questions_dat$Code[match(names(cdb_2013),questions_dat$actual)])
names(cdb_2013) <- ifelse(name_vec=="code_NA", names(cdb_2013), name_vec)


##########

cdb_2014_1 <- read_xlsx(paste0(cdb_path, "/CDB 2014.xlsx"), sheet=2)
cdb_2014_1 <- data.frame(cdb_2014_1)
names(cdb_2014_1) <- cdb_2014_1[4,]
#names(cdb_2014_1) <- sapply(names(cdb_2014_1), change_names)
cdb_2014_1 <- cdb_2014_1[-(1:4),]
#View(cdb_2014_1[1:100,])

###

cdb_2014_2 <- read_xlsx(paste0(cdb_path, "/CDB 2014.xlsx"), sheet=3)
cdb_2014_2 <- data.frame(cdb_2014_2)
names(cdb_2014_2) <- cdb_2014_2[4,]
#names(cdb_2014_2) <- sapply(names(cdb_2014_2), change_names)
cdb_2014_2 <- cdb_2014_2[-(1:4),]
#View(cdb_2014_2[1:100,])

###

cdb_2014_3 <- read_xlsx(paste0(cdb_path, "/CDB 2014.xlsx"), sheet=4)
cdb_2014_3 <- data.frame(cdb_2014_3)
names(cdb_2014_3) <- cdb_2014_3[4,]
#names(cdb_2014_3) <- sapply(names(cdb_2014_3), change_names)
cdb_2014_3 <- cdb_2014_3[-(1:4),]
#View(cdb_2014_3[1:100,])

###

cdb_2014 <- merge(cdb_2014_1, cdb_2014_2, by="VillGis", all=T)
cdb_2014 <- merge(cdb_2014, cdb_2014_3, by="VillGis", all=T)
rm(list = c("cdb_2014_1", "cdb_2014_2", "cdb_2014_3"))


questions_dat <- data.frame(read_xlsx(paste0(cdb_path, "/CDB 2014.xlsx"), sheet=1))
names(questions_dat) <- questions_dat[4,]
questions_dat <- questions_dat[-(1:4),]
questions_dat$actual <- paste0(questions_dat$Code, "-", questions_dat$`Short Question`)

name_vec <- paste0("code_", questions_dat$Code[match(names(cdb_2014),questions_dat$actual)])
names(cdb_2014) <- ifelse(name_vec=="code_NA", names(cdb_2014), name_vec)


##########

cdb_2015_1 <- read_xlsx(paste0(cdb_path, "/CDB 2015.xlsx"), sheet=2)
cdb_2015_1 <- data.frame(cdb_2015_1)
names(cdb_2015_1) <- cdb_2015_1[4,]
#names(cdb_2015_1) <- sapply(names(cdb_2015_1), change_names)
cdb_2015_1 <- cdb_2015_1[-(1:4),]
#View(cdb_2015_1[1:100,])

###

cdb_2015_2 <- read_xlsx(paste0(cdb_path, "/CDB 2015.xlsx"), sheet=3)
cdb_2015_2 <- data.frame(cdb_2015_2)
names(cdb_2015_2) <- cdb_2015_2[4,]
#names(cdb_2015_2) <- sapply(names(cdb_2015_2), change_names)
cdb_2015_2 <- cdb_2015_2[-(1:4),]
#View(cdb_2015_2[1:100,])

###

cdb_2015_3 <- read_xlsx(paste0(cdb_path, "/CDB 2015.xlsx"), sheet=4)
cdb_2015_3 <- data.frame(cdb_2015_3)
names(cdb_2015_3) <- cdb_2015_3[4,]
#names(cdb_2015_3) <- sapply(names(cdb_2015_3), change_names)
cdb_2015_3 <- cdb_2015_3[-(1:4),]
#View(cdb_2015_3[1:100,])

###

cdb_2015 <- merge(cdb_2015_1, cdb_2015_2, by="VillGis", all=T)
cdb_2015 <- merge(cdb_2015, cdb_2015_3, by="VillGis", all=T)
rm(list = c("cdb_2015_1", "cdb_2015_2", "cdb_2015_3"))


questions_dat <- data.frame(read_xlsx(paste0(cdb_path, "/CDB 2015.xlsx"), sheet=1))
names(questions_dat) <- questions_dat[4,]
questions_dat <- questions_dat[-(1:4),]
questions_dat$actual <- paste0(questions_dat$Code, "-", questions_dat$`Short Question`)

name_vec <- paste0("code_", questions_dat$Code[match(names(cdb_2015),questions_dat$actual)])
names(cdb_2015) <- ifelse(name_vec=="code_NA", names(cdb_2015), name_vec)


##########

cdb_2016_1 <- read_xlsx(paste0(cdb_path, "/CDB 2016.xlsx"), sheet=2)
cdb_2016_1 <- data.frame(cdb_2016_1)
names(cdb_2016_1) <- cdb_2016_1[4,]
#names(cdb_2016_1) <- sapply(names(cdb_2016_1), change_names)
cdb_2016_1 <- cdb_2016_1[-(1:4),]
#View(cdb_2016_1[1:100,])

###

cdb_2016_2 <- read_xlsx(paste0(cdb_path, "/CDB 2016.xlsx"), sheet=3)
cdb_2016_2 <- data.frame(cdb_2016_2)
names(cdb_2016_2) <- cdb_2016_2[4,]
#names(cdb_2016_2) <- sapply(names(cdb_2016_2), change_names)
cdb_2016_2 <- cdb_2016_2[-(1:4),]
#View(cdb_2016_2[1:100,])

###

cdb_2016_3 <- read_xlsx(paste0(cdb_path, "/CDB 2016.xlsx"), sheet=4)
cdb_2016_3 <- data.frame(cdb_2016_3)
names(cdb_2016_3) <- cdb_2016_3[4,]
#names(cdb_2016_3) <- sapply(names(cdb_2016_3), change_names)
cdb_2016_3 <- cdb_2016_3[-(1:4),]
#View(cdb_2016_3[1:100,])

###

cdb_2016 <- merge(cdb_2016_1, cdb_2016_2, by="VillGis", all=T)
cdb_2016 <- merge(cdb_2016, cdb_2016_3, by="VillGis", all=T)
rm(list = c("cdb_2016_1", "cdb_2016_2", "cdb_2016_3"))


questions_dat <- data.frame(read_xlsx(paste0(cdb_path, "/CDB 2016.xlsx"), sheet=1))
names(questions_dat) <- questions_dat[4,]
questions_dat <- questions_dat[-(1:4),]
questions_dat$actual <- paste0(questions_dat$Code, "-", questions_dat$`Short Question`)

name_vec <- paste0("code_", questions_dat$Code[match(names(cdb_2016),questions_dat$actual)])
names(cdb_2016) <- ifelse(name_vec=="code_NA", names(cdb_2016), name_vec)

##########

cdb_2008$year <- 2008
cdb_2009$year <- 2009
cdb_2010$year <- 2010
cdb_2011$year <- 2011
cdb_2012$year <- 2012
cdb_2013$year <- 2013
cdb_2014$year <- 2014
cdb_2015$year <- 2015
cdb_2016$year <- 2016

keep_names <- Reduce(intersect, lapply(list(cdb_2008, 
                                            cdb_2009, 
                                            cdb_2010, 
                                            cdb_2011, 
                                            cdb_2012, 
                                            cdb_2013, 
                                            cdb_2014, 
                                            cdb_2015, 
                                            cdb_2016), names))

cdb <- rbind(cdb_2008[,keep_names], 
             cdb_2009[,keep_names],
             cdb_2010[,keep_names],
             cdb_2011[,keep_names],
             cdb_2012[,keep_names],
             cdb_2013[,keep_names],
             cdb_2014[,keep_names],
             cdb_2015[,keep_names],
             cdb_2016[,keep_names])

write.csv(cdb, "/Users/christianbaehr/Downloads/cdb.csv", row.names = F)

shps <- st_read("/Users/christianbaehr/Downloads/cambodia_ndvi_eval/inputData/census_2008_villages/Village.shp",
                stringsAsFactors=F)
shps <- shps[, c("VILL_CODE", "VILL_NAME", "XCOOR", "YCOOR", "geometry")]
shps$VILL_CODE<-as.numeric(shps$VILL_CODE)

View(shps[1:100, ])
as.numeric(shps$VILL_CODE)

villGis <- unique(as.numeric(cdb$VillGis))
sum(villGis %in% shps$VILL_CODE)
villGis[!(villGis %in% shps$VILL_CODE)]

##########

# commune

cdb_commune_2008 <- read_xls(paste0(cdb_path, "/CDB 2008.xls"), sheet=4)

cdb_commune_2009 <- read_xls(paste0(cdb_path, "/CDB 2009.xls"), sheet=4)

cdb_commune_2010 <- read_xls(paste0(cdb_path, "/CDB 2010.xls"), sheet=4)

cdb_commune_2011 <- read_xlsx(paste0(cdb_path, "/CDB 2011.xlsx"), sheet=6)

cdb_commune_2013_1 <- read_xlsx(paste0(cdb_path, "/CDB 2011.xlsx"), sheet=3)
cdb_commune_2013_2 <- read_xlsx(paste0(cdb_path, "/CDB 2011.xlsx"), sheet=4)

cdb_commune_2014_1 <- read_xlsx(paste0(cdb_path, "/CDB 2014.xlsx"), sheet=5)
cdb_commune_2014_2 <- read_xlsx(paste0(cdb_path, "/CDB 2014.xlsx"), sheet=6)










#Head ---------------------------------
# purpose: 

##Prerequisites:
## 

# 1 Libraries ---------------------------------
library(sf)
library(RCurl)
library(geojsonio)
library(tidyverse)
library(RJSONIO)
library(units)
library(geojsonsf)
library(tictoc)

source("src/5_data_completeness/ohsome_stat.R") # get ohsome data


                                      # ---
                                      ## start timestamp forthe full script
                                      tic("total")
                                      Sys.sleep(1)
                                      # ---


# 2 Parameters -----------------------------

                                      # ---
                                      ## start timestamp for the section
                                      tic("step 2 - Define parameters")
                                      Sys.sleep(2)
                                      # ---
                                      

## 2.1 Set automatic parameters -------------------------------------------
### 2.1.1 Create a folder to store the processed files ----------------------------
dir.create("data")
dir.create("data/results")
dir.create("data/results/completeness")                                       
                                      
### 2.1.2 Set the input and output path ----------- 
### input
boundary_path <- "data/download/boundary/MOZ_adm0_boundary.gpkg"
impact_area_path <- "data/download/impact_area/impact_area.gpkg"
### output
completeness_path <- "data/results/completeness/ohsomeStats.Rdata"

### 2.1.3 read the input data -------------------
#boundaryGeoJ <- st_read(dsn = boundary_path, layer = "MOZ_adm0_boundary")  %>% sf_geojson()

boundary <- st_read(dsn = boundary_path, layer = "MOZ_adm0_boundary")
flood_bb <- st_read(dsn = impact_area_path, layer = "simpl_impact_area") %>%  st_bbox()
flood_bb_sf <- st_as_sfc(flood_bb)

# reduce the area of focus to the bbox of the impact area
flood_GeoJ <- st_crop(boundary, flood_bb) %>% sf_geojson()

noflood_GeoJ <- st_difference(boundary, flood_bb_sf) %>% sf_geojson()

## 2.2 OSM entities scope -------------------------------------------

# Contribution over time
theTime <- "2007-12-01/2021-01-01/P1M"

# Scope of primary health facilities
primary_filter <- "amenity=clinic or
                  amenity=health_post or
                  amenity=doctors or
                  healthcare=doctors or
                  healthcare=clinic or
                  healthcare=health_post or
                  healthcare=midwife or
                  healthcare=nurse or
                  healthcare=center"

# Scope of non primary health facilities
non_primary_filter <- "amenity=hospital or
                       healthcare=hospital or
                       building=hospital"

# Scope of road network
highwayClasses <- "motorway,
                  trunk,
                  primary,
                  secondary,
                  tertiary,
                  unclassified,
                  track,
                  path" 

# Scope of user activities on amenity
AmenityUsersClasses <- "doctors,
                        clinic,
                        hospital"
                                            # ---
                                            ## stop timestamp for the section
                                            toc(log = TRUE, quiet = TRUE)
                                            # ---


# 3 Retrieve the OSM contribution data -----------              
                                            # ---
                                            ## start timestamp for the section
                                            tic("step 3 - Retrieve the OSM contribution")
                                            Sys.sleep(2)
                                            # ---


## 3.1 Health facilities ----------------------

### 3.1.1 Health facilities on flooded area --------------
# Retrieve primary facilities from Ohsome
resPrimaryFlood <- getOhsomeStat(uri = "https://api.ohsome.org/v1/elements/count/",
                           bpolys= flood_GeoJ,
                           filter = primary_filter,
                           time = theTime,
                           valueFieldName = "primaryCount")

# Retrieve non primary facilities from Ohsome
resNonPrimaryFlood <- getOhsomeStat(uri = "https://api.ohsome.org/v1/elements/count/",
                              bpolys= flood_GeoJ,
                              filter = non_primary_filter,
                              time = theTime,
                              valueFieldName = "non_primaryCount")

# Bind together both healthcare level facilities
resHsFlood <- cbind(resPrimaryFlood,
             resNonPrimaryFlood$non_primaryCount)

# rename the column
names(resHsFlood) <- c("timestamp", "primaryCount", "non_primaryCount")

### 3.1.2 Health facilities on non flooded area --------------
# Retrieve primary facilities from Ohsome
resPrimaryNoFlood <- getOhsomeStat(uri = "https://api.ohsome.org/v1/elements/count/",
                                 bpolys= noflood_GeoJ,
                                 filter = primary_filter,
                                 time = theTime,
                                 valueFieldName = "primaryCount")

# Retrieve non primary facilities from Ohsome
resNonPrimaryNoFlood <- getOhsomeStat(uri = "https://api.ohsome.org/v1/elements/count/",
                                    bpolys= noflood_GeoJ,
                                    filter = non_primary_filter,
                                    time = theTime,
                                    valueFieldName = "non_primaryCount")

# Bind together both healthcare level facilities
resHsNoFlood <- cbind(resPrimaryNoFlood,
                    resNonPrimaryNoFlood$non_primaryCount)

# rename the column
names(resHsNoFlood) <- c("timestamp", "primaryCount", "non_primaryCount")



## 3.2 Highway ----------------------

### 3.2.1 Highway on flooded area --------------
resRoadContribLengthFlood <- getGroupByValues(uri="https://api.ohsome.org/v1/elements/length/groupBy/tag",
                                      bpolys= flood_GeoJ,
                                      groupByKey = "highway",
                                      filter = "highway=*",
                                      time = theTime,
                                      groupByValues= highwayClasses)


### 3.2.2 Highway on non flooded area --------------
resRoadContribLengthNoFlood <- getGroupByValues(uri="https://api.ohsome.org/v1/elements/length/groupBy/tag",
                                              bpolys= noflood_GeoJ,
                                              groupByKey = "highway",
                                              filter = "highway=*",
                                              time = theTime,
                                              groupByValues= highwayClasses)


## 3.3 Users activity ----------------------

### 3.3.1 User activity on flooded area --------------

# Retrieve active users on highway
resActiveUsersHighwFlood <- getOhsomeStat(uri = "https://api.ohsome.org/v1/users/count/",
                                       bpolys= flood_GeoJ,
                                       filter = "highway=* and type:way",
                                       time = theTime,
                                       valueFieldName = "countHighwayUsers")



# Retrieve active users on amenity
resActiveUsersAmenityFlood <- getGroupByValues(uri="https://api.ohsome.org/v1/users/count/groupBy/tag",
                                          bpolys= flood_GeoJ,
                                          groupByKey = "amenity",
                                          filter = "amenity=*",
                                          time = theTime,
                                          groupByValues= AmenityUsersClasses)



### 3.3.2 User activity on non flooded area --------------


# Retrieve active users on highway
resActiveUsersHighwNoFlood <- getOhsomeStat(uri = "https://api.ohsome.org/v1/users/count/",
                                       bpolys= noflood_GeoJ,
                                       filter = "highway=* and type:way",
                                       time = theTime,
                                       valueFieldName = "countHighwayUsers")

# Retrieve active users on amenity
resActiveUsersAmenityNoFlood  <- getGroupByValues(uri="https://api.ohsome.org/v1/users/count/groupBy/tag",
                                               bpolys= noflood_GeoJ,
                                               groupByKey = "amenity",
                                               filter = "amenity=*",
                                               time = theTime,
                                               groupByValues= AmenityUsersClasses)



## 3.4 Save the output ----------------------
#Results are serialized to be used by the following scripts.
save(resHsFlood,
     resHsNoFlood,
     resRoadContribLengthFlood,
     resRoadContribLengthNoFlood,
     resActiveUsersHighwFlood,
     resActiveUsersAmenityFlood,
     resActiveUsersHighwNoFlood,
     resActiveUsersAmenityNoFlood,
     file= completeness_path)



                                    ## stop timestamp for the section
                                    toc(log = TRUE, quiet = TRUE)
                                    # ---

# 4 Output messages --------------------------------

## 4.1 Running time ------------------------

## stop timestamp fof the script
toc(log = TRUE, quiet = TRUE)

## print timestamps results
log.txt <- tic.log(format = TRUE)
print(log.txt)
tic.clearlog() # clear the logs of timestamps
                                      
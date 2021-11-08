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

source("src/7_data_completeness/ohsome_stat.R") # get ohsome data


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
aggreg_completeness_path <- "data/results/completeness/aggreg_ohsomeStats.Rdata"

### 2.1.3 read the input data -------------------

boundaryGeoJ <- st_read(dsn = boundary_path, layer = "MOZ_adm0_boundary") %>% sf_geojson()

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
                                            
# Retrieve primary facilities from Ohsome
resPrimary <- getOhsomeStat(uri = "https://api.ohsome.org/v1/elements/count/",
                           bpolys= boundaryGeoJ,
                           filter = primary_filter,
                           time = theTime,
                           valueFieldName = "primaryCount")

# Retrieve non primary facilities from Ohsome
resNonPrimary<- getOhsomeStat(uri = "https://api.ohsome.org/v1/elements/count/",
                              bpolys= boundaryGeoJ,
                              filter = non_primary_filter,
                              time = theTime,
                              valueFieldName = "non_primaryCount")

# Bind together both healthcare level facilities
resHs <- cbind(resPrimary,
               resNonPrimary$non_primaryCount)

# rename the column
names(resHs) <- c("timestamp", "primaryCount", "non_primaryCount")


## 3.2 Highway ----------------------
resRoadContribLength <- getGroupByValues(uri="https://api.ohsome.org/v1/elements/length/groupBy/tag",
                                      bpolys = boundaryGeoJ,
                                      groupByKey = "highway",
                                      filter = "highway=*",
                                      time = theTime,
                                      groupByValues= highwayClasses)


## 3.3 Users activity ----------------------

#Retrieve active users on highway
resActiveUsersHighw <- getOhsomeStat(uri = "https://api.ohsome.org/v1/users/count/",
                                       bpolys= boundaryGeoJ,
                                       filter = "highway=* and type:way",
                                       time = theTime,
                                       valueFieldName = "countHighwayUsers")


# Retrieve active users on amenity
resActiveUsersAmenity <- getGroupByValues(uri="https://api.ohsome.org/v1/users/count/groupBy/tag",
                                         bpolys= boundaryGeoJ,
                                         groupByKey = "amenity",
                                         filter = "amenity=*",
                                         time = theTime,
                                         groupByValues= AmenityUsersClasses)




## 3.4 Save the output ----------------------
#Results are serialized to be used by the following scripts.
save(resHs,
     resRoadContribLength,
     resActiveUsersHighw,
     resActiveUsersAmenity,
     file= aggreg_completeness_path)



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
                                      
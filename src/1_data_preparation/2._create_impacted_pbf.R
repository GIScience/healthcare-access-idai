# Head ---------------------------------
# Author: Sami Petricola
## purpose: create a new osm.pbf file of the studied country trimmed off the impacted area
## This file, will be used to construct the graphs of the openrouteservice backend
## Process: 
### - create a .poly file that can be used by osmosis to trim the original .osm.pbf file
### - launch osmosis to trim the new file

# Prerequisite:
## install osmosis on your machine:  https://wiki.openstreetmap.org/wiki/Osmosis/Installation


# 1 Libraries ---------------------------------
library(tidyverse) # get data wrangling functions
library(sf) # spatial stuff
sf_use_s2(FALSE) # last version of sf uses s2 instead of GEOS for ellipsoidal coordinates but it presents some bugs so we disactivate it:https://github.com/r-spatial/sf/issues/1649
library(tictoc) # measuring script running time
library(osmextract) # download the .osm.pbf file from one of the official database
library(rmapshaper) # library to simplify polygons
library(sfheaders) # remove holes from polygons

                      # ---
                      ## start timestamp forthe full script
                      tic("Total")
                      Sys.sleep(1)
                      # ---

# 2 Parameters ---------------------------------

                      # ---
                      ## start timestamp for the section
                      tic("step 2 - Define parameters")
                      Sys.sleep(2)
                      # ---
  
## 2.1 set the name of the studied country -------------------
country_name <- "Mozambique"


## 2.2 create a directory to store our files -------------------
dir.create("local-ors")
dir.create("local-ors/ors-impact")
dir.create("local-ors/ors-normal")
dir.create("local-ors/ors-impact/data")
dir.create("local-ors/ors-normal/data")
poly_path <- paste0("local-ors/ors-impact/data/",country_name,"_filter.poly")
new_pbf_path <- paste0("local-ors/ors-impact/data/",country_name,"_impacted.osm.pbf")

                      # ---
                      ## stop timestamp for the section
                      toc(log = TRUE, quiet = TRUE)
                      # ---


# 3 Preprocessing of the input data ---------------------------------

                      # ---
                      ## start timestamp for the section
                      tic("step 3 - Preprocessing")
                      Sys.sleep(2)
                      # ---

                      
## 3.1 Country boundary -------------------
### the boundary of the country will be used to generate the .poly file
boundary_path <- "data/download/boundary/MOZ_adm0_boundary.gpkg"
boundary <- st_read(dsn=boundary_path)
boundary_bb <- st_read(dsn = boundary_path) %>% st_bbox() %>% st_as_sfc() #get the bbox of the country
                      
## 3.2 Impact_area ----------------------------
## the impact_area will be used to generate the .poly file
impact_area_path <- "data/download/impact_area/impact_area.gpkg"
### the use of .poly makes some requirements necessary:
### - the simpler the geometries, the speed of processing of osmosis will grow exponentially
### - the format must store each polygons into one section, therefore we must cast the multipolygons to polygons

impact_area <- st_read(dsn = impact_area_path, layer = "impact_area") %>%
               ms_simplify(keep = 0.01) %>% # simplification of geometry with  Visvalingam algorithm
               st_make_valid() %>%
               st_intersection(boundary) %>% # crop to the country boundary
               summarise() %>%  #convert to multipolygon to avoid overlap of geometries
               st_collection_extract("POLYGON") %>%  # convert all geometries to simgle polygon
               sf_remove_holes(close=TRUE) # make polygons without holes to avoid geometry errors

# write the processed impact area to be able to check the output
st_write(impact_area, dsn = impact_area_path, layer = "simpl_impact_area", append = F)

                      # ---
                      ## stop timestamp for the section
                      toc(log = TRUE, quiet = TRUE)
                      # --- 
                      
# 4 Create a .poly file ---------------------------------
## for more info about .poly format: https://wiki.openstreetmap.org/wiki/Osmosis/Polygon_Filter_File_Format

  # ---
  ## start timestamp for the section
  tic("step 4 - Create poly file")
  Sys.sleep(2)
  # ---

## 4.1 Open the writing strem ------------------------------------
sink(poly_path) #start a stream to write a txt file (.poly is txt format)
cat(paste0(country_name,"_filter.poly","\n")) # first line is the to name of file

## 4.2 Create the first section of .poly ------------------------------------
### the .poly is structured around section (one polygon by section)
### the first section is our country border
cat(paste0(country_name,"_boundary","\n")) # to start the section, write the name of the section
country_coord <- st_coordinates(boundary_bb) # retrieve the coordinate of the polygon as an array
for (i in 1:length(country_coord[,1])){ # loop through each node of the polygon
  cat(paste0(" ",country_coord[i,1]," ",country_coord[i,2],"\n")) # write the coordinates of the node
}
cat(paste0("END","\n")) # terminate the section


## 4.3 Create the sections to be subtracted ------------------------------------
### the following sections are composed of each polygon of the impact_area to be substracted
for (i in 1:length(impact_area$geom)){ # loop through all the polygons of the impact_area
  cat(paste0("!","impact_area",i,"\n")) # write the name of the section, "!" indicates the section will be subtracted and not added
  impact_coord<- st_coordinates(impact_area$geom[i]) # retrieve the coordinate of the polygon as an array
  for (j in 1:length(impact_coord[,1])){ # loop through each node of the polygon
    cat(paste0(" ",impact_coord[j,1]," ",impact_coord[j,2],"\n")) # write the coordinates of the node
  }
  cat(paste0("END","\n")) # terminate the section
}

cat("END")# end of the .poly file
sink()# end the writing stream

                          # ---
                          ## stop timestamp for the section
                          toc(log = TRUE, quiet = TRUE)
                          # --- 


# 5 Create a new .osm.pbf based on the area defined in .poly file ---------------------------------

                        # ---
                        ## start timestamp for the section
                        tic("step 5 - Create a new .osm.pbf based on the area defined in .poly file")
                        Sys.sleep(2)
                        # ---
  
## 5.1 download the original .osm.pbf file from the official database -------------------
osm_url <- oe_match(country_name)$url #function to get the downloading url
oe_download(file_url = osm_url, download_directory = "local-ors/ors-normal/data") # download the .osm.pbf file from database

## 5.2 launch osmosis on command line -------------------

cmd <- "osmosis "
arg_read <-"--read-pbf file=local-ors/ors-normal/data/geofabrik_mozambique-latest.osm.pbf "
arg_bounding <- paste0("--bounding-polygon file=",poly_path, " ")
arg_write <- paste0("--write-pbf file=",new_pbf_path)
system(paste0(cmd,arg_read,arg_bounding,arg_write))


                      ## stop timestamp for the section
                      toc(log = TRUE, quiet = TRUE)

# 6 Output messages --------------------------------

## 6.1 Running time ------------------------

                      ## stop timestamp fof the script
                      toc(log = TRUE, quiet = TRUE)

## print timestamps results
log.txt <- tic.log(format = TRUE)
print(log.txt)
tic.clearlog() # clear the logs of timestamps


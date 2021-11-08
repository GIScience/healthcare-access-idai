# Head ---------------------------------
# Author: Sami Petricola
# purpose: Function to retrieve the different datasets required to perform the accessibility analysis:
# healthcare (or other facilities) from OSM via ohsome endpoint
# populations estimations from worldpop


# 1 Libraries ---------------------------------
library(rgeoboundaries) # get border data
library(tidyverse) # get data wrangling functions
library(sf) # spatial stuff
library(raster)

source("src/1_data_preparation/1.0_download_ohsome.R") # get ohsome data

                # ---
                # start timestamp forthe full script
                tic("Total")
                Sys.sleep(1)
                # ---

# 2 Parameters ---------------------------------

                # ---
                ## start timestamp for the section
                tic("step 2 - Parameters")
                Sys.sleep(2)
                # ---

## 2.1 Create the directory to store output datasets ---------
dir.create("data")
dir.create("data/download")

## 2.2 Define the analysis scope  ---------------------------------
country <- "MOZ" # use the ISO code alpha 3 of the country of interest
# scope <- "all"  # choose between "primary", "non_primary" or "all"

                # ---
                ## stop timestamp for the section
                toc(log = TRUE, quiet = TRUE)
                # ---

    # 3 Download country borders ---------------------------------
  
                # ---
                ## start timestamp for the section
                tic("step 3 - Download country borders ")
                Sys.sleep(2)
                # ---
  
    # Set the directory to store the files
    dir.create("data/download/boundary")
    # Set the name of the output file
    boundary_name <- paste0(country, "_adm0_boundary")
    # Download the boundary from geoboundaries
    boundary <- gb_adm0(country = country, type = "SSCGS")
    # write to gpkg
    st_write(boundary,
             dsn = paste0("data/download/boundary/", boundary_name, ".gpkg"),
             layer = boundary_name,
             append=F
            )
    
                  # ---
                  ## stop timestamp for the section
                  toc(log = TRUE, quiet = TRUE)
                  # ---
    
    # 4 Retrieve OSM health_facilities ---------------------------------
    
                  # ---
                  ## start timestamp for the section
                  tic("step 4 - Retrieve OSM source points ")
                  Sys.sleep(2)
                  # ---

    # if (scope == "primary"){
    # osm_filter  = "amenity=clinic or
    #                amenity=health_post or
    #                amenity=doctors or
    #                healthcare=doctors or
    #                healthcare=clinic or
    #                healthcare=health_post or
    #                healthcare=midwife or
    #                healthcare=nurse or
    #                healthcare=center"
    # } else if (scope == "non-primary"){
    #   osm_filter = "amenity=hospital or
    #                 healthcare=hospital or
    #                 building=hospital"
    # } else if (scope == "all"){
    #   osm_filter = "amenity=clinic or
    #                 amenity=health_post or
    #                 amenity=doctors or
    #                 amenity=hospital or
    #                 healthcare=doctors or
    #                 healthcare=clinic or
    #                 healthcare=health_post or
    #                 healthcare=midwife or
    #                 healthcare=nurse or
    #                 healthcare=center or
    #                 healthcare=hospital or
    #                 building=hospital"
    # }

   osm_filter = "amenity=clinic or
                 amenity=health_post or
                 amenity=doctors or
                 amenity=hospital or
                 healthcare=doctors or
                 healthcare=clinic or
                 healthcare=health_post or
                 healthcare=midwife or
                 healthcare=nurse or
                 healthcare=center or
                 healthcare=hospital or
                 building=hospital"
                                
    health_facilities <- getOhsomeObjects(sf_boundary = boundary,
                                          filter_char = osm_filter,
                                          internal = FALSE,
                                          #to_time = "2021-04-01",
                                          to_time = "2021-07-01",
                                          props = "tags")
                                    

    # write to geopackage
    # st_write(health_facilities[,1:20], dsn = "data/download/source_points.gpkg", layer = scope, append = F)
    st_write(health_facilities[,1:20], dsn = "data/download/health_facilities.gpkg", layer = "health_facilities", append = F)
            # ---
            # stop timestamp for the section
            toc(log = TRUE, quiet = TRUE)
            # ---
    
    # 5 Preparation of the population estimation ---------------------------------
    
            # ---
            # start timestamp for the section
            tic("step 5 - Retrieve population data ")
            Sys.sleep(2)
            # ---
            
    # Create a folder to store the downloaded files
    dir.create("data/download/population")
    # extract the three letter country code from the boundary file
    country <- boundary$shapeGroup
    
    # set the url according to the country of interest
    worldpop <-paste0(
                  "https://data.worldpop.org/GIS/Population/Global_2000_2020_Constrained/2020/maxar_v1/",
                  country,
                  "/",
                  tolower(country),
                  "_ppp_2020_UNadj_constrained.tif"
                )
    ### download the population data as a .tif file in the data folder
    download_pop_path <-paste0("data/download/population/population_2020_const_",
                               country,
                               ".tif") # first we set the path to download the file
    download.file(worldpop, download_pop_path) # then we download it

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
    
    
    
    
    ## 6.2 Results ------------------------
    
    message("step 4 - Retrieve OSM source points:")
    message( paste0("Country: ", country))
    message(length(health_facilities$geometry), " OSM entities downloaded")
    
    message( "step 5 - Download population data: ")
    message( paste0("Country: ", country))
    message( "Population file downloaded")
    

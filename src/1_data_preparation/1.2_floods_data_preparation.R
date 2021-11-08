# Head ---------------------------------
# Author: Sami Petricola
# Purpose: Function to retrieve and process the impacted area


# 1 Libraries ---------------------------------
library(tidyverse) # get data wrangling functions
library(sf) # spatial stuff
library(tictoc) # timestamps
library(stars) # raster to vector

                        # ---
                        # start timestamp forthe full script
                        tic("Total")
                        Sys.sleep(1)
                        # ---

# 2 Parameters ---------------------------------

                        # ---
                        ## start timestamp for the section
                        tic("step 1 - Parameters")
                        Sys.sleep(2)
                        # ---

# Create the directory to store output dataset
dir.create("data")
dir.create("data/download") # Create a folder to store the downloaded files
dir.create("data/download/impact_area")
dir.create("data/download/impact_area/unzipped")


# Define the path for the output data
impact_area_path <- "data/download/impact_area/impact_area.gpkg"

                    
                        # ---
                        ## stop timestamp for the section
                        toc(log = TRUE, quiet = TRUE)
                        # ---


# 3 Preparation of impact area data ---------------------------------

                        # ---
                        # start timestamp for the section
                        tic("step 3 - retrieve impact area ")
                        Sys.sleep(2)
                        # initialize the output count
                        step3_counter <- 0
                        # ---

## 3.1 Retrieve and process the unosat vector data -----------------------
### 3.1.1 Download the file ---------------------------------
UNOSAT_flooded <- download.file("https://unosat-maps.web.cern.ch/unosat-maps/MZ/TC20190312MOZ/TC20190312MOZ_SHP.zip",
                             destfile = "data/download/impact_area/unosat_flooded_area.zip")

### 3.1.2 Unzip the file ---------------------------------


# unzip the file
unzip(zipfile = "data/download/impact_area/unosat_flooded_area.zip", exdir = "data/download/impact_area/unzipped")

### 3.1.3 Read and merge the shapefiles ---------------------------------
# Create a list of the unzipped file names that we are interested in (the shapefiles of the observed_event)
path <- paste0("data/download/impact_area/unzipped/", list.files("data/download/impact_area/unzipped"))

unosat_water_shp <-
  list.files(path = "data/download/impact_area/unzipped/TC20190312MOZ_SHP",
             pattern = "Water.+.shp$")

# loop through the list of shapefiles to create a geopackage and append together all of the shapefiles
for (i in seq_along(unosat_water_shp)) {
  temp_shp <-
    paste0("data/download/impact_area/unzipped/TC20190312MOZ_SHP/",
           unosat_water_shp[i])
  temp_sf <- st_read(temp_shp) %>% st_transform(crs = 4326) %>% summarise()
  if (i == 1) {
    st_write(temp_sf,
             dsn = impact_area_path,
             layer = 'unosat',
             append = FALSE)
    step3_counter = step3_counter + 1 # increment the ouput count
  } else {
    st_write(temp_sf,
             dsn = impact_area_path,
             layer = 'unosat',
             append = TRUE)
    step3_counter = step3_counter + 1 # increment the ouput count
  }
}


## 3.2 Retrieve and process the wfp vector data -----------------------
### 3.2.1 Download the file ---------------------------------
WFP_flooded <- download.file("https://data.humdata.org/dataset/4b3930dc-21a4-43b3-9257-e1f552a969a6/resource/9a3f23c6-0cc3-4e99-bb72-0b4e099847df/download/moz_totalfloodextent.zip",
                                                     destfile = "data/download/impact_area/wfp_flooded_area.zip")

### 3.2.2 Unzip the file ---------------------------------
path <- "data/download/impact_area/unzipped/"
# unzip the file
unzip(zipfile = "data/download/impact_area/wfp_flooded_area.zip", exdir = path)

### 3.2.3 convert the tiff to gpkg ---------------------------------
# Create a list of the unzipped file names that we are interested in (the shapefiles of the observed_event)

wfp_tif <-
  list.files(path = path,
             pattern = "\\.tif$")

wfp_impact = st_as_sf(read_stars(paste0(path,wfp_tif))) %>% st_transform(crs = 4326) %>% summarise()
st_write(wfp_impact,
         dsn = impact_area_path,
         layer = 'wfp',
         append = FALSE)

## 3.3 Clean the environment ---------------------------------
# remove the directory of all unzipped vector files
unlink("data/download/impact_area/unzipped", recursive = TRUE)

                        # stop timestamp for the section
                        toc(log = TRUE, quiet = TRUE)
                        # ---


                        


# 4 Geoprocessing of impact area ---------------------------------
## To ease future processing of impact_area, we process the geometries to have reliant data:
## we ensure the geometries are valid
## we dissolve the polygons together
## we convert multipolygons to simple polygons
                        
                      # ---
                      # start timestamp for the section
                      tic("step 4 - Geoprocessing ")
                      Sys.sleep(2)
                      # initialize the output count


## 4.1  read the created gpkg ---------------------------------
unosat_impact <- st_read(dsn = impact_area_path, layer = 'unosat') %>% st_make_valid()
wfp_impact <- st_read(dsn = impact_area_path, layer = 'wfp') %>% st_make_valid()                     
## 4.2 union and make valid and convert to simple polygons --------------------------------
processed_impact_area <- st_union(wfp_impact,unosat_impact) %>% # dissolve the polygons
                         st_cast("POLYGON")

## 4.3 rewrite the output gpkg ---------------------------------
st_write(processed_impact_area,
         dsn = impact_area_path,
         layer = 'impact_area',
         append = FALSE)



                         # stop timestamp for the section
                         toc(log = TRUE, quiet = TRUE)
                         # ---

# 5 Output messages --------------------------------

## 5.1 Running time ------------------------

                          ## stop timestamp fof the script
                          toc(log = TRUE, quiet = TRUE)
                                      
## print timestamps results
log.txt <- tic.log(format = TRUE)
print(log.txt)
tic.clearlog() # clear the logs of timestamps


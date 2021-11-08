#Head ---------------------------------
# purpose: Function to calculate the isochrones access to healthcare facilities
## based on the local instance of ORS

##Prerequisites:
## Have your local instance of ORS running : https://github.com/GIScience/openrouteservice/blob/master/docker/README.md


# 0.1 Libraries ---------------------------------
library(rgeoboundaries)
library(tidyverse)
library(sf)
sf_use_s2(FALSE) # last version of sf uses s2 instead of GEOS for ellipsoidal coordinates but it presents some bugs so we disactivate it:https://github.com/r-spatial/sf/issues/1649
library(raster)
library(openrouteservice)
library(rjson)
library(tictoc)
library(exactextractr)
library(polylabelr)
library(stars)
library(tmap)
library(tmaptools)
library(OpenStreetMap)
library(grid)
library(gridExtra)
library(knitr)
library(ggplot2)
library(doParallel)

source("src/2_healthcare_access/vector_analysis/1.1_isochrones_local.R")
source("src/2_healthcare_access/vector_analysis/1.2_dissolve_isochrones.R")
source("src/2_healthcare_access/vector_analysis/1.3_difference_isochrones.R")
source("src/2_healthcare_access/vector_analysis/1.4_population_estimates.R")
source("src/2_healthcare_access/vector_analysis/2.1_loss_analysis.R")
source("src/2_healthcare_access/vector_analysis/2.2_loss_population_mask.R")

                                        # ---
                                        # start timestamp forthe full script
                                        tic("Total")
                                        Sys.sleep(1)
                                        # ---

# 0.2 - User defined parameters ---------------
country <- "MOZ" # use the ISO code alpha 3 of the country of interest
scope <- "all"  # choose between "primary", "non_primary" or "all"
profile <- "driving-car" # choose between "driving-car" and "foot-walking"

# 0.3 - Repository creation
dir.create("data")
dir.create("data/download")
dir.create("data/download/boundary")
dir.create("data/download/population")
dir.create("data/results")
dir.create(paste0("data/results/",profile ))
dir.create(paste0("data/results/",profile,"/isochrones"))



# 1 - Isochrones----------------
                                    # ---
                                    ## start timestamp for the section
                                    tic("step 1 - Isochrones")
                                    Sys.sleep(2)
                                    # ---

## 1.1 Parameters ---------
                                    
## Read input files 
health_facilities <- st_read(dsn = "data/download/health_facilities.gpkg", layer = scope)
boundary <- st_read(dsn = paste0("data/download/boundary/",country,"_adm0_boundary.gpkg" )) 
population <- raster(paste0("data/download/population/population_2020_const_",country,".tif"))

## Set the time ranges according to profile
if (profile == "driving-car"){
    intervals <- c(600, 1200, 1800, 2400, 3000, 3600)
} else if (profile == "foot-walking"){
    #intervals <- c(3600, 7200, 10800, 14400, 18000, 21600)
    intervals <- seq(0, 21600, 600) # for walking profile, results are visualised with a 1h interval but the analysis is done with a 10min interval
}


## 1.2 isochrones processing ------
# launch the isochrone processing in parallel for normal and flooded situations                                   
cl <- makeCluster(2, type = "FORK")
registerDoParallel(cl)
instances <-c("normal","impact")
foreach(i=1:length(instances),
        .packages=c("rgeoboundaries", 
                     "tidyverse",
                     "sf", 
                     "raster",
                     "openrouteservice", 
                     "rjson",
                     "exactextractr")) %dopar% {
                         
    isochrones_path <- paste0("data/results/",profile,"/isochrones/10min_",scope,"_",instances[i],"_isochrones.gpkg") 
                         
### 1.2.1 - isochrones from ORS API ----------------
    raw_isochrones <- getIsochrones(source_points, intervals, profile, instances[i])
    raw_isochrones <- getIsochrones(health_facilities, intervals, profile, instances[i])
    st_write(raw_isochrones, dsn = isochrones_path, layer = "raw_isochrones",append=F)
    
## 1.2.2 - dissolve isochrones ----------------
    dissolved_isochrones <- dissolveIsochrones(raw_isochrones, boundary)
    st_write(dissolved_isochrones, dsn = isochrones_path, layer = "dissolved_isochrones", append=F)
                       
## 1.2.3 - differentiate isochrones ----------------                       
    differenced_isochrones <- differentiateIsochrones(dissolved_isochrones, boundary)
    st_write(differenced_isochrones, dsn = isochrones_path, layer = "differenced_isochrones", append =F)
    
## 1.2.4 - differentiate isochrones ----------------
    isochrones_populated <- estimatePopulation(differenced_isochrones, population)
    st_write(isochrones_populated, dsn = isochrones_path, layer = "isochrones_populated", append=F)
}
stopCluster(cl)

                                    # ---
                                    ## stop timestamp for the section
                                    toc(log = TRUE, quiet = TRUE)
                                    # ---

# 2 - Access loss analysis ----------------
                                    
                                    # ---
                                    ## start timestamp for the section
                                    tic("step 2 - Access loss analysis")
                                    Sys.sleep(2)
                                    # ---
                                    
## 2.1 - access loss calculation ---------
calculateAccesLoss(profile, scope, country)


## 2.2 - population impacted by loss of access ---------
maskImpactedPopulation(profile, scope,country)
                                    
                                    ## stop timestamp for the section
                                    toc(log = TRUE, quiet = TRUE)


# 3 Output messages --------------------------------
                                    
## 3.1 Running time ------------------------
                                    
## stop timestamp fof the script
toc(log = TRUE, quiet = TRUE)
                                    
## print timestamps results
log.txt <- tic.log(format = TRUE)
print(log.txt)
tic.clearlog() # clear the logs of timestamps




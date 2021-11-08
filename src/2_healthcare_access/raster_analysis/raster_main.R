#Head ---------------------------------
# purpose: 


# 0.1 Libraries ---------------------------------
library(tidyverse) # get data wrangling functions
library(sf) # spatial stuff
sf_use_s2(FALSE) # last version of sf uses s2 instead of GEOS for ellipsoidal coordinates but it presents some bugs so we disactivate it:https://github.com/r-spatial/sf/issues/1649
library(tictoc) # measuring script running time
library(ggplot2)
library(grid)
library(gridExtra)
library(gdistance)
library(tidyverse) # get data wrangling functions
library(raster)
library(stars)
library(exactextractr)
library(polylabelr)
library(tmap)
library(tmaptools)
library(OpenStreetMap)
library(knitr)
library(doParallel)


source("src/2_healthcare_access/raster_analysis/1.1_raster_accessibility.R")
source("src/2_healthcare_access/raster_analysis/1.2_raster_categorisation.R")
source("src/2_healthcare_access/raster_analysis/2._raster_loss_analysis.R")

                                        # ---
                                        # start timestamp forthe full script
                                        tic("Total")
                                        Sys.sleep(1)
                                        # ---

# 0.2 - User defined parameters ---------------
country <- "MOZ" # use the ISO code alpha 3 of the country of interest
scope <- "all"  # choose between "primary", "non_primary" or "all"
profile <- "foot-walking" # choose between "driving-car" and "foot-walking"


# 0.3 - Repository creation
dir.create("data")
dir.create("data/download")
dir.create("data/download/friction")
dir.create(paste0("data/download/friction/",profile))
dir.create("data/download/boundary")
dir.create("data/download/population")
dir.create("data/results")
dir.create(paste0("data/results/",profile ))
dir.create(paste0("data/results/",profile,"/raster"))

                                    # ---
                                    ## stop timestamp for the section
                                    toc(log = TRUE, quiet = TRUE)
                                    # ---


                                    
# 1 - Raster accessibility ----------------
                                    # ---
                                    ## start timestamp for the section
                                    tic("step 1 - Raster accessibility")
                                    Sys.sleep(2)
                                    # ---                                   
                                    
## 1.1 - Parameters ----     
## Read input files                                
health_facilities <- st_read(dsn = "data/download/health_facilities.gpkg", layer = scope)
impact_area <- st_read(dsn = "data/download/impact_area/impact_area.gpkg", layer = "simpl_impact_area")
boundary <- st_read(dsn = paste0("data/download/boundary/",country,"_adm0_boundary.gpkg" )) 
population <- raster(paste0("data/download/population/population_2020_const_",country,".tif"))
                                    

## Set the time ranges according to profile
if (profile == "driving-car"){
  intervals <- c(-1,10, 20, 30, 40, 50, 60, 9999999)
} else if (profile == "foot-walking"){
  intervals <- c(seq(0, 360, 10),9999999)
}
                                    
                                    
## 1.2 - raster processing  ----    
                                    
### 1.2.1 - Friction layer download  ----  
### url to download according to profile
if (profile == "driving-car"){
  friction_url = "https://malariaatlas.org/geoserver/ows?service=CSW&version=2.0.1&request=DirectDownload&ResourceId=Explorer:2020_motorized_friction_surface"
  download_friction_zip = paste0("data/download/friction/",profile,"/2020_motorized_friction_surface.zip")
} else if (profile == "foot-walking"){
  friction_url = "https://malariaatlas.org/geoserver/ows?service=CSW&version=2.0.1&request=DirectDownload&ResourceId=Explorer:2020_walking_only_friction_surface"
  download_friction_zip = paste0("data/download/friction/",profile,"/2020_walking_only_friction_surface.zip")
}

### Download MAP access estimates
options(timeout = 4000)
if (!file.exists(download_friction_zip)) { # check if the file already exists
  download.file(friction_url, destfile = download_friction_zip) # it can take several minutes
}

                                
### 1.2.2 - get raster access ----------------
cl <- makeCluster(2, type = "FORK")
registerDoParallel(cl)
instances <-c("normal","impact")
foreach(i=1:length(instances),
        .packages=c("gdistance", 
                    "tidyverse",
                    "sf",
                    "raster",
                    "stars")) %dopar% {
                         

### 1.2.3 - get raster access ----------------
    raster_access <- getRasterAcces(impact_area, health_facilities, boundary, profile, instances[i])
    output.access <- paste0("data/results/",profile,"/raster/",scope,"_",instances[i],"_raster_accessibility.tif")             
    writeRaster(raster_access, output.access, format = "GTiff", overwrite = TRUE)                  
                      
    

    
    raster_cat <- categroriseAccess(raster_access, intervals)
    raster_cat_path <- paste0("data/results/",profile,"/raster/cat_",scope,"_",instances[i],"_raster_access.tif")
    writeRaster(raster_cat, raster_cat_path, format = "GTiff", overwrite = TRUE)
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
                                    
                                    
calculateAccesLoss(scope, profile, country)
calculateAccesLossCat(scope, profile, country)


                                    
                                    ## stop timestamp for the section
                                    toc(log = TRUE, quiet = TRUE)
            

# 3. Output messages --------------------------------
                                    
## 3.1 Running time ------------------------
                                    
## stop timestamp fof the script
toc(log = TRUE, quiet = TRUE)
                                    
## print timestamps results
log.txt <- tic.log(format = TRUE)
print(log.txt)
tic.clearlog() # clear the logs of timestamps




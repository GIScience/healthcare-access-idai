# Accessibility Mapping in R
# 
# Dan Weiss
# Telethon Kids Institute, Perth 
# Malaria Atlas Project, University of Oxford
# 2020-08-06
#
# This script requires the gdistance package (van Etten, J. R Package gdistance: Distances and Routes on Geographical Grids. Journal of Statistical Software 76, 1-21)
# https://cran.r-project.org/web/packages/gdistance/index.html
#
# This script requires the two user supplied datasets:
# (a) A friction surface, two of which are available here: https://malariaatlas.org/research-project/accessibility_to_healthcare/
# (b) A user-supplied .csv of points (i.e., known geographic coordinates) 
#
# Notes:
# (a) All file paths and names should be changed as needed.
# (b) Important runtime details can be found in the comments.
# (c) This script is suitable only for analyses of moderately sized areas (e.g., up to 10 million km^2 in lower latitude settings - GLOBAL RUNS WILL NOT WORK).
#     We recommend using Google Earth Engine for larger areas, with the exception of high-latitude areas where custom approaches are typically required.
#
# Citations: 
#
# D. J. Weiss, A. Nelson, C. A. Vargas-Ruiz, K. Gligoric, S. Bavadekar, E. Gabrilovich, A. Bertozzi-Villa, J. Rozier, H. S. Gibson, T. Shekel, C. Kamath, A. Lieber, K. Schulman,
# Y. Shao, V. Qarkaxhija, A. K. Nandi, S. H. Keddie, S. Rumisha, P. Amratia, R. Arambepola, E. G. Chestnutt, J. J. Millar, T. L. Symons, E. Cameron, K. E. Battle, S. Bhatt, 
# and P. W. Gething. Global maps of travel time to healthcare facilities. (2020) Nature Medicine.
#
# A. Nelson, D. J. Weiss, J. van Etten, A. Cattaneo, T. S. McMenomy,and J. Koo. A suite of global accessibility indicators. (2019). Nature Scientific Data. doi.org/10.1038/s41597-019-0265-5
#
# D. J. Weiss, A. Nelson, H.S. Gibson, W. Temperley, S. Peedell, A. Lieber, M. Hancher, E. Poyart, S. Belchior, N. Fullman, B. Mappin, U. Dalrymple, J. Rozier, 
# T.C.D. Lucas, R.E. Howes, L.S. Tusting, S.Y. Kang, E. Cameron, D. Bisanzio, K.E. Battle, S. Bhatt, and P.W. Gething. A global map of travel time to cities to assess 
# inequalities in accessibility in 2015. (2018). Nature. doi:10.1038/nature25181.
# 

getRasterAcces <- function (impact_area, health_facilities, boundary, profile, instance){
      
      # 1. Parameters ---------
      
      # travel speed
      if (profile == "foot-walking"){
      # 60 min/km is a travel speed used as reference for wetlands in literature https://forobs.jrc.ec.europa.eu/products/gam/sources.php 
      flooded_area_speed <- NA # travel speed in min/meter
      } else if (profile == "driving-car"){
        flooded_area_speed <- NA
      }
      
      
      ### Set the input and output path 
      
      ### output
      output.friction <- paste0("data/results/",profile,"/raster/",instance,"_friction.tif")
      download_friction_path = paste0("data/download/friction/",profile)
     
      # 2. Data preparation  ---------------------------------
      
      ## 2.1 Friction surface preparation  ---------------------------------
      
      ### 2.1.1 Unzip ----------------
      
      if (length(list.files(path = download_friction_path, pattern = "\\.geotiff$")) > 0) {
        tif_file <- paste0(download_friction_path,"/",list.files(path = download_friction_path, pattern = "\\.geotiff$"))
        friction <- raster(tif_file)
      } else {
        zipped_list <- list.files(download_friction_path)
        zip_path <- paste0("data/download/friction/",profile,"/",zipped_list)
        friction <- unzip(zipfile = zip_path, exdir = download_friction_path) %>% 
          raster()
      }
      
      ### 2.1.2 crop to country extent --------------------
      friction_moz <- friction %>% crop(boundary) %>% mask(boundary)
      
      
      ### 2.1.4 apply the flooded area correction to the friction layer
      if (instance == "impact"){ # correction to be done only for analysis considering flooded area
        impact_area$value <- flooded_area_speed
        friction_moz <- st_rasterize(impact_area, st_as_stars(friction_moz)) %>%
                        as("Raster")
      }
      
      pdf(NULL) #prevent Rplots.pdf to be generated
      writeRaster(friction_moz, output.friction, format = "GTiff", overwrite = TRUE)
                                        
      
      ## 2.2 Source points convertion to coordinates dataframe ---------------------------------
      source_coord <- st_coordinates(health_facilities)
      
 
      # 3. Friction surface preparation  ---------------------------------
 
      # Make and geocorrect the transition matrix (i.e., the graph)
        tr <- transition(friction_moz, function(x) 1/mean(x), 8) # RAM intensive, can be very slow for large areas
      
        
        tr.gc <- geoCorrection(tr)                    
      
        
      # Convert the points into a matrix
      xy.matrix <- as.matrix(source_coord)
      
      # Run the accumulated cost algorithm to make the final output map. This can be quite slow (potentially hours).
      trvlt.rast <- accCost(tr.gc, xy.matrix)
      
      
      
      
      return(trvlt.rast)

}

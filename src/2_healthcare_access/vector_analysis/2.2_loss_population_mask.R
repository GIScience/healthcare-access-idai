
maskImpactedPopulation <- function(profile, scope,country){

  ### 2.2.2 Set the path and file name of output according to analysis scope----------- 
  loss_path <- paste0("data/results/",profile,"/isochrones/10min_",scope,"_access_loss.gpkg") 
  population_path <- paste0("data/download/population/population_2020_const_",
                            country,
                            ".tif") # set the path to population raster downloaded with datapreparation.R
  ### ouput
  pop_impacted_path <- paste0("data/results/", profile,"/isochrones/10min_",scope,"_population_impacted.tif")  
  
  
  # 3 Crop the population to the loss polygons -------------------
  
  ## 3.1 Read the input files -----------------------
  population <- raster(population_path)
  loss_area <- st_read(dsn=loss_path, layer = "access_loss")                          
                              
  ## 3.2 Mask the raster  ------------------------
  
  pop_impacted <-mask(population, loss_area)
  
  ## 3.3 write to result to a new geotiff -------------------------------
  writeRaster(pop_impacted, pop_impacted_path, format = "GTiff", overwrite = TRUE)                                    

}



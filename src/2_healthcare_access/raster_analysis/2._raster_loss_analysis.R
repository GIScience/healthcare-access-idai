
calculateAccesLoss <- function(scope, profile, country){
          
          ### 2.2.2 Set the path and file name of output ----------- 
          ### raster accessibility
          normal_raster_path <- paste0("data/results/",profile,"/raster/",scope,"_normal_raster_accessibility.tif")
          impact_raster_path <- paste0("data/results/",profile,"/raster/",scope,"_impact_raster_accessibility.tif")
          
          ### other inputs
          population_path <- "data/download/population/population_2020_const_MOZ.tif"
          
          ### ouput
          loss_path <- paste0("data/results/",profile,"/raster/",scope,"_raster_access_loss.tif")                                    
          
          
          ### 2.2.3 read the input data-------------------
          normal_raster <- raster(normal_raster_path)  
          impact_raster <- raster(impact_raster_path) 
          
          population <- raster(population_path)

          # 3 Calculation of access loss -------------------------
 
          ## 3.1 Calculate the extent of loss areas----------------------                                      
          
          impact_raster[impact_raster > 420] <- 9999                                     
          normal_raster[normal_raster > 360] <- 9999                                     
                                                
          loss <- impact_raster - normal_raster
          loss[loss <= 0] <- NA
          
          ## 3.2 Write the resulting raster ----------
          pdf(NULL) #prevent Rplots.pdf to be generated
          writeRaster(loss, loss_path, overwrite = TRUE)
}      

calculateAccesLossCat <- function(scope, profile, country){
  
  ### 2.2.2 Set the path and file name of output ----------- 
  ### raster accessibility
  normal_cat_raster_path <- paste0("data/results/",profile,"/raster/cat_",scope,"_normal_raster_access.tif")
  impact_cat_raster_path <- paste0("data/results/",profile,"/raster/cat_",scope,"_impact_raster_access.tif")
  
  ### other inputs
  population_path <- "data/download/population/population_2020_const_MOZ.tif"
  
  ### ouput
  loss_cat_path <- paste0("data/results/",profile,"/raster/cat_",scope,"_raster_access_loss.tif")                                    
  
  
  ### 2.2.3 read the input data-------------------
  normal_cat_raster <- raster(normal_cat_raster_path)  
  impact_cat_raster <- raster(impact_cat_raster_path) 
  
  population <- raster(population_path)
  
  # 3 Calculation of access loss -------------------------
  
  ## 3.1 Calculate the extent of loss areas----------------------                                      
  
  loss_cat <- impact_cat_raster - normal_cat_raster
  loss_cat[loss_cat <= 0] <- NA
  
  ## 3.2 Write the resulting raster ----------
  pdf(NULL) #prevent Rplots.pdf to be generated
  writeRaster(loss_cat, loss_cat_path, overwrite = TRUE)
}
          
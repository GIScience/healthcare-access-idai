
calculateAccesLoss <- function(profile, scope, country){
  
      poi_threshold <- 0.0005 # radius(decimal degree) of the pole of inaccessibility to filter out the small loss_area due to geometry approximation of isochrones API
      
      
      ### 2.2.2 Set the path and file name of output according to analysis scope----------- 
      noimpact_isochrones_path <- paste0("data/results/",profile,"/isochrones/10min_",scope,"_normal_isochrones.gpkg")
      impact_isochrones_path <- paste0("data/results/",profile,"/isochrones/10min_",scope,"_impact_isochrones.gpkg")
      population_path <- paste0("data/download/population/population_2020_const_",
                                country,
                                ".tif") # set the path to population raster downloaded with datapreparation.R
      impact_area_path <- "data/download/impact_area/impact_area.gpkg"
      
      ### ouput    
      loss_path <- paste0("data/results/",profile,"/isochrones/10min_",scope,"_access_loss.gpkg")  
      
      
      ### 2.2.3 read the input data-------------------
      impact_area <- st_read(dsn = impact_area_path, layer = "simpl_impact_area")
      
      ## isochrones cropped to the extent of the impact area
      noimpact_iso <- st_read(dsn = noimpact_isochrones_path,
                              layer = "differenced_isochrones") %>%
                      st_crop(st_bbox(impact_area))
      ## isochrones cropped to the extent of the impact area  
      impact_iso <- st_read(dsn = impact_isochrones_path,
                            layer = "differenced_isochrones") %>%
                    st_crop(st_bbox(impact_area))
      
      # 3 Calculation of access loss -------------------------
      
      
      
      ## 3.1 Calculate the extent of loss areas----------------------                                      
                                            
      ## 3.1.1 Initialization of the output sf----------------------
      loss <- st_intersection(noimpact_iso[1,],impact_iso[1,])
      loss$value[1] <- noimpact_iso$value[1]-impact_iso$value[1]
                                            
      ## 3.1.2 calculate the difference of access between normal and floofed situation----------------------
      for (i in 1:length(impact_iso$geom)){
        for (j in 1:length(noimpact_iso$geom)){
          if (noimpact_iso$value[j] < impact_iso$value[i]){
              temp_loss<- st_intersection(noimpact_iso[j,],impact_iso[i,])
            if ( is.na(temp_loss$value[1]) | temp_loss$value[1] == 0){
            } else {
               temp_loss$value[1] <- impact_iso$value[i]-noimpact_iso$value[j]
               loss <- rbind(loss,temp_loss)
            }
          }
        }
      }
                                            
      ## 3.1.3 cleaning and post-processing of the output file -------------------
                                            
      ### get rid of the "value.1" attribute and ensure right geometry
      loss <- subset(loss[,1-3], value != 0) %>%
                st_collection_extract("POLYGON") %>%
                st_cast("POLYGON")
      
      ### if the difference is higher than 18000 (positive or negative) we set to 999999
      for (i in 1:length(loss$geom)){
        if (loss$value[i] > 0){
          if (loss$value[i] > 18000){
            loss$value[i] = 999999
          }
        }
      }
      
      
      ## 3.2 Filter out the polygon due to geometry approximation -------------------
      
      # get the pole of inaccessibility of the polygon
      poi_list <- poi(loss, precision = 0.01)
      
      # convert the poles to df and then sf
      poi_df <- data.frame(matrix(unlist(poi_list), nrow=length(poi_list), byrow=TRUE))
      poi_sf <- st_as_sf(poi_df, coords = c("X1","X2"), crs = 4326) %>% subset( X3 > 0)
      
      # add the radius of the pole of inaccessibility to the access_loss polygons
      loss_poi <- st_join(loss,poi_sf, join = st_contains)
      # filter out if the radius (in decimal degree) is lower of a threshold
      loss_filter <- subset(loss_poi, X3 > poi_threshold) %>%
                            group_by(value) %>%
                            summarize()
      
      # 4 Generate population estimation -------------------
      
                                            
      ## 4.1 Read the input files -----------------------
      population <- raster(population_path)
      
      ## 3.2 Calculate the total population ------------------------
      total_pop <- cellStats(population, 'sum')
      loss_filter$country_pop <- total_pop                                      
                                                                                  
      ## 4.2 Loop through all the isochrones to calculate the sum of population -----------------
      for (i in 1:length(loss_filter$value)){
        loss_filter$pop_sum[i] <- exact_extract(population, loss_filter$geom[i],'sum')
        loss_filter$percent[i] <- loss_filter$pop_sum[i]*100/total_pop
      }
                                            
      ## 4.3 write to result to a new gpkg -------------------------------
      st_write(loss_filter, dsn = loss_path, layer= "access_loss", append = F) 

}


 
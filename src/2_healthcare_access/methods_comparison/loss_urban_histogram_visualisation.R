
# 0.1 Libraries --------------------------------- 
  library(tidyverse)
  library(sf)
  sf_use_s2(FALSE) # last version of sf uses s2 instead of GEOS for ellipsoidal coordinates but it presents some bugs so we disactivate it:https://github.com/r-spatial/sf/issues/1649
  library(raster)
  library(tictoc)
  library(ggplot2)
  library(ggpubr)
  
                              # ---
                              # start timestamp forthe full script
                              tic("Total")
                              Sys.sleep(1)
                              # ---
                              
  # 0.2 - User defined parameters ---------------
  scope <- "all"  # choose between "primary", "non_primary" or "all"
  # bbox corresponding to the urban area between Dondo and Beira                          
  bbox <- st_bbox(c(xmin = 34.6608, ymin = -19.8600, xmax = 34.9343, ymax = -19.5731), crs = st_crs(4326))
  
  # 1 - Parameters----------------
                          # ---
                          ## start timestamp for the section
                          tic("step 1 - Parameters")
                          Sys.sleep(2)
                          # ---
    ## 1.1 Set the path of the input and output files -------------------         
    ### vector input
    iso_loss <- st_read(dsn=paste0("data/results/foot-walking/isochrones/10min_",scope,"_access_loss.gpkg"), layer = "access_loss") %>%
                            st_crop(bbox) %>%
                            subset(select = c("value","geom"))
 ### raster accessibility input
    raster_loss <-raster(paste0("data/results/foot-walking/raster/cat_",scope,"_raster_access_loss.tif")) %>%
                            crop(bbox)
    names(raster_loss) <- "value"
    
    ### other inputs
    population <- raster("data/download/population/population_2020_const_MOZ.tif") %>%
                            crop(bbox)
    names(population) <- "population"
    country_pop <- cellStats(population, sum)
    
    ## output
    urban_loss_hist_path <-"docs/manuscript/urban_loss_hist.png"

    
    ## 1.2 Symbology parameters ----------------------
    
    # Set the labels according to the profile
    labels_loss <- c(paste0(seq(1, 5, 1)-1,"-",seq(1, 5, 1)), ">5")
    unit <- "h"
    
              # ---
              ## stop timestamp for the section
              toc(log = TRUE, quiet = TRUE)
              # ---
    
    # 2 - Data Preprocessing ----------------
    
              # ---
              ## start timestamp for the section
              tic("step 2 - Preprocessing")
              Sys.sleep(2)
              # ---    
    

    
    ## 2.1  Vector data-----------------------
            
    ### 2.1.1  Calculate the total population ------------------------
    iso_loss$country_pop <- country_pop                                     
              
    for (i in 1:length(iso_loss$value)){
      iso_loss$pop_sum[i] <- exact_extract(population, iso_loss$geom[i],'sum')
      iso_loss$percent[i] <- iso_loss$pop_sum[i]*100/country_pop
    }
    ### 2.1.2  Transform to data frame -----------------------
    iso_hist <- iso_loss   
    st_geometry(iso_hist) <- NULL
    
    ### 2.1.3 Adjust the attributes to the approprite format----------------------- 
    # Convert the population data to thousands
    iso_hist$pop_th_sum <- iso_hist$pop_sum/1000
    iso_hist$method <- "vector"
    
    # convert the time range from seconds to appropriate unit (h or min)
    iso_hist$value <- as.character(ceiling(iso_hist$value/3600),0)
    iso_hist  <- iso_hist  %>%
      group_by(value, method) %>%
      summarise(pop_sum = sum(pop_sum), pop_th_sum = sum(pop_th_sum), country_pop=max(country_pop))
    iso_hist$percent <- iso_hist$pop_sum/iso_hist$country_pop*100
    
    for (i in 1:length(iso_hist$value)){
      if (iso_hist$value[i] == "278" ){
        iso_hist$value[i] <- ">5"
      } else {
        iso_hist$value[i] <- paste0(as.numeric(iso_hist$value[i])-1,"-",iso_hist$value[i])
      }
    }
    
    ## 2.2  Raster data-----------------------
      
### 2.2.1 Raster classification----------------------
# Accesibility classification parameters 

  reclass_m <- c(0, 60, 1,
                 60, 120, 2,
                 120, 180, 3,
                 180, 240, 4,
                 240, 300, 5,
                 300, 360, 6,
                 360, Inf, 9999) %>%
    matrix(ncol = 3, byrow = TRUE)

raster_reclass <- reclassify(raster_loss, reclass_m, right=FALSE)

### 2.2.2 resample the population raster -----

# the factor of resolution between the 2 raster is 10 so we aggregate the population value
pop_resamp <- aggregate(population, fact=10, fun=sum) %>%
  resample(raster_reclass, method = "ngb")

### 2.2.3 convert the raster accessibilty to df with population data-----------------

# normal access : create multi layer raster and convert to dataframe
loss_pop_df <- brick(raster_reclass, pop_resamp) %>%
  as.data.frame(xy=TRUE) %>%
  subset(!is.na(population)) # filter out the rows without population data

# aggregate by time range 
raster_hist <- aggregate(population ~ value,
                                              loss_pop_df,
                                              sum)

### 2.2.4  convert the time range from seconds to appropriate unit (h or min) -----------------------
  raster_hist$value <- as.character(raster_hist$value)
  for (i in 1:length(raster_hist$value)){
    if (raster_hist$value[i] == "9999" ){
      raster_hist$value[i] <- ">5"
    } else {
      raster_hist$value[i] <- paste0(as.numeric(raster_hist$value[i])-1,"-",raster_hist$value[i])
    }
  }


colnames(raster_hist) <- c("value", "pop_sum" )

### 2.2.5 Adjust the attributes to the appropriate format-----------------------

# Convert the population data to thousands
raster_hist$pop_th_sum <- raster_hist$pop_sum/1000
raster_hist$percent <- raster_hist$pop_sum*100/country_pop
raster_hist$country_pop <- country_pop
raster_hist$method <- "raster"

## 2.3 Group both dataset-----------------------
loss_hist <- rbind(raster_hist,iso_hist)

# Set a level to plot in appropriate order
loss_level<- factor(loss_hist$value, level = labels_loss)

# 3 Plot the histogram to PNG -----------------------  

ggplot(loss_hist, aes(fill=method, y=pop_th_sum, x=loss_level)) + 
  scale_y_continuous(
    name = "Population (in thousands)",
    sec.axis = sec_axis( trans=~./(country_pop/1000)*100, name="Percentage of the country population (%)")
  ) +
  geom_bar(position="dodge", stat="identity")+
  geom_text(aes(label = round(pop_th_sum,2)),
            size=2,
            position=position_dodge(width=0.9),
            vjust=1.5) +
  geom_text(aes(label = paste0(round(percent,2),"%")),
            size=1.5,
            position=position_dodge(width=0.9),
            vjust=3.5) +
  theme(plot.title = element_text(hjust = 0.5, vjust = 0.5)) +
  xlab(paste0("Walking time increase (",unit,")")) +
  ylab("population (in thousands)")


# save to png
ggsave(urban_loss_hist_path, height = 10, width = 15, units = "cm", dpi = 300)




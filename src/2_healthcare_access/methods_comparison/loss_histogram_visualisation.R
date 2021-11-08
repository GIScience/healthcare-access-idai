
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
  
  
  
  # 1 - Parameters----------------
                          # ---
                          ## start timestamp for the section
                          tic("step 1 - Parameters")
                          Sys.sleep(2)
                          # ---
    ## 1.1 Set the path of the input and output files -------------------         
    ### vector input
    foot_iso_loss <- st_read(dsn=paste0("data/results/foot-walking/isochrones/10min_",scope,"_access_loss.gpkg"), layer = "access_loss")
    car_iso_loss <- st_read(dsn=paste0("data/results/driving-car/isochrones/10min_",scope,"_access_loss.gpkg"), layer = "access_loss")
    ### raster accessibility input
    foot_raster_loss <-raster(paste0("data/results/foot-walking/raster/cat_",scope,"_raster_access_loss.tif"))
    names(foot_raster_loss) <- "value"
    car_raster_loss <-raster(paste0("data/results/driving-car/raster/cat_",scope,"_raster_access_loss.tif"))
    names(car_raster_loss) <- "value"
    
    ### other inputs
    population <- raster("data/download/population/population_2020_const_MOZ.tif")
    names(population) <- "population"
    country_pop <- cellStats(population, sum)
    
    ## output
    loss_hist_path <-"docs/manuscript/access/loss_hist.png"

    
    ## 1.2 Symbology parameters ----------------------
    
    # Set the labels according to the profile
    car_labels_loss <- c(paste0(seq(10, 50, 10)-10,"-",seq(10, 50, 10)), ">50")
    car_unit <- "min"
    foot_labels_loss <- c(paste0(seq(1, 5, 1)-1,"-",seq(1, 5, 1)), ">5")
    foot_unit <- "h"
    
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
    

    
    ## 2.1  Foot-walking-----------------------
                                            
    ### 2.1.1 Vector data --------------
              
    #### 2.1.1.1  Transform to data frame -----------------------
    foot_iso_hist <- foot_iso_loss   
    st_geometry(foot_iso_hist) <- NULL
    
    #### 2.1.1.3 Adjust the attributes to the approprite format----------------------- 
    # Convert the population data to thousands
    foot_iso_hist$pop_th_sum <- foot_iso_hist$pop_sum/1000
    foot_iso_hist$method <- "Network-based"
    
    # convert the time range from seconds to appropriate unit (h or min)
    foot_iso_hist$value <- as.character(ceiling(foot_iso_hist$value/3600),0)
    foot_iso_hist  <- foot_iso_hist  %>%
      group_by(value, method) %>%
      summarise(pop_sum = sum(pop_sum), pop_th_sum = sum(pop_th_sum), country_pop=max(country_pop))
    foot_iso_hist$percent <- foot_iso_hist$pop_sum/foot_iso_hist$country_pop*100
    
    for (i in 1:length(foot_iso_hist$value)){
      if (foot_iso_hist$value[i] == "278" ){
        foot_iso_hist$value[i] <- ">5"
      } else {
        foot_iso_hist$value[i] <- paste0(as.numeric(foot_iso_hist$value[i])-1,"-",foot_iso_hist$value[i])
      }
    }
    
    
    ### 2.1.2 Raster data --------------
    
    #### 2.1.2.1 Raster classification----------------------
    # Accesibility classification parameters 
    
    foot_reclass_m <- c(0, 60, 1,
                        60, 120, 2,
                        120, 180, 3,
                        180, 240, 4,
                        240, 300, 5,
                        300, 360, 6,
                        360, Inf, 9999) %>%
      matrix(ncol = 3, byrow = TRUE)
    
    foot_raster_reclass <- reclassify(foot_raster_loss, foot_reclass_m, right=FALSE)
    
    #### 2.1.2.2 resample the population raster -----
    
    # the factor of resolution between the 2 raster is 10 so we aggregate the population value
    foot_pop_resamp <- aggregate(population, fact=10, fun=sum) %>%
      resample(foot_raster_reclass, method = "ngb")
    
    #### 2.1.2.3 convert the raster accessibilty to df with population data-----------------
    
    # normal access : create multi layer raster and convert to dataframe
    foot_loss_pop_df <- brick(foot_raster_reclass, foot_pop_resamp) %>%
      as.data.frame(xy=TRUE) %>%
      subset(!is.na(population)) # filter out the rows without population data
    
    # aggregate by time range 
    foot_raster_hist <- aggregate(population ~ value,
                                  foot_loss_pop_df,
                                  sum)
    
    #### 2.1.2.4  convert the time range from seconds to appropriate unit (h or min) -----------------------
    foot_raster_hist$value <- as.character(foot_raster_hist$value)
    for (i in 1:length(foot_raster_hist$value)){
      if (foot_raster_hist$value[i] == "9999" ){
        foot_raster_hist$value[i] <- ">5"
      } else {
        foot_raster_hist$value[i] <- paste0(as.numeric(foot_raster_hist$value[i])-1,"-",foot_raster_hist$value[i])
      }
    }
    
    
    colnames(foot_raster_hist) <- c("value", "pop_sum" )
    
    #### 2.1.2.5 Adjust the attributes to the appropriate format-----------------------
    
    # Convert the population data to thousands
    foot_raster_hist$pop_th_sum <- foot_raster_hist$pop_sum/1000
    foot_raster_hist$percent <- foot_raster_hist$pop_sum*100/country_pop
    foot_raster_hist$country_pop <- country_pop
    foot_raster_hist$method <- "Raster-based"
    
    
    
    
    ## 2.2  Driving-car-----------------------
    
    ### 2.2.1 Vector data --------------
    
    #### 2.1.2.1  Transform to data frame -----------------------
    car_iso_hist <- car_iso_loss   
    st_geometry(car_iso_hist) <- NULL
    
    #### 2.1.1.3 Adjust the attributes to the approprite format----------------------- 
    # Convert the population data to thousands
    car_iso_hist$pop_th_sum <- car_iso_hist$pop_sum/1000
    car_iso_hist$method <- "Network-based"
    
    # convert the time range from seconds to appropriate unit (h or min)
    car_iso_hist$value <- as.character(car_iso_hist$value/60)
    for (i in 1:length(car_iso_hist$value)){
      if (car_iso_hist$value[i] == "16666.65" ){
        car_iso_hist$value[i] <- ">50"
      } else {
        car_iso_hist$value[i] <- paste0(as.numeric(car_iso_hist$value[i])-10,"-",car_iso_hist$value[i])
      }
    }
      
  ### 2.2.2 Raster data --------------
  
  # Accesibility classification parameters 
  
  car_reclass_m <- c(0, 10, 10,
                      11, 20, 20,
                      21, 30, 30,
                      31, 40, 40,
                      41, 50, 50,
                      51, 60, 60,
                      61, Inf, 9999) %>%
    matrix(ncol = 3, byrow = TRUE)
  
  #### 2.2.2.1 Raster classification----------------------
  car_raster_reclass <- reclassify(car_raster_loss, car_reclass_m, right=FALSE)
  
  #### 2.2.2.2 resample the population raster -----
  
  # the factor of resolution between the 2 raster is 10 so we aggregate the population value
  car_pop_resamp <- aggregate(population, fact=10, fun=sum) %>%
    resample(car_raster_reclass, method = "ngb")
  
  #### 2.2.2.2 convert the raster accessibilty to df with population data-----------------
  
  # normal access : create multi layer raster and convert to dataframe
  car_loss_pop_df <- brick(car_raster_reclass, car_pop_resamp) %>%
    as.data.frame(xy=TRUE) %>%
    subset(!is.na(population )) # filter out the rows without population data
  
  # aggregate by time range 
  car_raster_hist <- aggregate(population ~ value,
                               car_loss_pop_df,
                               sum)
  
  #### 2.2.3.4  convert the time range from seconds to appropriate unit (h or min) -----------------------
    car_raster_hist$value <- as.character(car_raster_hist$value)
    for (i in 1:length(car_raster_hist$value)){
      if (car_raster_hist$value[i] >= "9999" ){
        car_raster_hist$value[i] <- ">50"
      } else {
        car_raster_hist$value[i] <- paste0(as.numeric(car_raster_hist$value[i])-10,"-",car_raster_hist$value[i])
      }
    }
  
  colnames(car_raster_hist) <- c("value", "pop_sum" )
  
  #### 2.2.2.5 Adjust the attributes to the appropriate format-----------------------
  
  # Convert the population data to thousands
  car_raster_hist$pop_th_sum <- car_raster_hist$pop_sum/1000
  car_raster_hist$percent <- car_raster_hist$pop_sum*100/country_pop
  car_raster_hist$country_pop <- country_pop
  car_raster_hist$method <- "Raster-based"
  
  
  ## 2.3 Group both dataset-----------------------
  foot_loss_hist <- rbind(foot_raster_hist,foot_iso_hist)
  car_loss_hist <- rbind(car_raster_hist,car_iso_hist)
  
  # Set a level to plot in appropriate order
  foot_loss_level<- factor(foot_loss_hist$value, level = foot_labels_loss)
  car_loss_level<- factor(car_loss_hist$value, level = car_labels_loss)

# 3 Plot the histogram to PNG -----------------------  


car_png <- ggplot(car_loss_hist, aes(fill= method, y=pop_th_sum, x=car_loss_level)) +
  scale_y_continuous(
    name = "Population (in thousands)",
    sec.axis = sec_axis( trans=~./(country_pop/1000)*100, name="Percentage of the country population (%)")
  ) +
  geom_bar(position="dodge", stat="identity")+
  ylim(0,750)+
  labs(title = "A. Driving profile", fill = "Method") + 
  scale_fill_manual(values=c('#999999','#E69F00')) + 
  theme(plot.title = element_text(hjust = 0.5, vjust = 0.5),
        legend.position = c(.45, .95),
        legend.justification = c("right", "top"),
        legend.box.just = "right",
        legend.margin = margin(6, 6, 6, 6)) +
  xlab(paste0("Driving time increase (",car_unit,")")) +
  ylab("population (in thousands)")
  
  
  
foot_png <- ggplot(foot_loss_hist, aes( fill= method, y=pop_th_sum, x=foot_loss_level)) + 
    scale_y_continuous(name = "Population (in thousands)",
                       sec.axis = sec_axis( trans=~./(country_pop/1000)*100, name="Percentage of the country population (%)")
    ) +
    geom_bar(position="dodge", stat="identity")+
    labs(title = "B. Walking profile") +  
    scale_fill_manual(values=c('#999999','#E69F00')) + 
    theme(plot.title = element_text(hjust = 0.5, vjust = 0.5),
          legend.position="none") +
    xlab(paste0("Walking time increase (",foot_unit,")")) +
    ylab("population (in thousands)")


ggarrange( car_png, foot_png,
          #common.legend=TRUE,
          #vjust=-0.8,
          ncol=2, nrow=1)

# save to png
ggsave(loss_hist_path, height = 10, width = 20, units = "cm", dpi = 300)




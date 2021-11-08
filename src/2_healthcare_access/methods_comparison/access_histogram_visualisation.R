
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
    foot_noimpact_iso <- st_read(dsn=paste0("data/results/foot-walking/isochrones/10min_",scope,"_normal_isochrones.gpkg"), layer = "isochrones_populated")
    foot_impact_iso <- st_read(dsn=paste0("data/results/foot-walking/isochrones/10min_",scope,"_impact_isochrones.gpkg"), layer = "isochrones_populated")
    car_noimpact_iso <- st_read(dsn=paste0("data/results/driving-car/isochrones/10min_",scope,"_normal_isochrones.gpkg"), layer = "isochrones_populated")
    car_impact_iso <- st_read(dsn=paste0("data/results/driving-car/isochrones/10min_",scope,"_impact_isochrones.gpkg"), layer = "isochrones_populated")
    ### raster accessibility input
    foot_normal_raster <-raster(paste0("data/results/foot-walking/raster/cat_",scope,"_normal_raster_access.tif"))
    names(foot_normal_raster) <- "value"
    foot_impact_raster <- raster(paste0("data/results/foot-walking/raster/cat_",scope,"_impact_raster_access.tif"))
    names(foot_impact_raster) <- "value"
    car_normal_raster <-raster(paste0("data/results/driving-car/raster/cat_",scope,"_normal_raster_access.tif"))
    names(car_normal_raster) <- "value"
    car_impact_raster <- raster(paste0("data/results/driving-car/raster/cat_",scope,"_impact_raster_access.tif"))
    names(car_impact_raster) <- "value"
    
    ### other inputs
    population <- raster("data/download/population/population_2020_const_MOZ.tif")
    names(population) <- "population"
    country_pop <- cellStats(population, sum)
    
    ## output
    access_hist_path <-"docs/manuscript/access/access_hist.png"

    
    ## 1.2 Symbology parameters ----------------------
    
    # Set the labels according to the profile
    car_labels_access <- c(paste0(seq(10, 60, 10)-10,"-",seq(10, 60, 10)), ">60")
    car_unit <- "min"
    foot_labels_access <- c(paste0(seq(1, 6, 1)-1,"-",seq(1, 6, 1)), ">6")
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
    

    
    ## 2.1  Vector data-----------------------
                                            
    ### 2.1.1 Foot-walking --------------
              
    #### 2.1.1.1  Transform to data frame -----------------------
    st_geometry(foot_noimpact_iso) <- NULL
    foot_noimpact_iso$Situation <- "Normal" # add a tag of the instance of the isochrones
    st_geometry(foot_impact_iso) <- NULL
    foot_impact_iso$Situation <- "Flooded" # add a tag of the instance of the isochrones
    
    
    #### 2.1.1.2  group to the same data.frame both datasets -----------------------
    foot_iso_hist <- rbind(foot_impact_iso, foot_noimpact_iso)
    foot_iso_hist$method <- "Network-based"
    
    #### 2.1.1.3 Adjust the attributes to the approprite format----------------------- 
    # Convert the population data to thousands
    foot_iso_hist$pop_mi_sum <- foot_iso_hist$pop_sum/1000000
    
    # convert the time range from seconds to appropriate unit (h or min)
    foot_iso_hist$value <- as.character(ceiling(foot_iso_hist$value/3600),0)
    foot_iso_hist <- foot_iso_hist %>%
          group_by(value, Situation, method) %>%
          summarise(pop_sum = sum(pop_sum), pop_mi_sum = sum(pop_mi_sum), country_pop=max(country_pop))
    foot_iso_hist$percent <- foot_iso_hist$pop_sum /foot_iso_hist$country_pop*100
        
        for (i in 1:length(foot_iso_hist$value)){
          if (foot_iso_hist$value[i] == "28" ){
            foot_iso_hist$value[i] <- ">6"
          } else {
            foot_iso_hist$value[i] <- paste0(as.numeric(foot_iso_hist$value[i])-1,"-",foot_iso_hist$value[i])
          }
        }
    
    ### 2.1.2 Driving-car --------------
    
    #### 2.1.2.1  Transform to data frame -----------------------
    st_geometry(car_noimpact_iso) <- NULL
    car_noimpact_iso$Situation <- "Normal" # add a tag of the instance of the isochrones
    st_geometry(car_impact_iso) <- NULL
    car_impact_iso$Situation <- "Flooded" # add a tag of the instance of the isochrones
    
    
    #### 2.1.2.2  group to the same data.frame both datasets -----------------------
    car_iso_hist <- rbind(car_impact_iso, car_noimpact_iso)
    car_iso_hist$method <- "Network-based"
    
    #### 2.1.2.3 Adjust the attributes to the approprite format----------------------- 
    # Convert the population data to thousands
    car_iso_hist$pop_mi_sum <- car_iso_hist$pop_sum/1000000
    
    # convert the time range from seconds to appropriate unit (h or min)
      car_iso_hist$value <- as.character(car_iso_hist$value/60)
      for (i in 1:length(car_iso_hist$value)){
        if (car_iso_hist$value[i] == "1666.65" ){
          car_iso_hist$value[i] <- ">60"
        } else {
          car_iso_hist$value[i] <- paste0(as.numeric(car_iso_hist$value[i])-10,"-",car_iso_hist$value[i])
        }
      }
    

    ## 2.2  Raster data-----------------------
      
    ### 2.2.1 Foot-walking --------------
      
#### 2.2.1.1 Raster classification----------------------
# Accesibility classification parameters 

  foot_reclass_m <- c(0, 60, 1,
                 60, 120, 2,
                 120, 180, 3,
                 180, 240, 4,
                 240, 300, 5,
                 300, 360, 6,
                 360, Inf, 9999) %>%
    matrix(ncol = 3, byrow = TRUE)

#### 2.2.1.2 reclassify the normal and impact rasters -----
foot_normal_raster_reclass <- reclassify(foot_normal_raster, foot_reclass_m, right=FALSE)
foot_impact_raster_reclass <- reclassify(foot_impact_raster, foot_reclass_m, right=FALSE)

#### 2.2.1.3 resample the population raster -----

# the factor of resolution between the 2 raster is 10 so we aggregate the population value
foot_pop_resamp <- aggregate(population, fact=10, fun=sum) %>%
  resample(foot_normal_raster_reclass, method = "ngb")

#### 2.2.1.4 convert the raster accessibilty to df with population data-----------------

# normal access : create multi layer raster and convert to dataframe
foot_normal_access_pop_df <- brick(foot_normal_raster_reclass, foot_pop_resamp) %>%
  as.data.frame(xy=TRUE) %>%
  subset(!is.na(population)) # filter out the rows without population data

# aggregate by time range 
foot_normal_access_pop_df_aggreg <- aggregate(population ~ value,
                                              foot_normal_access_pop_df,
                                              sum)

foot_normal_access_pop_df_aggreg$Situation <- "Normal" # add a tag of the instance of the accesibility raster

# impact access : create multi layer raster and convert to dataframe
foot_impact_access_pop_df <- brick(foot_impact_raster_reclass, foot_pop_resamp) %>%
  as.data.frame() %>%
  subset(!is.na(population)) # filter out the rows without population data

# aggregate by time range 
foot_impact_access_pop_df_aggreg <- aggregate(population ~ value,
                                              foot_impact_access_pop_df,
                                              sum)

foot_impact_access_pop_df_aggreg$Situation <- "Flooded"

#### 2.2.1.5  group to the sme data.frame both datasets -----------------------
foot_raster_hist <- rbind(foot_impact_access_pop_df_aggreg, foot_normal_access_pop_df_aggreg)

#### 2.2.1.6  convert the time range from seconds to appropriate unit (h or min) -----------------------
  foot_raster_hist$value <- as.character(foot_raster_hist$value)
  for (i in 1:length(foot_raster_hist$value)){
    if (foot_raster_hist$value[i] == "9999" ){
      foot_raster_hist$value[i] <- ">6"
    } else {
      foot_raster_hist$value[i] <- paste0(as.numeric(foot_raster_hist$value[i])-1,"-",foot_raster_hist$value[i])
    }
  }


colnames(foot_raster_hist) <- c("value", "pop_sum","Situation" )

#### 2.2.1.7 Adjust the attributes to the appropriate format-----------------------

# Convert the population data to thousands
foot_raster_hist$pop_mi_sum <- foot_raster_hist$pop_sum/1000000
foot_raster_hist$percent <- foot_raster_hist$pop_sum*100/country_pop
foot_raster_hist$country_pop <- country_pop
foot_raster_hist$method <- "Raster-based"

### 2.2.2 Driving-car --------------

#### 2.2.2.1 resample the population raster -----

# the factor of resolution between the 2 raster is 10 so we aggregate the population value
car_pop_resamp <- aggregate(population, fact=10, fun=sum) %>%
  resample(car_normal_raster, method = "ngb")

#### 2.2.2.2 convert the raster accessibilty to df with population data-----------------

# normal access : create multi layer raster and convert to dataframe
car_normal_access_pop_df <- brick(car_normal_raster, car_pop_resamp) %>%
  as.data.frame(xy=TRUE) %>%
  subset(!is.na(population)) # filter out the rows without population data

# aggregate by time range 
car_normal_access_pop_df_aggreg <- aggregate(population ~ value,
                                             car_normal_access_pop_df,
                                              sum)

car_normal_access_pop_df_aggreg$Situation <- "Normal" # add a tag of the instance of the accesibility raster

# impact access : create multi layer raster and convert to dataframe
car_impact_access_pop_df <- brick(car_impact_raster, car_pop_resamp) %>%
  as.data.frame() %>%
  subset(!is.na(population)) # filter out the rows without population data

# aggregate by time range 
car_impact_access_pop_df_aggreg <- aggregate(population ~ value,
                                             car_impact_access_pop_df,
                                              sum)

car_impact_access_pop_df_aggreg$Situation <- "Flooded"

#### 2.2.2.3  group to the sme data.frame both datasets -----------------------
car_raster_hist <- rbind(car_impact_access_pop_df_aggreg, car_normal_access_pop_df_aggreg)

#### 2.2.3,4  convert the time range from seconds to appropriate unit (h or min) -----------------------
  car_raster_hist$value <- as.character(car_raster_hist$value)
  for (i in 1:length(car_raster_hist$value)){
    if (car_raster_hist$value[i] == "9999999" ){
      car_raster_hist$value[i] <- ">60"
    } else {
      car_raster_hist$value[i] <- paste0(as.numeric(car_raster_hist$value[i])-10,"-",car_raster_hist$value[i])
    }
  }

colnames(car_raster_hist) <- c("value", "pop_sum","Situation" )

#### 2.2.2.5 Adjust the attributes to the appropriate format-----------------------

# Convert the population data to thousands
car_raster_hist$pop_mi_sum <- car_raster_hist$pop_sum/1000000
car_raster_hist$percent <- car_raster_hist$pop_sum*100/country_pop
car_raster_hist$country_pop <- country_pop
car_raster_hist$method <- "Raster-based"


## 2.3 Group both dataset-----------------------
foot_access_hist <- rbind(foot_raster_hist,foot_iso_hist)
car_access_hist <- rbind(car_raster_hist,car_iso_hist)

# Set a level to plot in appropriate order
foot_access_level<- factor(foot_access_hist$value, level = foot_labels_access)
car_access_level<- factor(car_access_hist$value, level = car_labels_access)

# 3 Plot the histogram to PNG -----------------------  

foot_png <- ggplot(foot_access_hist, aes(fill=factor(Situation,c("Normal","Flooded")), y=pop_mi_sum, x=foot_access_level)) + 
  scale_y_continuous(
    name = "Population (in millions)",
    sec.axis = sec_axis( trans=~./(foot_access_hist$country_pop/1000000)*100, name="Percentage of the country population (%)")
  ) +
  geom_bar(position="dodge", stat="identity")+
  labs(fill = "Situation") + 
  facet_grid(cols = vars(method)) +
  theme(plot.title = element_text(hjust = 0.5, vjust = 0.5)) +
  xlab(paste0("Walking time (",foot_unit,")")) +
  ylab("population (in thousands)")

car_png <- ggplot(car_access_hist, aes(fill=factor(Situation,c("Normal","Flooded")), y=pop_mi_sum, x=car_access_level)) + 
  scale_y_continuous(
    name = "Population (in millions)",
    sec.axis = sec_axis( trans=~./(car_access_hist$country_pop/1000000)*100, name="Percentage of the country population (%)")
  ) +
  geom_bar(position="dodge", stat="identity")+
  labs(fill = "Situation") + 
  facet_grid(cols = vars(method)) +
  theme(plot.title = element_text(hjust = 0.5, vjust = 0.5)) +
  xlab(paste0("Driving time (",car_unit,")")) +
  ylab("population (in thousands)")

ggarrange(foot_png, car_png,
         labels= c("A","B"),
         ncol=1, nrow=2)

# save to png
ggsave(access_hist_path, height = 20, width = 20, units = "cm", dpi = 300)




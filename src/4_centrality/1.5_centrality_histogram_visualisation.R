
# 0.1 Libraries --------------------------------- 
  library(tidyverse)
  library(sf)
  sf_use_s2(FALSE) # last version of sf uses s2 instead of GEOS for ellipsoidal coordinates but it presents some bugs so we disactivate it:https://github.com/r-spatial/sf/issues/1649
  library(raster)
  library(tictoc)
  library(ggplot2)
  library(ggpubr)
  library(sfnetworks)
  library(classInt)
  library(plyr)
  
                              
  # 0.2 - User defined parameters ---------------
  scope <- "all"  # choose between "primary", "non_primary" or "all"
  focus_area <- "Mozambique" # choose between "Dondo", "Makambine","Mocuba", "Tica" and "Quelimane"
  tc_cluster <- 20
  directionality <- "bi" # choose between "bi" and "uni"
  indicator <- "tc" # choose between "tc" and "pc"
  
  
  
  # 1 - Parameters----------------
 
    ### driving centrality
    # normal_centrality <- st_read(dsn=paste0("data/results/foot-walking/centrality/",focus_area,"/",tc_cluster,"km_",scope,"_centrality.gpkg"),
    #                                   layer = paste0(directionality,"direct_normal_", indicator))
    normal_centrality <- st_read(dsn=paste0("data/results/driving-car/centrality/",focus_area,"/",tc_cluster,"km_",scope,"_centrality.gpkg"),
                               layer = paste0(directionality,"direct_normal_", indicator))
    normal_centrality$length <- st_length(normal_centrality) 
    normal_centrality$Situation <- " Normal"
    normal_centrality$log_tc <- log10(normal_centrality$tc)
    
    # flooded_centrality <- st_read(dsn=paste0("data/results/foot-walking/centrality/",focus_area,"/",tc_cluster,"km_",scope,"_centrality.gpkg"),
    #                                   layer = paste0(directionality,"direct_impact_", indicator))
    flooded_centrality <- st_read(dsn=paste0("data/results/driving-car/centrality/",focus_area,"/",tc_cluster,"km_",scope,"_centrality.gpkg"),
                                  layer = paste0(directionality,"direct_impact_", indicator))
    flooded_centrality$length <- st_length(flooded_centrality) 
    flooded_centrality$Situation <- "Flooded" # add a tag of the instance of the isochrones
    flooded_centrality$log_tc <- log10(flooded_centrality$tc) 
    
    centrality <- rbind(flooded_centrality, normal_centrality)

    

    
    ## other input
    # impact_area <- st_read(dsn = "data/download/impact_area/impact_area.gpkg", layer = "simpl_impact_area")
    # impact_bbox <- st_bbox(impact_area)
    impact_bbox <- st_bbox(c(xmin = 33.532, ymin = -20.161, xmax = 34.914, ymax = -18.645), crs = st_crs(4326))
    
    dondo_bbox <- st_bbox(c(xmin = 34.58545, ymin = -19.69468, xmax = 34.89867, ymax = -19.41471), crs = st_crs(4326))
    
    makambine_bbox <- st_bbox(c(xmin = 33.8940, ymin = -19.909, xmax = 34.1978, ymax = -19.576), crs = st_crs(4326))
    
    ## output
    # flood_hist_path <-"docs/manuscript/centrality/flooded_centrality_hist.png"
    flood_hist_path <-"docs/manuscript/centrality/car_flooded_centrality_hist.png"
    # dondo_hist_path <-"docs/manuscript/centrality/dondo_centrality_hist.png"
    dondo_hist_path <-"docs/manuscript/centrality/car_dondo_centrality_hist.png"
    moz_hist_path <-"docs/manuscript/centrality/moz_centrality_hist.png"
    makambine_hist_path <-"docs/manuscript/centrality/makambine_centrality_hist.png"

    
    # 2 - Data Preprocessing ----------------


# 3 Plot the histogram to PNG -----------------------  
    ## 3.1  country hist -----------------------
mu <- ddply(centrality, "Situation", summarise, grp.mean=mean(log_tc))
              
ggplot(centrality, aes(x=log_tc, fill= Situation, color = Situation)) + 
  geom_histogram(aes(weight=length/1000),  position="identity", alpha = 0.5) +
  geom_vline(data=mu, aes(xintercept=grp.mean, color=Situation),
             linetype="dashed")+
  theme(plot.title = element_text(hjust = 0.5, vjust = 0.5)) +
  xlab(paste0("Targeted centrality (log10)")) +
  ylab("Road length (km)")

# save to png
ggsave(moz_hist_path, height = 20, width = 20, units = "cm", dpi = 300)

## 3.2  Flooded hist -----------------------
flood_centrality <- centrality %>% st_crop(impact_bbox)

mu <- ddply(flood_centrality, "Situation", summarise, grp.mean=mean(log_tc))

ggplot(flood_centrality, aes(x=log_tc, fill= Situation, color = Situation)) + 
  geom_histogram(aes(weight=length/1000),  position="identity", alpha = 0.5) +
  geom_vline(data=mu, aes(xintercept=grp.mean, color=Situation),
             linetype="dashed")+
  theme(plot.title = element_text(hjust = 0.5, vjust = 0.5)) +
  xlab(paste0("Targeted centrality (log10)")) +
  ylab("Road length (km)")


# save to png
ggsave(flood_hist_path, height = 5, width = 10, units = "cm", dpi = 700)

## 3.3  Dondo hist -----------------------
dondo_centrality <- centrality %>% st_crop(dondo_bbox)

mu <- ddply(dondo_centrality, "Situation", summarise, grp.mean=mean(log_tc))

ggplot(dondo_centrality, aes(x=log_tc, fill= Situation, color = Situation)) + 
  geom_histogram(aes(weight=length/1000),  position="identity", alpha = 0.5) +
  geom_vline(data=mu, aes(xintercept=grp.mean, color=Situation),
             linetype="dashed")+
  theme(plot.title = element_text(hjust = 0.5, vjust = 0.5)) +
  xlab(paste0("Targeted centrality (log10)")) +
  ylab("Road length (km)")


# save to png
ggsave(dondo_hist_path, height = 5, width = 10, units = "cm", dpi = 700)


## 3.3  Makambine hist -----------------------
makambine_centrality <- centrality %>% st_crop(makambine_bbox)

mu <- ddply(makambine_centrality, "Situation", summarise, grp.mean=mean(log_tc))

ggplot(makambine_centrality, aes(x=log_tc, fill= Situation, color = Situation)) + 
  geom_histogram(aes(weight=length/1000),  position="identity", alpha = 0.5) +
  geom_vline(data=mu, aes(xintercept=grp.mean, color=Situation),
             linetype="dashed")+
  theme(plot.title = element_text(hjust = 0.5, vjust = 0.5)) +
  xlab(paste0("Targeted centrality (log10)")) +
  ylab("Road length (km)")


# save to png
ggsave(makambine_hist_path, height = 5, width = 10, units = "cm", dpi = 700)





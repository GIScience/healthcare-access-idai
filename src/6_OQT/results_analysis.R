#Head ---------------------------------
# purpose: 

# 0.1 Libraries ---------------------------------
library(tidyverse)
library(sf)
sf_use_s2(FALSE) # last version of sf uses s2 instead of GEOS for ellipsoidal coordinates but it presents some bugs so we disactivate it:https://github.com/r-spatial/sf/issues/1649
library(tictoc)
library(jsonlite) # manage JSON format
library(foreach)
library(ggplot2)
library(stars)
library(raster)
library(exactextractr)


# 0.2 - User defined parameters ---------------
country <- "MOZ" # use the ISO code alpha 3 of the country of interest

# 0.3 - Repository creation ---------
dir.create("data")
dir.create("data/results")
dir.create("data/results/OQT")





# 1 - OQT polygon creation----------------


## 1.1 Input definition ---------

## Read input files 
boundary <- st_read(dsn = paste0("data/download/boundary/",country,"_adm0_boundary.gpkg" )) 
impact_area <- st_read(dsn="data/download/impact_area/impact_area.gpkg", layer = "simpl_impact_area")

hex_path <- "data/results/OQT/hex20.geojson"
OQT_path <- "data/results/OQT/results_hex20.gpkg" 
# ghs_smod_moz <- read_stars("data/results/OQT/urban_extent/MOZ_GHS_SMOD_2015.tif") %>%
#   st_warp(crs = st_crs(boundary))
# ghs_smod_moz <- ghs_smod_moz[boundary]
# write_stars(ghs_smod_moz, "data/results/OQT/urban_extent/MOZ_GHS_SMOD_2015_crop.tif")
ghs_smod_moz <- raster("data/results/OQT/urban_extent/MOZ_GHS_SMOD_2015_crop.tif")
reclass <- matrix(c(0,15,0,16,40,1), nrow = 2, byrow = TRUE)
urban_raster <- reclassify(ghs_smod_moz, reclass)

results <- st_read(hex_path) %>% 
  subset(select = c(shapeName,shapeID,ogc_fid))

## flooded ----------
buf_impact_area <- st_buffer(impact_area, 10*0.01) %>% st_union()
#buf_impact_area <- st_union(impact_area)
buf_impact_surf <- results %>%
                      st_intersection(buf_impact_area)
                      
buf_impact_surf$flood_area <- st_area(buf_impact_surf)
buf_impact_surf$geometry <- NULL


results <- left_join(results, buf_impact_surf, by= "ogc_fid") %>%
  subset(select=-c(shapeName.y,shapeID.y))
results$hex_area <- st_area(results)
results$flood_area[is.na(results$flood_area)]<- 0
results$flood_percent <- as.numeric(results$flood_area/results$hex_area)

foreach(i=1:nrow(results)) %do% {
  if(results$flood_percent[i]==0){
    results$flooded[i] <- "no"
  } else {
    results$flooded[i]<- "yes"
  }
}

## urban -------
foreach(i= 1:nrow(results)) %do% {
  results$urban_count[i] <- exact_extract(urban_raster, results$geometry[i],'sum')
}

foreach(i=1:nrow(results)) %do% {
  if(results$urban_count[i] == 0){
    results$urban[i] <- "rural"
  } else {
    results$urban[i]<- "urban"
  }
}

## oqt results
oqt_WpopCompBuild <- st_read(OQT_path, layer = "WpopCompBuild") %>%
  subset(select = c(result.value, data.pop_count_per_sqkm, data.feature_count_per_sqkm, ogc_fid, geom))
oqt_WpopCompBuild$geom <- NULL
colnames(oqt_WpopCompBuild) <- c("WpopCompBuild","pop_density","building_count", "ogc_fid")

results <- left_join(results, oqt_WpopCompBuild, by= "ogc_fid")
results$WpopCompBuild[is.na(results$WpopCompBuild)]<- 0

oqt_WpopCompRoad <- st_read(OQT_path, layer = "WpopCompRoad") %>%
  subset(select = c(result.value, data.feature_length_per_sqkm, ogc_fid, geom))
oqt_WpopCompRoad$geom <- NULL
colnames(oqt_WpopCompRoad) <- c("WpopCompRoad","road_density","ogc_fid")

results <- left_join(results, oqt_WpopCompRoad, by= "ogc_fid")
results$WpopCompRoad[is.na(results$WpopCompRoad)]<- 0

## plot
ggplot(results, aes( flood_percent, WpopCompBuild)) +
  # geom_bin2d(binwidth = 0.2) + 
  # scale_fill_continuous(low="lavenderblush", high="red")
  geom_jitter() 

ggplot(results, aes( pop_density, building_count)) +
  # geom_bin2d(binwidth = 0.2) + 
  # scale_fill_continuous(low="lavenderblush", high="red")
  geom_jitter() 

ggplot(results, aes( flooded , WpopCompBuild)) +
  geom_boxplot() 

ggplot(results, aes( urban, WpopCompBuild)) +
  geom_boxplot()

ggplot(results, aes(urban_count, WpopCompBuild)) +
  geom_point()


ggplot(results, aes( pop_density, road_density)) +
  # geom_bin2d(binwidth = 0.2) + 
  # scale_fill_continuous(low="lavenderblush", high="red")
  geom_jitter() 

ggplot(results, aes( pop_density, road_density)) +
  # geom_bin2d(binwidth = 0.2) + 
  # scale_fill_continuous(low="lavenderblush", high="red")
  geom_jitter() 


#Head ---------------------------------
# purpose: 

# 0.1 Libraries ---------------------------------
library(tidyverse)
library(sf)
sf_use_s2(FALSE) # last version of sf uses s2 instead of GEOS for ellipsoidal coordinates but it presents some bugs so we disactivate it:https://github.com/r-spatial/sf/issues/1649
library(tictoc)


                        # ---
                        # start timestamp for the full script
                        tic("Total")
                        Sys.sleep(1)
                        # ---

# 0.2 - User defined parameters ---------------
country <- "MOZ" # use the ISO code alpha 3 of the country of interest

# 0.3 - Repository creation ---------
dir.create("data")
dir.create("data/results")
dir.create("data/results/OQT")

# output path definition
hex20_path <- "data/results/OQT/hex20.geojson"  
hex50_path <- "data/results/OQT/hex50.geojson"
hex100_path <- "data/results/OQT/hex100.geojson"  
regions_path<- "data/results/OQT/regions.geojson"

# 1 - OQT polygon creation----------------

                # ---
                ## start timestamp for the section
                tic("step 1 - OQT polygon creation")
                Sys.sleep(2)
                # ---

## 1.1 Input definition ---------

## Read input files 
boundary <- st_read(dsn = paste0("data/download/boundary/",country,"_adm0_boundary.gpkg" )) 
impact_area <- st_read(dsn="data/download/impact_area/impact_area.gpkg", layer = "simpl_impact_area")


## 1.2 Polygon creation ----------

### 1.2.1 20*20 hexbin ----------------
hex20 <- st_bbox(boundary) %>% 
        st_as_sfc() %>%
        st_make_grid(n=c(20,20),
                    crs = if (missing(x)) NA_crs_ else st_crs(x),
                    what = "polygons",
                    square = FALSE) %>%
        st_as_sf() %>%
        st_join(boundary,
                #join = st_within,
                join = st_intersects,
                left=FALSE)
hex20$ogc_fid <- rownames(hex20)

st_write(hex20, dsn = hex20_path, append = F) 

### 1.2.2 50*50 hexbin ----------------
hex50 <- st_bbox(boundary) %>% 
          st_as_sfc() %>%
          st_make_grid(n=c(50,50),
                       crs = if (missing(x)) NA_crs_ else st_crs(x),
                       what = "polygons",
                       square = FALSE) %>%
          st_as_sf() %>%
          st_join(boundary,
                  #join = st_within,
                  join = st_intersects,
                  left=FALSE)
hex50$ogc_fid <- rownames(hex50)

st_write(hex50, dsn = hex50_path) 

### 1.2.3 100*100 hexbin ----------------

hex100 <- st_bbox(boundary) %>% 
          st_as_sfc() %>%
          st_make_grid(n=c(100,100),
                      crs = if (missing(x)) NA_crs_ else st_crs(x),
                      what = "polygons",
                      square = FALSE) %>%
          st_as_sf() %>%
          st_join(boundary,
                  #join = st_within,
                  join = st_intersects,
                  left=FALSE)
hex100$ogc_fid <- rownames(hex100)

st_write(hex100, dsn = hex100_path)   

### 1.2.4 flooded region ----------------                   
# flooded_region <- st_crop( boundary, st_bbox(impact_area)) %>%
#                   subset(select="geom")
# non_flooded_region <- st_difference(boundary, flooded_region)%>%
#                       subset(select="geom")
# regions <- rbind(flooded_region,non_flooded_region)
# 
# st_write(regions, dsn = regions_path)                     
                    


                ## stop timestamp for the section
                toc(log = TRUE, quiet = TRUE)

# 2 Output messages --------------------------------

## 2.1 Running time ------------------------

## stop timestamp fof the script
toc(log = TRUE, quiet = TRUE)

## print timestamps results
log.txt <- tic.log(format = TRUE)
print(log.txt)
tic.clearlog() # clear the logs of timestamps                   

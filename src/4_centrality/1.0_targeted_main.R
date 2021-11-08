#Head ---------------------------------
# purpose: 
## based on the local instance of ORS

##Prerequisites:
## Have your local instance of ORS running : https://github.com/GIScience/openrouteservice/blob/master/docker/README.md


# 0.1 Libraries ---------------------------------
library(tidyverse) # get data wrangling functions
library(sf) # spatial stuff
sf_use_s2(FALSE) # last version of sf uses s2 instead of GEOS for ellipsoidal coordinates but it presents some bugs so we disactivate it:https://github.com/r-spatial/sf/issues/1649
library(httr)
library(tictoc) # generate timestamps
library(jsonlite) # manage JSON format
library(sfnetworks)
library(tidygraph)
library(raster)
library(tmap) # 
library(tmaptools)
library(OpenStreetMap)
library(grid)
library(gridExtra)
library(classInt)
library(raster)
library(doParallel)

source("src/4_centrality/1.1_export_graph.R")
source("src/4_centrality/1.2_network_creation.R")
source("src/4_centrality/1.3_targeted_centrality_local.R")


                                        # ---
                                        # start timestamp forthe full script
                                        tic("Total")
                                        Sys.sleep(1)
                                        # ---

# 0.2 - User defined parameters ---------------


profile <- "driving-car"# choose between "driving-car" and "foot-walking"
focus_area <- "Mozambique" # choose between "Dondo", "Makambine","Mocuba", "Tica" and "Quelimane"
scope <- "all" # choose between "primary", "non_primary" or "all"
directionality <- "bi" # choose between "bi" and "uni"
indicator <- "tc" # choose between "tc" and "pc"
tc_cluster <- 20

# 0.3 - Repository creation
dir.create("data")
dir.create("data/results")
dir.create(paste0("data/results/",profile ))
dir.create(paste0("data/results/",profile,"/centrality"))
dir.create(paste0("data/results/",profile,"/centrality/",focus_area))

# 0.4 - Bbox definition
if (focus_area == "Dondo"){
    # bbox <- st_bbox(c(xmin = 34.6042, xmax = 34.8971, ymax = -19.3455, ymin = -19.6876), crs = st_crs(4326))  bbox_ors <- paste0('[[34.6042,-19.6876],[34.8971,-19.3455]]')
    bbox <- st_bbox(c(xmin = 34.58545, ymin = -19.69468, xmax = 34.89867, ymax = -19.41471), crs = st_crs(4326))
} else if (focus_area == "Tica"){
    bbox <- st_bbox(c(xmin = 34.2622, ymin = -19.4413, xmax = 34.4931, ymax = -19.2750), crs = st_crs(4326))
} else if (focus_area == "Quelimane"){
    bbox <- st_bbox(c(xmin = 36.4904, ymin = -17.9445, xmax = 37.1729, ymax = -17.5288), crs = st_crs(4326))
} else if (focus_area == "Makambine"){
    bbox <- st_bbox(c(xmin = 33.8940, ymin = -19.8453, xmax = 34.1978, ymax = -19.6399), crs = st_crs(4326))
} else if (focus_area == "Mocuba"){
    bbox <- st_bbox(c(xmin = 36.9023, ymin = -16.8857, xmax = 37.1633, ymax = -16.7064), crs = st_crs(4326))
} else if (focus_area == "Mozambique"){
    bbox <- st_bbox(c(xmin = 30.21559, ymin = -26.86804, xmax = 40.83752, ymax = -10.47377), crs = st_crs(4326))
} else if (focus_area == "test"){
    bbox <- st_bbox(c(xmin = 34.5221, ymin = -19.6724, xmax = 35.0588, ymax = -19.3175), crs = st_crs(4326))
}

# 0.5 - Input path
impact_area_path <- "data/download/impact_area/impact_area.gpkg"
impact_area <- st_read(dsn = impact_area_path, layer = "simpl_impact_area")

# 0.6 - Output path
network_path <- paste0("data/results/",profile,"/centrality/",focus_area,"/network.gpkg") 
tc_path <- paste0("data/results/",profile,"/centrality/",focus_area,"/",tc_cluster,"km_",scope,"_centrality.gpkg")

# 1 - Targeted centrality----------------

## 1.1 Graph creation-------

                # ---
                ## start timestamp for the section
                tic("step 1.1 - Graph creation")
                Sys.sleep(2)
                # ---

cl <- makeCluster(2, type = "FORK")
registerDoParallel(cl)
instances <-c("normal","impact")
foreach(i=1:length(instances),
        .packages=c("tidyverse",
                    "sf",
                    "jsonlite",
                    "httr")) %dopar% {     
                        
                        ### 1.1.1  Export graphs  ---------
                        graph_json_path <- paste0("data/results/",profile,"/centrality/",focus_area,"/",instances[i],"_graph.json")
                        if (!file.exists(graph_json_path)){                                  
                            url <- paste0("http://ors-app-",instances[i],":8080/ors/v2/export/",profile,"/json") # for R running on rocker container
                            graph_json <- exportGraph(url, bbox)
                            
                            write(graph_json, graph_json_path)
                        } else {
                            graph_json <- fromJSON(graph_json_path)
                        }
                        
                        ### 1.1.2  Create graphs  ---------
                        if(file.exists(network_path) && paste0("edges_", instances[i]) %in% st_layers(network_path)$name){
                            # do nothing
                        } else {
                            network <- createNetwork(graph_json)
                            # write the graph edges and nodes for testing purposes
                            edges <- network %>%
                                activate("edges") %>%
                                st_as_sf()
                            st_write(edges, dsn = network_path, layer = paste0("edges_", instances[i]), append =F)
                        }
                        remove(edges)
                    }
stopCluster(cl)


                # ---
                ## stop timestamp for the section
                toc(log = TRUE, quiet = TRUE)
                # ---

## 1.2 Set sources and destination -------

                # ---
                ## start timestamp for the section
                tic("step 1.2 - sources and destination")
                Sys.sleep(2)
                # ---

### 1.2.1 Define the destination points as health facilities ------ 
if(file.exists(paste0("data/results/",profile,"/centrality/",focus_area,"/",tc_cluster,"km_",scope,"_clust_dst_pts.rds"))){
    destination_pts <- readRDS(file =paste0("data/results/",profile,"/centrality/",focus_area,"/",tc_cluster,"km_",scope,"_clust_dst_pts.rds"))
} else{
    # destinations points from the health facilities
    health_facilities <- st_read(dsn = "data/download/health_facilities.gpkg", layer = scope)
    destination_pts <- st_intersection(health_facilities,st_as_sf(st_as_sfc(bbox))) %>%
        subset(select=c("X.osmId","X.snapshotTimestamp", "name", "geom")) %>%
        mutate(id = row_number())
    
    st_crs(destination_pts) = 4326 # ensure the crs to be in EPSG 4326 for the buffer calculation
    
    
    ### 1.2.2 Define the sources points as population nucleus ------ 
    
    # source points from the 1km-grid population nucleus
    population <- raster("data/download/population/population_2020_const_MOZ.tif")
    
    source_pts <- population %>%
        crop(bbox) %>%
        aggregate( fact=10, fun=sum) %>% # aggregate the population to a 1km grid
        rasterToPoints(spatial = TRUE) %>% # convert the raster grid to points
        st_as_sf() %>%
        mutate(id = row_number())
    
    st_crs(source_pts) = 4326 # ensure the crs to be in EPSG 4326 for the buffer calculation
    st_write(source_pts, dsn = tc_path, layer = "pop_sources", append =F)
    
    ### 1.2.3 count the number of destination within the buffer zone for each source point ------ 
    source_pts$ndst <- lengths(st_intersects(st_buffer(source_pts, tc_cluster*0.01),destination_pts))
    st_write(source_pts, dsn = tc_path, layer = "pop_sources", append =F)
    
    ### 1.2.4 Cluster the sources around each destination with a buffer ------ 
    cl <- makeCluster(detectCores() - 2, type = "FORK")
    registerDoParallel(cl)
    temp <- foreach(i=1:nrow(destination_pts),
                    .packages=c("tidyverse",
                                "sf")) %dopar% {
                                    cluster_src <- st_intersection(source_pts, st_buffer(st_geometry(destination_pts[i,]), tc_cluster*0.01))
                                    destination_pts$cluster_src <- list(cluster_src)
                                    return(destination_pts[i,])
                                }
    destination_pts <- dplyr::bind_rows(temp)
    stopCluster(cl)
    gc()
    
    # save the source and cluster destinations to files
    saveRDS(destination_pts, file =paste0("data/results/",profile,"/centrality/",focus_area,"/",tc_cluster,"km_",scope,"_clust_dst_pts.rds"))
    
}

            # ---
            ## stop timestamp for the section
            toc(log = TRUE, quiet = TRUE)
            # ---

## 1.3 Calculate targeted centrality -------

            # ---
            ## start timestamp for the section
            tic("step 1.3 - Calculate targeted centrality")
            Sys.sleep(2)
            # ---

foreach(i=1:length(instances)) %do%{
    edges <- st_read(network_path, layer = paste0("edges_",instances[i]))
    network <- edges %>%
        as_sfnetwork(directed=TRUE) %>%
        activate("edges") %>%
        mutate(weight = weight)
    # call the function
    res_tc <- getTargeted(network, destination_pts, directionality, tc_cluster)
    st_write(res_tc,dsn = tc_path, layer = paste0(directionality,"direct_",instances[i],"_tc"), append =F)
}

            # ---
            ## stop timestamp for the section
            toc(log = TRUE, quiet = TRUE)
            # ---


# 3 Output messages --------------------------------

## 3.1 Running time ------------------------

## stop timestamp fof the script
toc(log = TRUE, quiet = TRUE)

## print timestamps results
log.txt <- tic.log(format = TRUE)
print(log.txt)
tic.clearlog() # clear the logs of timestamps




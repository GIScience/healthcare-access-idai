
getTargeted <- function (network, clust_dst.pts, directionality, buffer){
  
  # 3. Targeted centrality -------------
  ## 3.2 calculate the shortest paths for each source/dsetination pairs
  no_cores <- ceiling((detectCores())/2) # number of cores available
  
  res <- mclapply(st_geometry(clust_dst.pts), function(dst){# lapply only accepts a list so we need to get the geometry only
    tryCatch({ # if no network edge is within the buffer, it will create an error. in this case, we return an empty sf
      
      # crop the network to the extent of buffer zone in order to improve performance
      poly <- st_buffer(st_geometry(dst), buffer*0.01)
      net <- network %>%
        activate("edges") %>%
        st_crop(poly) %>%
        activate("nodes") %>%
        filter(!node_is_isolated())
      
      # retrieve the source points which are included in the buffer zone of the destination points
      dst <- st_sfc(dst, crs = st_crs(clust_dst.pts))
      cluster_src <- st_join(st_as_sf(dst),clust_dst.pts)$cluster_src[[1]]
      
      temp_res <- lapply(st_geometry(cluster_src), function(src){ # lapply only accepts a list so we need to get the geometry only
        
        # spatial join to ensure to retrieve the attribute of the source points
        src <- st_sfc(src, crs = 4326) %>%
          st_as_sf() %>%
          st_join(cluster_src)
        
        # calculate the shortest paths
        paths_to_source <- net %>%
          activate("edges") %>%
          st_network_paths(from = src,
                           to = dst,
                           weights = "weight") %>%
          pull(edge_paths) %>%
          unlist()
        # get the corresponding segments of the network
        paths_to_source_sf <- net %>%
          activate("edges") %>%
          slice(paths_to_source) %>%
          st_as_sf() %>%
          mutate(count = 1/src$ndst) %>% # add a count of the segment used for centrality, the count is divided by the number of destination within the buffer of the source
          mutate(popCount = src$population_2020_const_MOZ/src$ndst)  # add a count of the segment used for populated centrality, the count is divided by the number of destination within the buffer of the source
        
        
        return(paths_to_source_sf)
      })
      
      # according to the directionality parameter, aggregate the centrality score for the paths calculated to the destination point
      if (directionality == "uni"){
        temp_res_sf <- dplyr::bind_rows(temp_res) %>%
          dplyr::group_by(toId, fromId, weight,unidirectId,bidirectId) %>%
          summarize(tc = sum(count), pc =sum(popCount), .groups = "keep")
      } else if (directionality == "bi"){
        temp_res_sf <- dplyr::bind_rows(temp_res) %>%
          dplyr::group_by(bidirectId) %>%
          summarize(tc = sum(count), pc =sum(popCount), .groups = "keep")
      }
      
      # process follow-up
      print_follow <- paste0("processed ",st_join(st_as_sf(dst),clust_dst.pts)$id," of ", nrow(clust_dst.pts))
      write(print_follow, file = "progress_tc.txt", append =T)
      
      remove(net)
      
      return(temp_res_sf)
    },
    error=function(e) {
      temp_res_sf <- st_sf(geom = st_sfc(st_linestring()))
      return(temp_res_sf)
    })
    
  }, mc.cores=no_cores)
  
  res_sf <- dplyr::bind_rows(res)
  
  # count the occurence of each segment according to directionality
  if (directionality == "uni"){
    res_tc <- res_sf  %>% dplyr::group_by(toId, fromId, weight,unidirectId,bidirectId) %>%
      summarize(tc = sum(tc), pc =sum(pc), .groups = "keep")
  } else if (directionality == "bi"){
    res_tc <- res_sf  %>% dplyr::group_by(bidirectId) %>%
      summarize(tc = sum(tc), pc =sum(pc), .groups = "keep")
  }
  
  unlink("progress_tc.txt")
  
  return(res_tc)
  
}


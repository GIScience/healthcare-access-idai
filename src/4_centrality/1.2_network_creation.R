
createNetwork <- function (graph){

  
        # 1 Parameters --------------------
        
        # the response is given as 2 lists :locations and edgeScores
        nodes <- fromJSON(graph)$nodes # nodes ID and coordinate
        edges <- fromJSON(graph)$edges # edges score defined with 2 nodes
        
        # we generate the data frame with the 2 nodes which define the edge and the score            
        edges_temp <- merge(edges, nodes, by.x = "fromId", by.y="nodeId") %>% rename(from_coord = location)  
        edges_df <- merge(edges_temp, nodes, by.x = "toId", by.y="nodeId") %>% rename(to_coord = location) 
        
        # split the coordinates of both point to longitude and latitude colums
        
        no_cores <- detectCores() - 1
        x <- split(edges_df, sample(rep(1:no_cores, ceiling(nrow(edges_df)/no_cores))))
        temp_res <- mclapply(x, function(edges_df){
        for (i in 1:length(edges_df$weight)) {
                   edges_df$from_lon[i] <- edges_df$from_coord[i][[1]][[1]]
                   edges_df$from_lat[i] <- edges_df$from_coord[i][[1]][[2]]
                   edges_df$to_lon[i] <- edges_df$to_coord[i][[1]][[1]]
                   edges_df$to_lat[i] <- edges_df$to_coord[i][[1]][[2]]
        }
          return(edges_df)
        }, mc.cores=no_cores)
        edges_df <- dplyr::bind_rows(temp_res)
        
        # create a geometry attribute as character
        edges_df$geom = sprintf("LINESTRING(%s %s, %s %s)",
                                     edges_df$from_lon,
                                     edges_df$from_lat,
                                     edges_df$to_lon,
                                     edges_df$to_lat)
        # add a unidirectional Id for each segement
        edges_df$unidirectId <- seq.int(nrow(edges_df))
        
        edges_df <- subset(edges_df,select = c('toId' , 'fromId','weight', "geom", "unidirectId")) %>% tibble()
        
        # create a bidirectional Id attribute for each segment regardless to its direction
        edges_map <- edges_df %>% mutate( toFrom = map2_chr( toId, fromId, ~str_flatten(sort(c(.x,.y)), collapse = "_") ) )
        edges_map_y <- edges_map %>% group_by(toFrom) %>% filter( n() == 2 ) %>% ungroup %>%   # Keep groups of size 2
          dplyr::select(toFrom) %>% distinct %>% mutate( bidirectId = 1:n() )   
        
        edges_df <- left_join( edges_map, edges_map_y ) %>% dplyr::select(-toFrom) 
        
        
        # bind together into one sf
        edges_sf <- edges_df %>%
                    st_as_sf( wkt = "geom", crs= 4326)
        
        # create a network
        net <- edges_sf %>%
                as_sfnetwork(directed=TRUE) %>%
                activate("edges") %>%
                mutate(weight = weight) 
        
        return(net)

}


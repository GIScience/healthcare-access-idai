
dissolveIsochrones <- function (raw_isochrones, boundary){
                    
    # 1. group the isochrones by time range and summarize it ------------------------- 
    dissolved_isochrones <- raw_isochrones %>% group_by(value) %>% summarize() 
    
    # 2. combine each time range iscochrone with lower time range to unsure completeness of isochrones --------------------
    ## workaround proposed here https://gitlab.gistools.geog.uni-heidelberg.de/giscience/disaster-tools/health_access/isochrone_access/-/issues/66
    ## related to ORS issue: https://github.com/GIScience/openrouteserviece/issues/468
    arrange(dissolved_isochrones, value) ## ensure the isochrones are ordered from smaller to bigger time range
    ## union of each isochrone with the one of lower time range
    for (i in 2:length(dissolved_isochrones$value)){
      dissolved_isochrones$geom[i] <- st_union(dissolved_isochrones$geom[i],dissolved_isochrones$geom[i-1])
    }
    
    # 3. loop into the isochrones to crop them to the extent of the boundaries -------------------
    for (i in 1:length(dissolved_isochrones$value)){
      dissolved_isochrones$geom[i] <- st_intersection(dissolved_isochrones$geom[i],boundary)
    }
    return(dissolved_isochrones)
}

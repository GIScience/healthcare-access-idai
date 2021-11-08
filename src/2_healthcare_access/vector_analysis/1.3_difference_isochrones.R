
differentiateIsochrones <- function (dissolved_isochrones, boundary){      
  
    ## 3.2 Add > 60 mins isochrone ------------------
    ## Append the boundary polygon to the isochrone with time range value 999999
    ## It will enable to have a last isochrone for time range >3600s
    boundary_sf <- st_sf("value"=99999, "geom"=boundary$geom[1], crs = 4326 ) # create an sf object of the boundary with same attributes as isochrones
    #dissolved_isochrones <- rbind(dissolved_isochrones,boundary_sf) # bind isochrone file with boundary file
    diss_boundary_iso <- rbind(dissolved_isochrones,boundary_sf) # bind isochrone file with boundary file
    
    
    ## 3.3 Difference processing  between isochrones -----------------------
    ## create a list of the time range values
    time_range <- unique(diss_boundary_iso$value)
    ## convert the multipolygons to single polygons to ease geometry operations and ensure it is sorted by crescent value
    dissol_iso_multi <- st_cast(diss_boundary_iso,"POLYGON") %>%
                          group_by(value) %>%
                          summarise() %>%
                          arrange(value) 
    
    # ## initialize the output with the isochrones of first time range
     diff_iso_multi <- dissol_iso_multi[dissol_iso_multi$value==time_range[1],]
    # 
    # ## for each time range, we will do a st_difference between the isochrones of a time range and the ones of the inferior time range
     for (i in 2:length(time_range)){
      temp_multi_inf <- dissol_iso_multi[dissol_iso_multi$value==time_range[i-1],] #create the sf of inferior time_range isochrones
      temp_multi_sup <- dissol_iso_multi[dissol_iso_multi$value==time_range[i],] #create the sf of superior time_range isochrones
    
      diff_iso_multi[i,]$value <- time_range[i]
      diff_iso_multi[i,]$geom <- st_difference(temp_multi_sup,temp_multi_inf)$geom
     }
    return(diff_iso_multi)
}

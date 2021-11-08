

getIsochrones <- function (sources, intervals, profile, instance){
                
      # 1. Set the API service according to instance parameter------------------------
      if (instance == "normal"){
        #options(openrouteservice.url = paste0("http://localhost:8080/ors")) # for R running locally
        options(openrouteservice.url = paste0("http://ors-app-normal:8080/ors")) # for R running on rocker container
      } else if (instance == "impact"){
       # options(openrouteservice.url = paste0("http://localhost:8081/ors")) # for R running locally
        options(openrouteservice.url = paste0("http://ors-app-impact:8080/ors")) # for R running on rocker container
      } else {
      }
      
      # 2.We loop for all the source_points of the input file --------------------------
        for (i in 1:nrow(sources)) {
          ### for each source_point, we loop to generate an isochrone for each time range
          for (j in intervals){
            tryCatch(
              {     isochrone <- ors_isochrones(st_coordinates(sources[i,]),
                                                     range = j,
                                                     profile = profile,
                                                     output = "sf") ### we run the API request
              
              ### check if it is the first run, then replace output, else append
              if (i == 1 & j == intervals[1]) {
                raw_isochrones <- isochrone
              } else {
                raw_isochrones <- rbind(raw_isochrones, isochrone)
              }
              },
              error=function(cond) {}
            )
          }
        }
  raw_isochrones <- raw_isochrones %>% subset(select=c("value","geometry"))
  return(raw_isochrones)
        
} 





estimatePopulation <- function(differenced_isochrones, population){
   
    # 1.Calculate the total population ------------------------
    total_pop <- cellStats(population, 'sum')
    differenced_isochrones$country_pop <- total_pop
    
    # 2.Loop through all the isochrones to calculate the sum and percentage of population -----------------
    for (i in 1:length(differenced_isochrones$value)){
      differenced_isochrones$pop_sum[i] <- exact_extract(population, differenced_isochrones$geom[i],'sum')
      differenced_isochrones$percent[i] <- differenced_isochrones$pop_sum[i]*100/total_pop
    }

    return(differenced_isochrones)
}
  

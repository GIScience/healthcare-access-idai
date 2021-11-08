
categroriseAccess <- function (raster, intervals){

        # 1 - Raster categorisation ----------------
        
        matrix_recl <- c(intervals[1], intervals[2],intervals[2])
        for (i in 2:(length(intervals)-1)){
          rowi <- c(intervals[i], intervals[i+1],intervals[i+1])
          matrix_recl <- rbind(matrix_recl, rowi)
        }
        rownames(matrix_recl) <- NULL
        
        raster_cat <- reclassify(raster, matrix_recl)
        return(raster_cat)
        

}


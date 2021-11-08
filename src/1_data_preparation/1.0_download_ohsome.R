# Head ---------------------------------
# purpose: Function to retrieve OSM Objects from Ohsome
# author: Marcel
#
#
#1 Libraries ---------------------------------
library(sf)
library(httr)
library(geojsonsf)

#2 Function ---------------------------------
getOhsomeObjects <- function(sf_boundary, filter_char, internal, to_time, props) {
    # Extracts OSM features via ohsome API by passing a extent, filter and time param.
    #
    # Args:
    #   sf_boundary: A sf object that represents the area of interest.
    #   filter_char: A string that represents the tag query for the request.
    #   internal: Boolean that controls whether the public or intenral api is used. University VPN needed.
    #   to_time: A time range or snapshot from which the objects shall be extracted.
    #
    # Returns:
    #   A sf object
    
    # Converting of the boundary sf to extent and shaping the coordinates to the right format.
    ext.str <-
      paste(as.character(st_bbox(sf_boundary)), collapse = ",")
    
    # Prepare url based on internal flag
    url <- ifelse(internal == TRUE, "https://api-internal.ohsome.org/v1/elements/centroid",
           "https://api.ohsome.org/v1/elements/centroid")
    
    
    # Fire a post request against the ohsome api to extract centroid geometries for the desired objects
    resp <- POST(
      url,
      encode = "form",
      body = list(
        #bpolys = extent,
        bboxes = ext.str,
        filter = filter_char,
        #time = "2007-10-09,2021-01-01",
        time = to_time,
        properties = props
      )
    )
    
    # Below steps are neccessary to get the geojson response as a proper sf object in R:
    # Get the binary content of the response. A not human readable format of the geojson.
    h <- httr::content(resp, as = "raw")
    # Define output file geojson and write the binary content. It will be aprsed
    # to standard geojson, therefore it is human readable in the file.
    src.file <- paste0("temp_ohsome.geojson")
    writeBin(h, src.file)
    
    # TODO ogr2ogr routine einfügen
    
    # alternative
    #write_disk(src.file, overwrite = T)
    
    # Load the written geojson as sf
    ohsome_gj <- st_read(src.file, quiet = T)
    # Remove the temporary file
    file.remove(src.file)
    
    # Intersect the response from Ohsome with the original boundary file to
    # only get objects for the area of concern.
    ohsome_gj <- ohsome_gj[sf_boundary, op = st_intersects]
    
    # cleanup some memory
    gc()
    # return sf object
    return(ohsome_gj)
}

getOhsomeAggregates <- function(sf_objects, filter_char, to_time) {
  # Extracts OSM aggregates(count for now) for (multiple) sf objects adn returns a dataframe.
  #
  # Args:
  #   sf_objects: A sf object that represents the area of interest.
  #   filter_char: A string that represents the tag query for the request.
  #   to_time: A time range or snapshot from which the objects shall be extracted.
  #
  # Returns:
  #   A dataframe with the results for each sf object
  
  
  # no internal endpoint available
  url <- "https://api.ohsome.org/v1/elements/count/groupBy/boundary"
  
  # Fire a post request against the ohsome api to extract centroid geometries for the desired objects
  resp <- POST(url ,
               encode = "form",
               body = list(
                 bpolys = sf_geojson(sf_objects),
                 filter = filter_char,
                 time = to_time,
                 format = 'csv')
  )
  
  h <- httr::content(resp, as = "raw")
  # Define output file geojson and write the binary content. It will be aprsed
  # to standard geojson, therefore it is human readable in the file.
  src.file <- paste0("temp_ohsome.csv")
  writeBin(h, src.file)
  ohsome_dat = as.data.frame(t(read.csv(src.file, skip = 3, header = F, sep = ';')), stringsAsFactors = F)
  # remove timestamp
  ohsome_dat <- ohsome_dat[-1,]
  # Remove the temporary file
  file.remove(src.file)
  # cleanup some memory
  gc()
  
  #rename columns
  names(ohsome_dat) <- c("features", filter_char)
  
  # return df
  return(ohsome_dat)
}




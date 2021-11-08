# Head ---------------------------------
# purpose: 
# author: 
#
# inspired from: https://gitlab.gistools.geog.uni-heidelberg.de/giscience/big-data/ohsome/ohsome-api-analysis-examples/completeness_highway_healthsites_jakarta/-/tree/master
#


#1 Function ---------------------------------

# A helper function that eases the communication with the API a bit.
# It handles the processing of the data to ensure that a properly formatted data.frame is returned.
# It basically passes the parametes via *postForm* to the ohsome API and converts the results into a R data.frame which is returned.
# Dates are converted into POSIXct to ease handling in plotting and regression analysis.
# The parameter *valueFieldName* specifies the name of the field in the data.frame that contains the results.
getOhsomeStat <- function(uri, filter, time, valueFieldName, bpolys, ...){
  tryCatch(results <-httr::POST(uri,
                                body = list(bpolys = bpolys,
                                            filter = filter,
                                            time = time)),
           GenericCurlError = function(x)  print(x),
           error = function(x) print(x))
    

  resultList <- httr::content(results, as = "text") %>% RJSONIO::fromJSON()
  resultsDf <- data.frame(do.call("rbind", (resultList$result)))

  # make sure the right data types are used
  # for users we have  fromTimestamp  and  toTimestamp fields, not timestampe
  if(length(grep(x=names(resultsDf), pattern = "timestamp"))> 0)
  {
    resultsDf$timestamp <- parse_datetime( as.character(resultsDf$timestamp))  
  }
  if(length(grep(x=names(resultsDf), pattern = "fromTimestamp"))> 0)
  {
    resultsDf$fromTimestamp <- parse_datetime( as.character(resultsDf$fromTimestamp))  
  }
  if(length(grep(x=names(resultsDf), pattern = "toTimestamp"))> 0)
  {
    resultsDf$toTimestamp <- parse_datetime( as.character(resultsDf$toTimestamp))  
  }
  #rename value field
  resultsDf$value <- as.numeric(as.character(resultsDf$value))
  idxValueField <- which(names(resultsDf)=="value")
  names(resultsDf)[idxValueField] <- valueFieldName
  
  
  return(resultsDf)
}

# This function uses the group by endpoint of the ohsome API to get resuls for the same key but different values.
# The values not queried explicitly are aggregated as *remainder*.
getGroupByValues <- function(uri, bpolys, groupByKey, filter, time, groupByValues, ...){

  tryCatch(results <-httr::POST(uri,
                                body = list(bpolys= bpolys,
                                            groupByKey = groupByKey,
                                            filter = filter,
                                            time = time,
                                            groupByValues = groupByValues)),
           GenericCurlError = function(x)  print(x),
           error = function(x) print(x)) 
  
  resultsList <- httr::content(results, as = "text") %>% RJSONIO::fromJSON(simplify = TRUE)
  resultsDf <- purrr::map_df(resultsList$groupByResult, tibble::as_tibble, .name_repair ="universal") %>% unnest_wider(result)
  
  if(length(grep(x=names(resultsDf), pattern = "timestamp"))> 0)
  {
    resultsDf$timestamp <- parse_datetime( as.character(resultsDf$timestamp))  
  }
  if(length(grep(x=names(resultsDf), pattern = "fromTimestamp"))> 0)
  {
    resultsDf$fromTimestamp <- parse_datetime( as.character(resultsDf$fromTimestamp))  
  }
  if(length(grep(x=names(resultsDf), pattern = "toTimestamp"))> 0)
  {
    resultsDf$toTimestamp <- parse_datetime( as.character(resultsDf$toTimestamp))  
  }
  
  resultsDf$value <- as.numeric(as.character(resultsDf$value))
  resultsDf_wide <- pivot_wider(resultsDf, names_from = groupByObject)
  
  return(resultsDf_wide)
}



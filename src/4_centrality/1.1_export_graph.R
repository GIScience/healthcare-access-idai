
exportGraph <- function (url, bbox){

  
        # 1 Parameters --------------------

        bbox_ors <- paste0('[[',bbox[1],',',bbox[2],'],[',bbox[3],',',bbox[4],']]')
        
        # 2. graph creation -----------      
         
        # 2.1 reauest ORS export endpoint to create the graph
        ### 2.1.1 Set the request body-------------------
        body <- toJSON(list(bbox = fromJSON(bbox_ors)), 
                       auto_unbox = T)
     
        ### 2.1.2 send the POST request ---------------------
        resp <- POST(
          url = url,
          encode = "raw",
          body = body,
          httr::add_headers(`accept` = 'application/json'), 
          httr::content_type('application/json'),
          verbose()
        )
        resp_content <- httr::content(resp, as = "text")
}
#Head ---------------------------------
# purpose: 

##Prerequisites:
## 

# 1 Libraries ---------------------------------
library(sf)
library(tidyverse)
library(ggpubr) # for the arrangement of multiple ggplot objects
library(units)
library(ggplot2)
library(grid)
library(gridExtra)
library(tictoc)


                                        # ---
                                        ## start timestamp forthe full script
                                        tic("total")
                                        Sys.sleep(1)
                                        # ---


# 2 Parameters -----------------------------

                                        # ---
                                        ## start timestamp for the section
                                        tic("step 2 - Define parameters")
                                        Sys.sleep(2)
                                        # ---

## 2.1 Manual parameters ----------------------------
                                        
## 2.2 Set automatic parameters -------------------------------------------
### 2.1.1 Create a folder to store the processed files ----------------------------
dir.create("data")
dir.create("data/results")
dir.create("data/results/completeness")                                       

### 2.1.2 Set the input and output path ----------- 
### input
load("data/results/completeness/ohsomeStats.Rdata")

### output
contribution_png_path <- "data/results/completeness/osm_contribution.png"
activity_png_path <- "data/results/completeness/osm_activity.png"

### 2.1.3 Other parameters --------------
# timestamp of the cyclone
idai_time <- resRoadContribLengthFlood$timestamp[136]

                                    # ---
                                    ## stop timestamp for the section
                                    toc(log = TRUE, quiet = TRUE)
                                    # ---


# 3 Plot OSM contributions -----------    

                                    # ---
                                    ## start timestamp for the section
                                    tic("step 3 - Plot OSM contributions")
                                    Sys.sleep(2)
                                    # ---

## 3.1 Plot highway ---------------

### 3.1.1 Plot Highway on flooded area --------------
# Change the table format from the wide format to the long format since this simplifies handling in ggplot dramatically.
resHighway_longFlood <- pivot_longer(resRoadContribLengthFlood, remainder:`highway=motorway`, names_to = "type", values_to = "length" )
resHighway_longFlood$length <- resHighway_longFlood$length / 1000 # convert to km


# Reorder the factor levels for nicer plotting
resHighway_longFlood$type <- factor(resHighway_longFlood$type,
                                   levels = c("highway=path",
                                              "highway=track",
                                              "highway=unclassified",
                                              "highway=motorway",
                                              "highway=trunk",
                                              "highway=primary",
                                              "highway=secondary",
                                              "highway=tertiary",
                                              "remainder"),
                                   labels = c("Path",
                                              "Track",
                                              "Unclassified",
                                              "Motorway",
                                              "Trunk",
                                              "Primary",
                                              "Secondary",
                                              "Tertiary",
                                              "Other"))


# Plot the Highway
pHighwFlood <- ggplot(resHighway_longFlood, mapping=aes(x=timestamp, y=length/1000, fill=type)) +
            geom_area(position="stack") +  
            xlab("") + 
            ylab("Highway length [1000 km]") + 
            ylim(0,160) +
            labs(subtitle = "Flooded regions") +
        geom_vline(xintercept=as.numeric(idai_time),
                   linetype=4,
                   colour = "red") +
        geom_text(aes(x=idai_time, # timestamp of the cyclone
                      label="Cyclone impact",
                      y=20,
                      colour = "red"),
                  vjust = -10,
                  hjust = 1.1,
                  size = 3) +
          ggthemes::scale_fill_economist() +
          theme(legend.position = "none",
                axis.title.y = element_text(margin = unit(c(0, 3, 0, 0), "mm"), size = 9),
                axis.title.x = element_blank(),
                axis.text = element_text(size = 7))



### 3.1.2 Plot Highway on non flooded area --------------
# Change the table format from the wide format to the long format since this simplifies handling in ggplot dramatically.
resHighway_longNoFlood <- pivot_longer(resRoadContribLengthNoFlood, remainder:`highway=motorway`, names_to = "type", values_to = "length" )
resHighway_longNoFlood$length <- resHighway_longNoFlood$length / 1000 # convert to km


# Reorder the factor levels for nicer plotting
resHighway_longNoFlood$type <- factor(resHighway_longNoFlood$type,
                                      levels = c("highway=path",
                                                 "highway=track",
                                                 "highway=unclassified",
                                                 "highway=motorway",
                                                 "highway=trunk",
                                                 "highway=primary",
                                                 "highway=secondary",
                                                 "highway=tertiary",
                                                 "remainder"),
                                      labels = c("Path",
                                                 "Track",
                                                 "Unclassified",
                                                 "Motorway",
                                                 "Trunk",
                                                 "Primary",
                                                 "Secondary",
                                                 "Tertiary",
                                                 "Other"))


# Plot the Highway
pHighwNoFlood <- ggplot(resHighway_longNoFlood, mapping=aes(x=timestamp, y=length/1000, fill=type)) +
        geom_area(position="stack") +  
        xlab("") + 
        ylab("") +
        ylim(0,160) +
        labs(subtitle = "Other regions") +  
        geom_vline(xintercept=as.numeric(idai_time),
                   linetype=4,
                   colour = "red") +
        ggthemes::scale_fill_economist() +
        theme(legend.position = "none",
              axis.title.y = element_text(margin = unit(c(0, 3, 0, 0), "mm"), size = 9),
              axis.title.x = element_blank(),
              axis.text = element_text(size = 7))

### 3.1.3 Plot legend Highway on flooded area --------------
legHighw <- get_legend(
        ggplot(resHighway_longFlood, mapping=aes(x=timestamp, y=length, fill=type)) +
        geom_area(position="stack") +    
        geom_vline(xintercept=as.numeric(idai_time),
                   linetype=4) +
        ggthemes::scale_fill_economist() +
        theme(legend.position = "top",
              legend.direction = "horizontal",
              legend.key.size = unit(3, 'mm'),
              legend.title = element_blank(),
              element_blank(),
              axis.title.y = element_text(margin = unit(c(0, 3, 0, 0), "mm")),
              axis.title.x = element_blank())
        ) %>% as_ggplot()


## 3.2 Plot Health sites ---------------

### 3.2.1 Plot health sites on flooded area --------------
# Change the table format from the wide format to the long format since this simplifies handling in ggplot dramatically.
resHs_longFlood <- pivot_longer(resHsFlood, primaryCount:non_primaryCount, names_to = "type", values_to = "count" )

# Reorder the factor levels for nicer plotting
resHs_longFlood$type <- factor(resHs_longFlood$type, 
                          levels = c("primaryCount", "non_primaryCount"),
                          labels = c("Primary", "Non primary"))


# Plot the Health sites
pHsFlood <- ggplot(resHs_longFlood, mapping=aes(x=timestamp, y=count, fill=type)) +
          geom_area(position="stack",
                    show.legend = FALSE) + 
          xlab("") + 
          ylab("Health facilities Count") + 
          ylim(0,700) +
          labs(subtitle = "Flooded regions") +   
          geom_vline(xintercept=as.numeric(idai_time),
                     linetype=4,
                     colour = "red") +
        ggthemes::scale_fill_economist() + 
        theme(plot.title = element_blank(),
              axis.title.y = element_text(margin = unit(c(0, 3, 0, 0), "mm"), size = 9),
              axis.title.x =  element_blank(),
              axis.text = element_text(size = 7))


### 3.2.2 Plot health sites on non flooded area --------------
# Change the table format from the wide format to the long format since this simplifies handling in ggplot dramatically.
resHs_longNoFlood <- pivot_longer(resHsNoFlood, primaryCount:non_primaryCount, names_to = "type", values_to = "count" )

# Reorder the factor levels for nicer plotting
resHs_longNoFlood$type <- factor(resHs_longNoFlood$type, 
                               levels = c("primaryCount", "non_primaryCount"),
                               labels = c("Primary", "Non primary"))


# Plot the Health sites
pHsNoFlood <- ggplot(resHs_longNoFlood, mapping=aes(x=timestamp, y=count, fill=type)) +
        geom_area(position="stack",
                  show.legend = FALSE) + 
        xlab("") + 
        ylab("") + 
        ylim(0,700) +
        labs(subtitle = "Other regions") +   
        geom_vline(xintercept=as.numeric(idai_time),
                   linetype=4,
                   colour = "red") +
        ggthemes::scale_fill_economist() + 
        theme(plot.title = element_blank(),
              axis.title.y = element_text(margin = unit(c(0, 3, 0, 0), "mm"), size = 9),
              axis.title.x =  element_blank(),
              axis.text = element_text(size = 7))

### 3.2.3 Plot legend Health sites on flooded area --------------
legHs <- get_legend(
        ggplot(resHs_longNoFlood, mapping=aes(x=timestamp, y=count, fill=type)) +
        geom_area(position="stack",
                  show.legend = TRUE) +   
        geom_vline(xintercept=as.numeric(idai_time),
                   linetype=4) +
        ggthemes::scale_fill_economist() + 
        theme(legend.position = "top",
              legend.direction = "horizontal",
              legend.title = element_blank(),
              legend.key.size = unit(3, 'mm'),
              axis.title.y = element_text(margin = unit(c(0, 3, 0, 0), "mm")),
              axis.title.x =  element_blank())
        ) %>% as_ggplot()

## 3.3 Plot together and save ------------
png(filename = contribution_png_path,
    width = 15,
    height= 12,
    units = "cm",
    res = 300)


vp_layout <- viewport(layout=grid.layout(2, 1, heights = unit(c(0.05,0.95),"npc")))
pushViewport(vp_layout)                                             
        # plot the main title
        vp_title <- viewport(layout.pos.row = 1,
                             layout.pos.col = 1)
        grid.text("OSM contributions Mozambique",
                  gp=gpar(fontsize=15,
                          fontface=2),
                  vp = vp_title)
        
        # plot the diagrams
        vp_diagrams <- viewport(layout = grid.layout(2,1),
                              layout.pos.row=2,
                              layout.pos.col=1)
        pushViewport(vp_diagrams)  
        
                # plot the contribution on Highway 
                vp_Highw <- viewport(layout = grid.layout(2,2, heights = unit(c(0.9,0.1),"npc")),
                                        layout.pos.row=1,
                                        layout.pos.col=1)
                pushViewport(vp_Highw)  
                        # plot the contribution on Highway  for flooded area
                        vp_HghwFlood <- viewport(layout.pos.row=1,
                                               layout.pos.col=1)
                        print(pHighwFlood, vp = vp_HghwFlood)
                        # plot the contribution on Highway  for non flooded area
                        vp_HghwNoFlood <- viewport(layout.pos.row=1,
                                                 layout.pos.col=2)
                        print(pHighwNoFlood, vp = vp_HghwNoFlood )
                        # plot the legend on Highway
                        vp_HghwLeg <- viewport(layout.pos.row=2,
                                               layout.pos.col=1:2)
                        print(legHighw, vp = vp_HghwLeg)
                        upViewport()
                
                # plot the contribution on amenities
                vp_Hs <- viewport(layout = grid.layout(2,2, heights = unit(c(0.9,0.1),"npc")),
                                     layout.pos.row=2,
                                     layout.pos.col=1)
                 pushViewport(vp_Hs)                  
                        #plot the contribution on Health sites for flooded area
                        vp_HsFlood <- viewport(layout.pos.row=1,
                                               layout.pos.col=1)
                        print(pHsFlood, vp = vp_HsFlood)
                        # plot the contribution on Health sites for non flooded area
                        vp_HsNoFlood <- viewport(layout.pos.row=1,
                                                 layout.pos.col=2)
                        print(pHsNoFlood, vp = vp_HsNoFlood )
                        # plot the legend on Health sites
                        vp_HsLeg<- viewport(layout.pos.row=2,
                                            layout.pos.col=1:2)
                        print(legHs, vp = vp_HsLeg)
                        
                        # plot a caption for explanation
                        vp_caption_frame <- viewport(layout = grid.layout(3,2),
                                                     layout.pos.row=2,
                                                     layout.pos.col=2)
                        pushViewport(vp_caption_frame) 
                        
                                # plot first line of caption
                                vp_caption1 <- viewport(layout.pos.row = 1,
                                                        layout.pos.col = 2)
                                grid.text("* flooded regions : areas within flooded extent bbox",
                                          gp=gpar(fontsize=4,
                                                  fontface=2),
                                          vp = vp_caption1)
                                # plot first line of caption
                                vp_caption2 <- viewport(layout.pos.row = 2,
                                                        layout.pos.col = 2)
                                grid.text("  other regions : rest of the country",
                                          gp=gpar(fontsize=4,
                                                  fontface=2),
                                          vp = vp_caption2)
                                upViewport()
                        upViewport()
                upViewport()
        
        upViewport()
dev.off()   


                                                ## stop timestamp for the section
                                                toc(log = TRUE, quiet = TRUE)
                                                # ---

# 4 Plot OSM users activity -----------    

                                                # ---
                                                ## start timestamp for the section
                                                tic("step 4 - Plot OSM users acitvity")
                                                Sys.sleep(2)
                                                # ---

## 4.1 Plot users activity on Highway ---------------
                                                
### 4.1.1 Plot users activity on Highway on flooded area --------------
pHighwFlood <- resActiveUsersHighwFlood[49:157,] %>% # start the plot in 2012 to ease reding
        ggplot(mapping=aes(x=toTimestamp, y=countHighwayUsers)) +
        geom_area(alpha=.7,
                  fill = "#C83737") +
        xlab("") +
        ylab("Active users on highway tags") +
        ylim(0,1200) +
        labs(subtitle = "Flooded regions") + 
         geom_vline(xintercept=as.numeric(idai_time),
                    linetype=4,
                    colour = "red") +
         geom_text(aes(x=idai_time,label="Cyclone impact", y=20, colour = "red"),
                   vjust = -10,
                   hjust = 1.1,
                   size = 3) +
        ggthemes::scale_fill_economist() +
        theme(legend.position = "none",
              axis.title.y = element_text(margin = unit(c(0, 3, 0, 0), "mm")))

                                                
                                                
### 4.1.2 Plot users activity on Highway on non flooded area --------------
pHighwNoFlood <- resActiveUsersHighwNoFlood[49:157,] %>% # start the plot in 2012 to ease reding
        ggplot(mapping=aes(x=toTimestamp, y=countHighwayUsers)) +
        geom_area(alpha=.7,
                  fill = "#C83737") +
        xlab("") +
        ylab("") +
        ylim(0,1200) +
        labs(subtitle = "Other regions") +  
        geom_vline(xintercept=as.numeric(idai_time),
                   linetype=4,
                   colour = "red") +
        ggthemes::scale_fill_economist() +
        theme(axis.title.y = element_text(margin = unit(c(0, 3, 0, 0), "mm")))

### 4.2.3 Plot legend users activity on Highway --------------
legHighw <- get_legend(
            ggplot(resActiveUsersHighwNoFlood, mapping=aes(x=toTimestamp, y=countHighwayUsers)) +
            geom_area(alpha=.7,
                      fill = "#C83737",
                      show.legend = TRUE) +
            ggthemes::scale_fill_economist() + 
            theme(legend.position = "top",
                  legend.direction = "horizontal",
                  legend.title = element_blank(),
                  legend.key.size = unit(3, 'mm'),
                  axis.title.y = element_text(margin = unit(c(0, 3, 0, 0), "mm")),
                  axis.title.x =  element_blank())
            ) %>% as_ggplot()


## 4.2 Plot users activity on Amenity ---------------
                                                
### 4.2.1 Plot users activity on amenity on flooded area --------------

# Change the table format from the wide format to the long format since this simplifies handling in ggplot dramatically.
resActiveAmeni_longflood <- pivot_longer(resActiveUsersAmenityFlood,
                                    remainder:`amenity=doctors`,
                                    names_to = "type",
                                    values_to = "countAmenityUsers" )
                                                
# Reorder the factor levels for nicer plotting
resActiveAmeni_longflood$type <- factor(resActiveAmeni_longflood$type,
                                   levels = c("remainder",
                                              "amenity=clinic",
                                              "amenity=hospital",
                                              "amenity=doctors"),
                                   labels = c( "Other",
                                              "Clinic",
                                              "Hospital",
                                              "Doctors"))                                                
                                                
pAmeniFlood <- resActiveAmeni_longflood[193:628,] %>% # start the plot in 2012 to ease reding
        ggplot(mapping=aes(x=toTimestamp, y=countAmenityUsers, fill=type)) +
        geom_area(position="stack",
                  show.legend = FALSE) +
        xlab("") +
        ylab("Active users on amenity tags") +
        ylim(0,60) +
        labs(subtitle = "Flooded regions") +  
        geom_vline(xintercept=as.numeric(idai_time),
                   linetype=4,
                   colour = "red") + 
        ggthemes::scale_fill_economist() +
        theme( legend.text = element_text(size = 9),
               legend.title=element_blank(),
               axis.title.y = element_text(margin = unit(c(0, 3, 0, 0), "mm")),
               axis.title.x =  element_blank())
                                                
### 4.2.2 Plot users activity on amenity on non flooded area --------------

# Change the table format from the wide format to the long format since this simplifies handling in ggplot dramatically.
resActiveAmeni_longnoflood <- pivot_longer(resActiveUsersAmenityNoFlood,
                                         remainder:`amenity=doctors`,
                                         names_to = "type",
                                         values_to = "countAmenityUsers" )

# Reorder the factor levels for nicer plotting
resActiveAmeni_longnoflood$type <- factor(resActiveAmeni_longnoflood$type,
                                          levels = c("remainder",
                                                     "amenity=clinic",
                                                     "amenity=hospital",
                                                     "amenity=doctors"),
                                          labels = c( "Other",
                                                      "Clinic",
                                                      "Hospital",
                                                      "Doctors"))  

pAmeniNoFlood <- resActiveAmeni_longnoflood[193:628,] %>% # start the plot in 2012 to ease reding
                    ggplot(mapping=aes(x=toTimestamp, y=countAmenityUsers, fill=type)) +
                    geom_area(position="stack",
                              show.legend = FALSE) +
                    xlab("") +
                    ylab("") +
                    ylim(0,60) +
                    labs(subtitle = "Other regions") +   
                    geom_vline(xintercept=as.numeric(idai_time),
                               linetype=4,
                               colour = "red") +
                    ggthemes::scale_fill_economist() +
                    theme( legend.text = element_text(size = 9),
                           legend.title=element_blank(),
                           axis.title.y = element_text(margin = unit(c(0, 3, 0, 0), "mm")),
                           axis.title.x =  element_blank())

### 4.2.3 Plot legend users activity on Amenities --------------
legAmeni  <- get_legend(
                        ggplot(resActiveAmeni_longnoflood, mapping=aes(x=toTimestamp, y=countAmenityUsers, fill=type)) +
                            geom_area(position="stack",
                                      show.legend = TRUE) +   
                            geom_vline(xintercept=as.numeric(idai_time),
                                       linetype=4) +
                            ggthemes::scale_fill_economist() + 
                            theme(legend.position = "top",
                                  legend.direction = "horizontal",
                                  legend.title = element_blank(),
                                  legend.key.size = unit(3, 'mm'),
                                  axis.title.y = element_text(margin = unit(c(0, 3, 0, 0), "mm")),
                                  axis.title.x =  element_blank())
                    ) %>% as_ggplot()                                                
                                                
## 4.3 Plot together and save ------------
     
png(filename = activity_png_path,
    width = 15,
    height= 12,
    units = "cm",
    res = 300)
                                                
                                                
vp_layout <- viewport(layout=grid.layout(3, 1, heights = unit(c(0.05,0.92,0.03),"npc"))) # split the plot into 4 quarters + 1 first line of title
pushViewport(vp_layout)                                             
        # plot the main title
        vp_title <- viewport(layout.pos.row = 1,
                             layout.pos.col = 1)
        grid.text("OSM active users Mozambique",
                  gp=gpar(fontsize=15,
                          fontface=2),
                  vp = vp_title)
        
        # plot the diagrams
        vp_diagrams <- viewport(layout = grid.layout(2,1),
                                layout.pos.row=2,
                                layout.pos.col=1)
        pushViewport(vp_diagrams)  
        
                # plot the contribution on Highway 
                vp_Highw <- viewport(layout = grid.layout(2,2, heights = unit(c(0.9,0.1),"npc")),
                                     layout.pos.row=1,
                                     layout.pos.col=1)
                pushViewport(vp_Highw) 
                        # plot the activity on Health sites for flooded area
                        vp_HighwFlood <- viewport(layout.pos.row=1,
                                              layout.pos.col=1)
                        print(pHighwFlood, vp = vp_HighwFlood)
                        # plot the activity on Health sites for non flooded area
                        vp_HighwNoFlood <- viewport(layout.pos.row=1,
                                              layout.pos.col=2)
                        print(pHighwNoFlood, vp = vp_HighwNoFlood )
                        # plot the legend on Highway
                        vp_HghwLeg <- viewport(layout.pos.row=2,
                                               layout.pos.col=1:2)
                        print(legHighw, vp = vp_HghwLeg)
                        upViewport()
                        
                # plot the contribution on Highway 
                vp_Ameni <- viewport(layout = grid.layout(2,2, heights = unit(c(0.9,0.1),"npc")),
                                     layout.pos.row=2,
                                     layout.pos.col=1)
                pushViewport(vp_Ameni) 
                        # plot the activity on Health sites for flooded area
                        vp_AmeniFlood <- viewport(layout.pos.row=1,
                                               layout.pos.col=1)
                        print(pAmeniFlood, vp = vp_AmeniFlood)
                        # plot the activity on Health sites for non flooded area
                        vp_AmeniNoFlood <- viewport(layout.pos.row=1,
                                                 layout.pos.col=2)
                        print(pAmeniNoFlood, vp = vp_AmeniNoFlood )
                        # plot the legend on amenities
                        vp_ameniLeg <- viewport(layout.pos.row=2,
                                               layout.pos.col=1:2)
                        print(legAmeni, vp = vp_ameniLeg)
                        
                        # plot a caption for explanation
                        vp_caption_frame <- viewport(layout = grid.layout(3,2),
                                                     layout.pos.row=2,
                                                     layout.pos.col=2)
                        pushViewport(vp_caption_frame) 
                        
                                # plot first line of caption
                                vp_caption1 <- viewport(layout.pos.row = 1,
                                                        layout.pos.col = 2)
                                grid.text("* flooded regions : areas within flooded extent bbox",
                                          gp=gpar(fontsize=4,
                                                  fontface=2),
                                          vp = vp_caption1)
                                # plot first line of caption
                                vp_caption2 <- viewport(layout.pos.row = 2,
                                                        layout.pos.col = 2)
                                grid.text("  other regions : rest of the country",
                                          gp=gpar(fontsize=4,
                                                  fontface=2),
                                          vp = vp_caption2)
                                upViewport()
                        upViewport()
        upViewport()
dev.off()        
        
                                                                                                  


                                    ## stop timestamp for the section
                                    toc(log = TRUE, quiet = TRUE)
                                    # ---
                                    
                                    
                                    
# 5 Output messages --------------------------------

## 5.1 Running time ------------------------

## stop timestamp fof the script
toc(log = TRUE, quiet = TRUE)

## print timestamps results
log.txt <- tic.log(format = TRUE)
print(log.txt)
tic.clearlog() # clear the logs of timestamps




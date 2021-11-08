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
load("data/results/completeness/aggreg_ohsomeStats.Rdata")

### output
contribution_png_path <- "data/results/completeness/osm_contribution_aggreg.png"
activity_png_path <- "data/results/completeness/osm_activity_aggreg.png"

### 2.1.3 Other parameters --------------
# timestamp of the cyclone
idai_time <- resRoadContribLength$timestamp[136]

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

# Change the table format from the wide format to the long format since this simplifies handling in ggplot dramatically.
resHighway_long <- pivot_longer(resRoadContribLength, remainder:`highway=motorway`, names_to = "type", values_to = "length" )
resHighway_long$length <- resHighway_long$length / 1000 # convert to km


# Reorder the factor levels for nicer plotting
resHighway_long$type <- factor(resHighway_long$type,
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
pHighw <- ggplot(resHighway_long, mapping=aes(x=timestamp, y=length/1000, fill=type)) +
            geom_area(position="stack") +  
            xlab("") + 
            ylab("Length [1000 km]") +
            labs(title = "OSM contributions Mozambique",
                 subtitle = "Highway") +
        geom_vline(xintercept=as.numeric(idai_time),
                   linetype=4,
                   colour = "red") +
        geom_text(aes(x=idai_time, # timestamp of the cyclone
                      label="Cyclone impact",
                      y=20,
                      colour = "red"),
                  vjust = -10,
                  hjust = 1.1,
                  text=element_text(size=9)) +
          ggthemes::theme_economist_white(base_family="Verdana") +
          ggthemes::scale_fill_economist() +
          theme(legend.text = element_text(size = 9),
                legend.title=element_blank(),
                axis.title.y = element_text(margin = unit(c(0, 3, 0, 0), "mm")),
                axis.title.x = element_blank())


## 3.2 Plot Health sites ---------------

# Change the table format from the wide format to the long format since this simplifies handling in ggplot dramatically.
resHs_long <- pivot_longer(resHs, primaryCount:non_primaryCount, names_to = "type", values_to = "count" )

# Reorder the factor levels for nicer plotting
resHs_long$type <- factor(resHs_long$type, 
                          levels = c("primaryCount", "non_primaryCount"),
                          labels = c("Primary", "Non primary"))


# Plot the Health sites
pHs <- ggplot(resHs_long, mapping=aes(x=timestamp, y=count, fill=type)) +
          geom_area(position="stack") + 
          xlab("") + 
          ylab("Count") +
          labs(subtitle = "Health facilities") + 
        geom_vline(xintercept=as.numeric(idai_time),
                   linetype=4) +
        geom_text(aes(x=idai_time,
                      label="Cyclone Idai",
                      y=20,
                      colour = "red"),
                  vjust = -10,
                  hjust = 1.1,
                  text=element_text(size=11)) +
        ggthemes::theme_economist_white(base_family="Verdana", base_size = 7) + 
        ggthemes::scale_fill_economist() + 
        theme(legend.text = element_text(size = 9),
              legend.title=element_blank(),
              plot.title = element_blank(),
              axis.title.y = element_text(margin = unit(c(0, 3, 0, 0), "mm")),
              axis.title.x =  element_blank())


## 3.3 Plot together and save ------------

# plot together
ggarrange(pHighw, pHs, ncol=1)

# export to png
ggsave(contribution_png_path)


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

p1 <- resActiveUsersHighw %>%
        ggplot(mapping=aes(x=toTimestamp, y=countHighwayUsers)) +
        geom_area(alpha=.7,
                  fill = "#7C260A") +
        xlab("") +
        ylab("Active users") +
        labs(title = "OSM active users Mozambique", subtitle = "Highway") +
         geom_vline(xintercept=as.numeric(idai_time),
                    linetype=4,
                    colour = "red") +
         geom_text(aes(x=idai_time,label="Cyclone impact", y=20, colour = "red"),
                   vjust = -10,
                   hjust = 1.1,
                   text=element_text(size=7)) +
        ggthemes::theme_economist_white(base_family="Verdana", base_size = 7) + ggthemes::scale_fill_economist() +
        theme(axis.title.y = element_text(margin = unit(c(0, 3, 0, 0), "mm")))

                                                

## 4.2 Plot users activity on Amenity ---------------
# Change the table format from the wide format to the long format since this simplifies handling in ggplot dramatically.
resActiveAmeni_long <- pivot_longer(resActiveUsersAmenity, remainder:`amenity=doctors`, names_to = "type", values_to = "countAmenityUsers" )
                                               
# Reorder the factor levels for nicer plotting
resActiveAmeni_long$type <- factor(resActiveAmeni_long$type,
                                   levels = c("amenity=doctors",
                                              "amenity=clinic",
                                              "amenity=hospital",
                                              "remainder"),
                                   labels = c("Doctors",
                                              "Clinic",
                                              "Hospital",
                                              "Other"))
                                                
p2 <- resActiveAmeni_long %>% 
        ggplot(mapping=aes(x=toTimestamp, y=countAmenityUsers, fill=type)) +
        geom_area(position="stack") + 
        xlab("") +
        ylab("Active users") +
        labs(subtitle = "Amenity") + 
        geom_vline(xintercept=as.numeric(idai_time),
                   linetype=4,
                   colour = "red") +
        ggthemes::theme_economist_white(base_family="Verdana", base_size = 7) +
        ggthemes::scale_fill_economist() +
        theme( legend.text = element_text(size = 7),
               legend.title=element_blank(),
               axis.title.y = element_text(margin = unit(c(0, 3, 0, 0), "mm")),
               axis.title.x =  element_blank())
           

## 4.3 Plot together and save ------------

# plot together
ggarrange(p1, p2, ncol=1)

# export to png
ggsave(activity_png_path)





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




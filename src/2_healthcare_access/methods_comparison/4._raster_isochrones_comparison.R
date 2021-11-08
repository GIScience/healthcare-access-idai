

compareAccessMethods <- function (profile, scope, instance, threshold){

          # 2 Parameters ---------------------------------
          
          ## 2.2 Set the path of the input and output files -------------------         
          ### input: raster accessibility
          raster_path <- paste0("data/results/",profile,"/raster/cat_",scope,"_",instance,"_raster_access.tif")
          
          ### input: isochrones accessibility
          isochrones_path <- paste0("data/results/",profile,"/isochrones/10min_",scope,"_",instance,"_isochrones.gpkg")
          
          ### other inputs:
          impact_area_path <- "data/download/impact_area/impact_area.gpkg"
          
          
          ### output
          png_path <-paste0("data/results/",profile,"/raster/cat_",scope,"_access_raster_isochrones_map.png")
          
          
          ## 2.3 read the input data-------------------
          access_raster <- raster(raster_path)  
          access_isochrones <- st_read(dsn = isochrones_path, layer = "isochrones_populated")
          impact_area <- st_read(dsn = impact_area_path, layer = "simpl_impact_area")
          impact_area$label <- "Flooded area" # add a label attribute
          boundary <- st_read(dsn = "data/download/boundary/MOZ_adm0_boundary.gpkg", layer = "MOZ_adm0_boundary")
          
          
          ## 2.4 Set the visualisation parameters-------------------
          tmap_options(max.raster = c(plot = 1e7, view = 1e8))
          tmap_mode("plot")
          
          ## 2.5 Retrieve the background maps-------------------
          impact_bbox <- st_bbox(impact_area)
          impact_bb_sf <- st_as_sfc(st_bbox(impact_area))
          moz_bbox_sf <- st_bbox(boundary) %>% st_as_sfc() %>% st_as_sf()
          basemap_moz <- read_osm(boundary, type = "osm", zoom = 7)
          
          ## 2.6 Symbology parameters ----------------------
          ### isochrones parameters
          #### adjust the labels according to profile
          if (profile== "driving-car"){
            unit <- "min"
            labels_raster <- c(paste0("< ", threshold*10, unit, " - raster-based only"),
                               paste0("> ", threshold*10,unit))
            labels_iso<- paste0("< ", threshold*10, unit," - both method")
          } else if (profile== "foot-walking"){
            unit <- "h"
            labels_raster <- c(paste0("< ", threshold, unit, " - raster-based only"),
                               paste0("> ", threshold,unit))
            labels_iso<- paste0("< ", threshold, unit," - both method")
          }
          
          # breaks_raster <- c(0,1.5,2) # breaks for 
          # palette_raster <- c("#1a6193","#f8ce93")

          breaks_raster <- c(0,0.1,1.1,2) # breaks for
          palette_raster <- c("#FFFFFF","#1a6193","#f8ce93")
          
          # 3 Data preprocessing ---------------------------------
           
          if (profile== "driving-car"){
            # convert isochrones to one only multipolygon for time range < 60min (threshold)
            access_iso <- filter(access_isochrones, value <= threshold*600) %>% summarise()
            #categorize the raster to under and higher than 60min
            matrix_recl <- rbind(c(0, threshold*10,1),
                                 c(threshold*10-1, 99999,2))
            access_raster <- reclassify(access_raster, matrix_recl) %>% st_as_stars()
            
          } else if (profile== "foot-walking"){
            # convert isochrones to one only multipolygon for time range < 6h (threshold)
            access_iso <- filter(access_isochrones, value <= threshold*3600) %>% summarise()
            #categorize the raster to under and higher than 6h
            matrix_recl <- rbind(c(0, threshold*60,1),
                                 c(threshold*60-1, 99999,2))
            access_raster <- reclassify(access_raster, matrix_recl) %>% st_as_stars()
          
          }
            
          # 4 Elements setup ---------------------------------
          
          ## 4.1 Maps ----------------------------
          
          ### Map of non-flooded area                                    
          access_map <- tm_shape(basemap_moz,
                                  bbox = impact_bbox) +
                           tm_rgb(alpha = 0.8) +
                       tm_shape(access_raster) +
                           tm_raster(palette = palette_raster,
                                     #style = "cat",
                                     alpha = 0.8) +
                        tm_shape(access_iso) +
                            tm_fill("#9e1e1a",
                                    border.alpha = 0,
                                    alpha = 0.9) +
                        tm_scale_bar(position = c("RIGHT","BOTTOM"),
                                     breaks = c(0,100,200),
                                     bg.color = "#ffffff",
                                     bg.alpha = 0.6,
                                     text.size = 6)
                         tm_layout(legend.show = FALSE,
                                   bg.color="#242424")
          
          
          
          
          ## 4.2 Side elements setup----------------------------
          ### creation a map of localisation
          loc_map <- tm_shape(basemap_moz) +
                        tm_rgb(alpha = 0.5) +
                      tm_shape(boundary) +
                        tm_borders(lwd= 8) +
                      tm_shape(impact_bb_sf) +
                        tm_polygons(col="#ff0000",
                                    alpha=0.3)
            
          
          ### legend for isochrones
          # set a level to order the legend adequatly
          leg_map <- tm_shape(access_iso) +
                      tm_fill("#9e1e1a",
                              border.alpha = 0,
                              alpha = 0.9,
                              labels = labels_iso,
                              title = "Access time according to method") +
                      tm_add_legend("fill",
                                    col = "#9e1e1a",
                                    border.alpha = 0,
                                    alpha = 0.9,
                                    labels = labels_iso,
                                    title = "Access time according to method") +
                      tm_add_legend("fill",
                                    col = palette_raster[2],
                                    labels = labels_raster[1],
                                    alpha = 0.6,
                                    title = "") +
                      tm_add_legend("fill",
                                    col = palette_raster[3],
                                    labels = labels_raster[2],
                                    alpha = 0.6,
                                    title = "") +
                      tm_layout(legend.only = TRUE,
                                legend.text.size = 10,
                                legend.title.size = 15)
          
          
          
          # 4. Plot the elements together --------------------
          
          png(filename = png_path,
              width = 7000,
              height= 5000,
              units = "px")
          
          vp_layout <- viewport(layout=grid.layout(2, 1, heights = unit(c(0.05,0.95),"npc")))
          pushViewport(vp_layout)
              # plot the main title
              vp_title <- viewport(layout.pos.row = 1,
                                   layout.pos.col = 1)
              # grid.text(paste0("Access to ", scope, " health facilities by ", profile, " - Method comparison"),
              grid.text(paste0("Access to health facilities by ", profile, " - Method comparison"),
                        gp=gpar(fontsize=150,
                                fontface=2),
                        vp = vp_title)
              
              # plot the elements
              vp_element <- viewport(layout=grid.layout(1, 2, widths = unit(c(0.7,0.3),"npc")),
                                 layout.pos.row=2,
                                 layout.pos.col=1)
              pushViewport(vp_element)
              
                  # plot the main map
                  vp_map <- viewport(layout.pos.row=1,
                                     layout.pos.col=1)
                  print(access_map, vp = vp_map)
                  
                  # plot the side elements to the right
                  vp_legend <- viewport(layout=grid.layout(6, 4),
                                        layout.pos.row=1,
                                        layout.pos.col=2)
                  pushViewport(vp_legend)
                      # plot the localisation map
                      vp_loc_map <- viewport(layout.pos.row=1:2,
                                             layout.pos.col=1:4)
                      print(loc_map, vp = vp_loc_map)
                      
                      # plot the isochrone legend
                      vp_leg_map <- viewport(layout.pos.row=3:4,
                                             layout.pos.col=1:4)
                      print(leg_map, vp =vp_leg_map)
          
                      # plot the sources
                      vp_source <- viewport(layout.pos.row=5:6,
                                            layout.pos.col=1)
                      grid.text("Data source : OpenStreetMap contributors\nBase map : OpenStreetMap Standard\nFlooded area : UNOSAT and WFP\nIsochrones generated by OpenRouteService\nRaster access based on friction layer\nby Malaria Atlas Project",
                                gp=gpar(fontsize=70),
                                just = c(0,0.5),
                                vp = vp_source)
                      upViewport()
                  upViewport()
          upViewport()
          dev.off()

}

# compareLossMethods <- function (profile, scope, instance, threshold){
compareLossMethods <- function (profile, instance, threshold){
            
            # 2 Parameters ---------------------------------
            
            ## 2.2 Set the path of the input and output files -------------------         
            ### input: raster accessibility
            raster_path <- paste0("data/results/",profile,"/raster/cat_raster_access_loss.tif")
            
            ### input: isochrones accessibility
            # isochrones_path <- paste0("data/results/",profile,"/",scope,"/access_loss.gpkg")
            isochrones_path <- paste0("data/results/",profile,"/isochrones/10min_access_loss.gpkg")
            
            ### other inputs:
            impact_area_path <- "data/download/impact_area/impact_area.gpkg"
            
            
            ### output
            png_path <-paste0("data/results/",profile,"/raster/cat_loss_raster_isochrones_map.png")
            
            
            ## 2.3 read the input data-------------------
            loss_raster <- raster(raster_path)  
            loss_isochrones <- st_read(dsn = isochrones_path, layer = "access_loss")
            impact_area <- st_read(dsn = impact_area_path, layer = "simpl_impact_area")
            impact_area$label <- "Flooded area" # add a label attribute
            boundary <- st_read(dsn = "data/download/boundary/MOZ_adm0_boundary.gpkg", layer = "MOZ_adm0_boundary")
            
            
            ## 2.4 Set the visualisation parameters-------------------
            tmap_options(max.raster = c(plot = 1e7, view = 1e8))
            tmap_mode("plot")
            
            ## 2.5 Retrieve the background maps-------------------
            impact_bbox <- st_bbox(impact_area)
            impact_bb_sf <- st_as_sfc(st_bbox(impact_area))
            moz_bbox_sf <- st_bbox(boundary) %>% st_as_sfc() %>% st_as_sf()
            basemap_moz <- read_osm(boundary, type = "osm", zoom = 7)
            
            ## 2.6 Symbology parameters ----------------------
            ### isochrones parameters
            #### adjust the labels according to profile
            if (profile== "driving-car"){
              unit <- "min"
              labels_raster <- c(paste0("< ", threshold*10, unit, " - raster-based only"),
                                 paste0("> ", threshold*10,unit))
              labels_iso<- paste0("< ", threshold*10, unit," - both method")
            } else if (profile== "foot-walking"){
              unit <- "h"
              labels_raster <- c(paste0("< ", threshold, unit, " - raster-based only"),
                                 paste0("> ", threshold,unit))
              labels_iso<- paste0("< ", threshold, unit," - both method")
            }
            
            # breaks_raster <- c(0,1.5,2) # breaks for 
            # palette_raster <- c("#1a6193","#f8ce93")
            
            breaks_raster <- c(0,0.1,1.1,2) # breaks for
            palette_raster <- c("#FFFFFF","#1a6193","#f8ce93")
            
            # 3 Data preprocessing ---------------------------------
            
            if (profile== "driving-car"){
              # convert loss isochrones to one only multipolygon
              loss_iso <- loss_isochrones %>% summarise()
             
            } else if (profile== "foot-walking"){
              # convert isochrones to one only multipolygon for time range < 6h (threshold)
              loss_iso <- loss_isochrones %>% summarise()
              
              loss_raster <- loss_raster %>% st_as_stars()
            }
            
            # 4 Elements setup ---------------------------------
            
            ## 4.1 Maps ----------------------------
            
            ### Map of non-flooded area                                    
            loss_map <- tm_shape(basemap_moz,
                                   bbox = impact_bbox) +
                        tm_rgb(alpha = 0.8) +
                        tm_shape(loss_raster) +
                        tm_raster(palette = palette_raster,
                                  #style = "cat",
                                  alpha = 0.8) +
                        tm_shape(loss_iso) +
                        tm_fill("#9e1e1a",
                                border.alpha = 0,
                                alpha = 0.9) +
                        tm_scale_bar(position = c("RIGHT","BOTTOM"),
                                     breaks = c(0,100,200),
                                     bg.color = "#ffffff",
                                     bg.alpha = 0.6,
                                     text.size = 6)
                      tm_layout(legend.show = FALSE,
                                bg.color="#242424")
            
            
            
            
            ## 4.2 Side elements setup----------------------------
            ### creation a map of localisation
            loc_map <- tm_shape(basemap_moz) +
                        tm_rgb(alpha = 0.5) +
                        tm_shape(boundary) +
                        tm_borders(lwd= 8) +
                        tm_shape(impact_bb_sf) +
                        tm_polygons(col="#ff0000",
                                    alpha=0.3)
            
            
            ### legend for isochrones
            # set a level to order the legend adequatly
            leg_map <- tm_shape(loss_iso) +
                        tm_fill("#9e1e1a",
                                border.alpha = 0,
                                alpha = 0.9,
                                labels = labels_iso,
                                title = "Access loss according to method") +
                        tm_add_legend("fill",
                                      col = "#9e1e1a",
                                      border.alpha = 0,
                                      alpha = 0.9,
                                      labels = labels_iso,
                                      title = "Access loss according to method") +
                        tm_add_legend("fill",
                                      col = palette_raster[2],
                                      labels = labels_raster[1],
                                      alpha = 0.6,
                                      title = "") +
                        tm_add_legend("fill",
                                      col = palette_raster[3],
                                      labels = labels_raster[2],
                                      alpha = 0.6,
                                      title = "") +
                        tm_layout(legend.only = TRUE,
                                  legend.text.size = 10,
                                  legend.title.size = 15)
            
            
            
            # 4. Plot the elements together --------------------
            
            png(filename = png_path,
                width = 7000,
                height= 5000,
                units = "px")
            
            vp_layout <- viewport(layout=grid.layout(2, 1, heights = unit(c(0.05,0.95),"npc")))
            pushViewport(vp_layout)
                    # plot the main title
                    vp_title <- viewport(layout.pos.row = 1,
                                         layout.pos.col = 1)
                    # grid.text(paste0("Access to ", scope, " health facilities by ", profile, " - Method comparison"),
                    grid.text(paste0("Loss of access to health facilities by ", profile, " - Method comparison"),
                              gp=gpar(fontsize=150,
                                      fontface=2),
                              vp = vp_title)
                    
                    # plot the elements
                    vp_element <- viewport(layout=grid.layout(1, 2, widths = unit(c(0.7,0.3),"npc")),
                                           layout.pos.row=2,
                                           layout.pos.col=1)
                    pushViewport(vp_element)
                    
                          # plot the main map
                          vp_map <- viewport(layout.pos.row=1,
                                             layout.pos.col=1)
                          print(loss_map, vp = vp_map)
                          
                          # plot the side elements to the right
                          vp_legend <- viewport(layout=grid.layout(6, 4),
                                                layout.pos.row=1,
                                                layout.pos.col=2)
                          pushViewport(vp_legend)
                                    # plot the localisation map
                                    vp_loc_map <- viewport(layout.pos.row=1:2,
                                                           layout.pos.col=1:4)
                                    print(loc_map, vp = vp_loc_map)
                                    
                                    # plot the isochrone legend
                                    vp_leg_map <- viewport(layout.pos.row=3:4,
                                                           layout.pos.col=1:4)
                                    print(leg_map, vp =vp_leg_map)
                                    
                                    # plot the sources
                                    vp_source <- viewport(layout.pos.row=5:6,
                                                          layout.pos.col=1)
                                    grid.text("Data source : OpenStreetMap contributors\nBase map : OpenStreetMap Standard\nFlooded area : UNOSAT and WFP\nIsochrones generated by OpenRouteService\nRaster access based on friction layer\nby Malaria Atlas Project",
                                              gp=gpar(fontsize=70),
                                              just = c(0,0.5),
                                              vp = vp_source)
                          upViewport()
                    upViewport()
            upViewport()
            dev.off()
}

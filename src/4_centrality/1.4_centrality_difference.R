# 0.1 Libraries ---------------------------------
library(tidyverse) # get data wrangling functions
library(sf) # spatial stuff
sf_use_s2(FALSE) # last version of sf uses s2 instead of GEOS for ellipsoidal coordinates but it presents some bugs so we disactivate it:https://github.com/r-spatial/sf/issues/1649
library(httr)
library(tictoc) # generate timestamps
library(jsonlite) # manage JSON format
library(sfnetworks)
library(tidygraph)
library(raster)
library(tmap) # 
library(tmaptools)
library(OpenStreetMap)
library(grid)
library(gridExtra)
library(classInt)
library(raster)
library(doParallel)
library(png)
library(ggpubr)
library(caret)


# ---
# start timestamp forthe full script
tic("Total")
Sys.sleep(1)
# ---

# 0.2 - User defined parameters ---------------


profile <- "driving-car"# choose between "driving-car" and "foot-walking"
focus_area <- "Mozambique" # choose between "Dondo", "Makambine","Mocuba", "Tica" and "Quelimane"
scope <- "all" # choose between "primary", "non_primary" or "all"
directionality <- "bi" # choose between "bi" and "uni"
indicator <- "tc" # choose between "tc" and "pc"
tc_cluster <- 20

# 0.3 - Repository creation
dir.create("data")
dir.create("data/results")
dir.create(paste0("data/results/",profile ))
dir.create(paste0("data/results/",profile,"/centrality"))
dir.create(paste0("data/results/",profile,"/centrality/",focus_area))

# # 0.4 - Bbox definition
# if (focus_area == "Dondo"){
#   # bbox <- st_bbox(c(xmin = 34.6042, xmax = 34.8971, ymax = -19.3455, ymin = -19.6876), crs = st_crs(4326))  bbox_ors <- paste0('[[34.6042,-19.6876],[34.8971,-19.3455]]')
#   bbox <- st_bbox(c(xmin = 34.58545, ymin = -19.69468, xmax = 34.89867, ymax = -19.41471), crs = st_crs(4326))
# } else if (focus_area == "Tica"){
#   bbox <- st_bbox(c(xmin = 34.2622, ymin = -19.4413, xmax = 34.4931, ymax = -19.2750), crs = st_crs(4326))
# } else if (focus_area == "Quelimane"){
#   bbox <- st_bbox(c(xmin = 36.4904, ymin = -17.9445, xmax = 37.1729, ymax = -17.5288), crs = st_crs(4326))
# } else if (focus_area == "Makambine"){
#   bbox <- st_bbox(c(xmin = 33.8940, ymin = -19.8453, xmax = 34.1978, ymax = -19.6399), crs = st_crs(4326))
# } else if (focus_area == "Mocuba"){
#   bbox <- st_bbox(c(xmin = 36.9023, ymin = -16.8857, xmax = 37.1633, ymax = -16.7064), crs = st_crs(4326))
# } else if (focus_area == "Mozambique"){
#   bbox <- st_bbox(c(xmin = 30.21559, ymin = -26.86804, xmax = 40.83752, ymax = -10.47377), crs = st_crs(4326))
# } else if (focus_area == "test"){
#   bbox <- st_bbox(c(xmin = 34.5221, ymin = -19.6724, xmax = 35.0588, ymax = -19.3175), crs = st_crs(4326))
# }

impact_bbox <- st_bbox(c(xmin = 33.532, ymin = -20.161, xmax = 34.914, ymax = -18.645), crs = st_crs(4326))
dondo_bbox <- st_bbox(c(xmin = 34.58545, ymin = -19.69468, xmax = 34.89867, ymax = -19.41471), crs = st_crs(4326))


# # 0.5 - Input path
# impact_area_path <- "data/download/impact_area/impact_area.gpkg"
# impact_area <- st_read(dsn = impact_area_path, layer = "simpl_impact_area")

# 0.6 - Output path
network_path <- paste0("data/results/",profile,"/centrality/",focus_area,"/network.gpkg") 
tc_path <- paste0("data/results/",profile,"/centrality/",focus_area,"/",tc_cluster,"km_",scope,"_centrality.gpkg")



# 1 ---------

normal_tc <- st_read(dsn = tc_path, layer = paste0(directionality,"direct_normal_tc")) %>% st_crop(impact_bbox)
impact_tc <- st_read(dsn = tc_path, layer = paste0(directionality,"direct_impact_tc")) %>% st_crop(impact_bbox)

# normal_tc <- st_read(dsn = tc_path, layer = paste0(directionality,"direct_normal_tc")) %>% st_crop(dondo_bbox)
# impact_tc <- st_read(dsn = tc_path, layer = paste0(directionality,"direct_impact_tc")) %>% st_crop(dondo_bbox)

  difference_left_normal <- st_join(normal_tc, impact_tc, join = st_equals, left=TRUE)
  colnames(difference_left_normal) <- c("Id_normal", "tc_normal", "pc_normal", "Id_impact","tc_impact","pc_impact","geom")
  difference_left_normal[is.na(difference_left_normal)] <- 0
  
  difference_left_impact <- st_join(impact_tc, normal_tc, join = st_equals, left=TRUE)
  colnames(difference_left_impact) <- c("Id_impact","tc_impact","pc_impact", "Id_normal", "tc_normal", "pc_normal","geom")
  difference_left_impact[is.na(difference_left_impact)] <- 0
  
  difference <- rbind(difference_left_normal, difference_left_impact) %>% unique()
  
  
  difference$tc_diff <- difference$tc_impact - difference$tc_normal
  difference$pc_diff <- difference$pc_impact - difference$pc_normal

# st_write(difference, dsn= tc_path, layer = "direct_difference_tc", append = F)

img <- readPNG("background.png")

# ggplot(difference, aes(tc_impact, tc_normal)) +
#   background_image(img) +
#   geom_point()
max <- max(difference$tc_normal)

arrows <-  tibble(
            x1 = c(max*0.35, max*0.65),
            y1 = c(max*0.65, max*0.35),
            x2 = c(max*0.1, max*0.9),
            y2 = c(max*0.9, max*0.1)
          )

ggplot(difference, aes(tc_normal, tc_impact)) +
 # background_image(img) +
  ylim(0,max) +
  xlim(0,max) +
  geom_point(size = 0.5,
             color = "483737ff") +
  labs(x="Targeted centrality in normal situation",
       y="Targeted centrality under flooded situation") +
  geom_curve(data = arrows,
             aes(x = x1, y = y1, xend = x2, yend = y2),
             arrow = arrow(length = unit(0.15, "inch")),
             size = 1,
             color = "gray20",
             curvature = 0) +
  annotate("text", x = 250, y = 600, size = 4, color = "gray20", lineheight = .9,
    label = glue::glue("Back-up\nroads")) +
  annotate("text", x = 620, y = 200, size = 4, color = "gray20", lineheight = .9,
               label = glue::glue("Critical\nroads")) 
  





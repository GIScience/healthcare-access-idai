
# 1. CRAN packages ----------

# Package names
packages <- c("ggplot2",
              "readxl",
              "tidyverse", # get data wrangling functions
              "sf", # spatial stuff
              "raster",
              "tidyverse", # get data wrangling functions
              "tictoc", # timestamps
              "stars", # raster to vector
              "osmextract", # download the .osm.pbf file from one of the official database
              "rmapshaper", # library to simplify polygons
              "sfheaders", 
              "rjson",
              "exactextractr",
              "polylabelr",
              "tmap",
              "tmaptools",
              "OpenStreetMap",
              "grid",
              "gridExtra",
              "knitr",
              "ggplot2",
              "doParallel",
              "gdistance",
              "httr",
              "jsonlite", # manage JSON format
              "classInt",
              "tidygraph",
              "sfnetworks",
              "RCurl",
              "geojsonio",
              "RJSONIO",
              "units",
              "geojsonsf",
              "ggpubr",
              "caret") # for the arrangement of multiple ggplot objects

# Install packages not yet installed
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}

# 2 remote packages ------------

## openrouteservice
installed_ors <- "openrouteservice" %in% rownames(installed.packages())
if (any(installed_ors == FALSE)) {
  remotes::install_github("GIScience/openrouteservice-r")
}

## rgeoboundaries
installed_ors <- "rgeoboundaries" %in% rownames(installed.packages())
if (any(installed_ors == FALSE)) {
  remotes::install_github("wmgeolab/rgeoboundaries")
}




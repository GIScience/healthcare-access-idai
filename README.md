# Healthcare accessibility and road criticality during floods disaster

Analysis of the impact of disasters on accessing health facilities by population and assessment of the road criticality in delivering the access. This analysis was done using the case study of floods induced by the cyclone Idai in Mozambique in march-april 2019.

The analysis was developped by Sami Petricola with the support of Marcel Reinmuth and used for a scientific publication.

# Content
-  [System requirements](#System-requirements)
-  [Installation](#Installation)
    - [R scripts](#R-scripts)
        - [Dependencies](#Dependencies)
    - [Osmosis](#Osmosis)
    - [Docker](#Docker)
- [Folder structure](#Folder-structure) 
- [**I. Data Prepation**](#I.-Data-Preparation)
    - [1. Data download](#1.1-Data-download)
        - [1.1 Main datasets](#1.1-Main-datasets)
        - [1.2 Preparation of the flood data](#1.2-Preparation-of-the-flood-data)
    - [2. Create a .osm.pbf file](#1.2-Create-a-.osm.pbf-file)
- [**II. Healthcare accessibility analysis**](#II.-Healthcare-accessibility-analysis)
    - [Vector-based analysis](#Vector-based-analysis)
        - [1. Launch ORS instances](#1.-Launch-ORS-instances)
        - [2. Isochrone processing](#2.-Isochrone-processing)
    - [Raster-based analysis](#Vector-based-analysis)
 - [**III. Centrality analysis**](#III.-Centrality-analysis)
    - [1. Betweeness centrality](#1.-Betweeness-centrality)
    - [2. _Targeted_ centrality](#2.-_Targeted_-centrality)
    - [3. Indicator comparison](#3.-_Indicator_-comparison)
- [**IV. OSM data completeness analysis**](#IV.-OSM-data-completeness-analysis)
    - [1. Aggregation at country level](#1.-Aggregation-at-country-level)
    - [2. Disaggregation between flooded and non flooded regions](#2.-Disaggregation-between-flooded-and-non-flooded-regions)


</br>
</br>

# System requirements

### Scripts have been tested on the following systems
|Versions|Linux|MacOS|
|---|---|---|
|OS|Ubuntu 20.04.2|11.3|
|R|4.0.5|4.0.5|
|GDAL|3.2.1|3.3.0|
|GEOS|3.9.0|3.9.1|
|PROJ|7.2.1|8.0.1|

</br>

**WARNING:** 
Make sure to use a version of GEOS > 3.9

Some issues on geometry operations (st_difference) were detected with the use of older libraries which don't include OverlayNG in JTS. It was implemented in JTS version 1.18.

</br>

## Performance 

An estimation of the time performance can be found [here](../docs/README.md)

# Installation

Clone git repository:  
```
git clone https://gitlab.gistools.geog.uni-heidelberg.de/giscience/disaster-tools/health_access/local_ors_accessibility.git
```

</br>

## Directory structure
Running the scripts will create automatically the required folders

`local_ors_accessibility`: working directory
- `docs`: several documentations about the requirements and running time estimation
- `src`: contains subfolders with the R script to be used according to the process steps
- `data` : folder automatically created to store the data files
    - `download`: store all the input files downloaded by the script
    - `results`: store all the output of the scripts
        - `profile1` (ie. driving-car): store the results of the analysis of the defined profile
            - `isochrones`: output of the vector-based accessibility analysis
            - `raster`: output of the raster-based accessibility analysis
            - `centrality`: output of the centrality analysis
        - `profile2`: .....
- `local-ors`: directory to be used by the ORS docker container
    - `ors-impact`: directory of the ORS instance with the osm network impacted by the floods
        - `conf`: configuration of the ORS instance
        - `data`: data used by the ORS. Including the osm.pbf file with the network to be used.
    - `ors-normal` : directory of the ORS instance with the normal osm network
        - same structure as `ors-impact`

</br>

## R 
- Start R in the `local_ors_accessibility` working directory
```
cd local_ors_accessibility
```


### Packages
Install the R packages with the script [install.packages.R](../src/install.packages.R):

[rgeoboundaries](https://github.com/wmgeolab/rgeoboundaries), [tidyverse](https://www.tidyverse.org/), [sf](https://r-spatial.github.io/sf/), [httr](https://cran.r-project.org/web/packages/httr/index.html), [geojsonsf](https://cran.r-project.org/web/packages/geojsonsf/index.html), [openrouteservice](https://github.com/GIScience/openrouteservice), [rjson](https://cran.r-project.org/web/packages/rjson/index.html), [jsonlite](https://cran.r-project.org/web/packages/jsonlite/vignettes/json-aaquickstart.html), [raster](https://cran.r-project.org/web/packages/raster/index.html), [osmextract](https://github.com/ropensci/osmextract) , [rmapshaper](https://cran.r-project.org/web/packages/rmapshaper/index.html), [sfheaders](https://cran.r-project.org/web/packages/sfheaders/index.html), [stars](https://github.com/r-spatial/stars/), [exactextractr](https://cran.r-project.org/web/packages/exactextractr/readme/README.html), [tictoc](https://cran.r-project.org/web/packages/tictoc/index.html), [OpenStreetMap](https://cran.r-project.org/web/packages/OpenStreetMap/index.html), [tmap](https://cran.r-project.org/web/packages/tmap/vignettes/tmap-getstarted.html), [tmaptools](https://cran.r-project.org/web/packages/tmaptools/index.html), [grid](https://www.rdocumentation.org/packages/graphics/versions/3.6.2/topics/grid), [gridExtra](https://cran.r-project.org/web/packages/gridExtra/index.html), [polylabelr](https://cran.r-project.org/web/packages/polylabelr/polylabelr.pdf), [tidygraph](https://tidygraph.data-imaginist.com/index.html), [sfnetworks](https://luukvdmeer.github.io/sfnetworks/index.html), [doParallel](https://cran.r-project.org/web/packages/doParallel/index.html)


## Other dependencies
Install the dependency:
- [Osmosis](https://wiki.openstreetmap.org/wiki/Osmosis#Example_usage)

</br>

## Docker
Install docker.

More information can be encountered [here](https://github.com/GIScience/openrouteservice/wiki)

# **I. Data preparation**
</br>

## 1. Data download

### 1.1 Main datasets

#### **_Objective:_**
Download and process all the input datasets required for the analysis.

Note: the flood data requires more processing and therefore is presented in the following section

</br>

#### **_Boundaries_**
The Mozambique boundaries are downloaded from geoboundary and will be used by different scripts to get a bounding box, to retrieve OSM data, etc.
#### **_OSM Health facilities_**
We use the Ohsome API to download the health facilities from OSM.
We defined 3 scopes of healthcare level:

- primary
- non_primary (secondary)
- all

#### **_World population_**
We download the population constrained estimation done by [worldpop](https://www.worldpop.org/methods/top_down_constrained_vs_unconstrained)

</br>

**_Parameters:_**

Some parameters **MUST** be set manually.

Open the scripts and adjust the 2.1 section accordingly:
- `country`: the country of the area of interest, it must be introduced as the ISO code alpha 3. By default it is set to `MOZ` for the Mozambique cyclone Idai simulation.
- `scope`: level of healthcare facilities, choose between `primary`, `non_primary` and `all`

</br>

#### **_Script:_**
- [1.1_datapreparation.R](../src/1_data_preparation/1.1_datapreparation.R) : all datasets downloaded and processed will be stored in the appropriate folders

#### **_Sub-script:_**
- [1.0_download_ohsome.R](../src/1_data_preparation/1.0_download_ohsome.R) : functions to launch request to the Ohsome API

</br>
</br>

### 1.2 Preparation of the flood data
#### **_Disaster event images_**
There are 3 different datasets with open access showing the extent of the flooded areas of Idai Cyclon:

- **Copernicus Emergency Management Service:** 

    The vector files of the delineation of flooded area can be downloaded [here](https://emergency.copernicus.eu/mapping/list-of-components/EMSR348/DELINEATION/ALL). 

    This dataset presents 2 limitations: the impossibility to include the download into a script and the limited extent of the region included

- **ARC - African Risk Capacity / WFP:** 

    The raster file of the flooded area has been published in HDX by WFP (World Food Program) and can be downloaded [here](https://data.humdata.org/dataset/mozambique-flood-detected-waters-cyclone-idai). 

    This dataset has been provided by the African Risk Capacity which publish some information about the dataset [here](https://www.africanriskcapacity.org/wp-content/uploads/2019/06/ARC_AFMR_SouthernAfrica_FloodUpdate04_March2019_EN_20190330.pdf).

    Dataset published : 21 March 2019

    Data detection: 12-20 March 2019 (to be confirmed)

    Technology used : natural microwave radiation, details [here](https://www.africanriskcapacity.org/product/river-flood/)

    Resolution: 90 m

- **UNOSAT - UN Operational Satellite Applications Programme ([website](https://www.unitar.org/maps/unosat-rapid-mapping-service)) :** 

    The vector files of the flooded area has been published in HDX and can be downloaded [here](https://data.humdata.org/dataset/cumulative-satellite-detected-waters-extent-13-26-march-2019-over-sofala-province-mozambique) or [here](https://data.humdata.org/dataset/unosat-analysis-on-floods-in-mozambique-march-2019). 

    Dataset published : 26 March 2019

    Data detection: 13-14-19-20-26 March 2019

    Technology used : Sentinel-1 Imagery 
    
    Resolution: 10 m

 After visual analysis, we decided to use UNOSAT and ARC/WFP dataset due to the larger geographical coverage. Moreover, both datasets can be downloaded within a script.

</br>

#### **_Scripts:_**
- [1.2_floods_data_preparation.R](../src/1_data_preparation/1.2_floods_data_preparation.R) : run the script to download the datasets of the floods. The script will also combine them and write an ouptut geopackage file.

</br>
</br>


### 2. Create a .osm.pbf file
OpenRouteService is based on a osm.pbf file which stores the road network from OpenStreetMap.
We need to retrieve it from OpenStreetMap as well to alter a version to cut out the flooded area

</br>

**_Scripts:_**
- [2._create_impacted_pbf.R](../src/1_data_preparation/2._create_impacted_pbf.R) :
    - downloading of the osm.pbf and save it to be used in the ors-normal instance (../local-ors/ors-normal/data)
    - use the flooded area retrieved in step 1.1 to create a .poly file that will be used by osmosis to cut out the flooded area of osm.pbf. The flooded area is processed (crop, simplify, remove holes) to ensure a better performance of the osmium process. The output will used by the ors-impact instance (../local-ors/ors-impact/data)
    
    To know more on .poly files, read [here](https://wiki.openstreetmap.org/wiki/Osmosis/Polygon_Filter_File_Format)

    To know more on Osmosis tool, read [here](https://wiki.openstreetmap.org/wiki/Osmosis#Example_usage)

    **_Tip 1 :_** to check the processed flooded area created: you can visualise the layer "simpl_impact_area" created in the geopackage [impact_area.gpkg](../data/download/impact_area/impact_area.gpkg)
    
    **_Tip 2 :_** to check the poly file created: transform to geojson with python package [polygon2osm](https://github.com/ustroetz/polygon2osm), script [polygon2geojson.py](https://github.com/ustroetz/polygon2osm/blob/master/polygon2geojson.py)

     **_Tip 3 :_** to have an [acceptable performance](../docs/REAME.md) of the script, the .poly file created should not be bigger than 1 or 2Mb 

</br>
</br>

# **II. Healthcare accessibility analysis**

## Vector-based analysis

### **_Objective:_**
Isochrones of time to the closest health facility are calculated by the OpenRouteService API and then processed to retrieved the population included in each time range

## 1. Launch ORS instances
### **_Objective:_**
OpenRouteService API needs to be set up locally to run the analysis.
Two instances will be set:
1. "Normal" instance: considering the road network of OpenStreetMap
2. "Impact" instance: considering the road network of OpenStreetMap cutted out of the roads flooded by the cyclone

</br>

### 1.1 "normal" ORS instance

The launch of the ORS instance must be done in command line opened in `local_ors_accessibility` working directory:
```
cd local-ors/ors-normal

docker-compose up
```
### 1.2 "impact" ORS instance
The launch of the ORS instance must be done in command line opened in `local_ors_accessibility` working directory:
```
cd local-ors/ors-impact

docker-compose up
```

</br>

## 2. Isochrone processing
### **_Objective:_**
- This analysis will retrieve and process the isochrones from the ORS API endpoint.
- It will also compare the loss of accessibility to health facilities between flooded the situation and the normal situation
- Lastly, it will create the visualisations of the analysis results as .png images.


**_Parameters:_**

Some parameters **MUST** be set manually.

Open the scripts and adjust the 2.1 section accordingly:
- `country`: the country of the area of interest, it must be introduced as the ISO code alpha 3. By default it is set to `MOZ` for the Mozambique cyclone Idai simulation.
- `scope`: level of healthcare facilities, choose between `primary`, `non_primary` and `all`
- `profile`: refers to the transportation mean, choose between `foot-walking` and `driving-car`

**_Scripts:_**
- [isochrones_main.R](../src/2_healthcare_access/vector_analysis/isochrones_main.R) : the main script will call the functions from the sub scripts described below for an integrated process.


**_Sub-Scripts:_**
- [1.1_isochrones_local.R](../src/2_healthcare_access/vector_analysis/1.1_isochrones_local.R) : retrieve the isochrones from your local ORS instance according to your scope and profile.
- [1.2_dissolve_isochrones.R](../src/2_healthcare_access/vector_analysis/1.2_dissolve_isochrones.R) : dissolve together (union) all the isochrones of a same time range. If an area has access to 2 (or more) health facilities with conflicting different time range, the lower range will be considered.
- [1.3_difference_isochrones.R](../src/2_healthcare_access/vector_analysis/1.3_difference_isochrones.R) : differentiate the isochrones to avoird overlap between isochrones of different time range
- [1.4_population_estimates.R](../src/2_healthcare_access/vector_analysis/1.4_population_estimates.R): calculate (sum and proportion) of the population which is included in the iscohrones of each time range.
- [2.1_loss_analysis.R](../src/2_healthcare_access/vector_analysis/2.1_loss_analysis.R) :

    The difference between the 2 situations generates many virtual polygons which only represent the approximation of the edges of the isochrones created by the ORS API. To reduce this effect, we crop the loss_analysis to the bounding box of the floods and we use the "[pole of inaccessibility](https://github.com/mapbox/polylabel)" algorithm (bigger circle inscribed within the polygon) to filter out these polygons. The threshold to filter is set to 0.0005 degress (approx. 50 meters at the Mozambique latitudes)

- [2.2_loss_population_mask.R](../src/2_healthcare_access/vector_analysis/2.2_loss_population_mask.R) :

    Crop the population dataset to the extent of the polygon where loss of access was highlighted to be able to visualise it

</br>
</br>

## Raster-based analysis

### **_Objective:_**
- This analysis will perform the accessibility analysis based on a friction layer and raster-based approach.
- It will also compare the loss of accessibility to health facilities between flooded the situation and the normal situation.
- Moreover, it will perform a comparison of the results between the raster-based approach and the ORS-isochrones approach.
- Lastly, it will create the visualisations of the analysis results as .png images.

</br>

**_Parameters:_**

Some parameters **MUST** be set manually.

Open the scripts and adjust the 2.1 section accordingly:
- `country`: the country of the area of interest, it must be introduced as the ISO code alpha 3. By default it is set to `MOZ` for the Mozambique cyclone Idai simulation.
- `scope`: level of healthcare facilities, choose between `primary`, `non_primary` and `all`
- `profile`: refers to the transportation mean, choose between `foot-walking` and `driving-car`
- `threshold`: refers to the accessibility time, it will be used to compare the extent accessibility between raster-based and Isochrones-based methos. Choose an integer between `1` and `6`

</br>

**_Scripts:_**
- [raster_main.R](../src/2_healthcare_access/raster_analysis/raster_main.R)

</br>
</br>

# **III. Centrality analysis**

### **_Objective:_**
Evaluate the resilience of the road network by calculating a targeted edge centrality indicators:
- **_Targeted_ centrality** : count the occurence of a segment of the network in the shortest paths from a grid of population nucleus to some destinations points (healthcare facilities by default)

The analysis is based on OpenRouteService `Centrality` and `Export`API endpoints. Please refer to part [II.1. Launch ORS instances](#1.-Launch-ORS-instances) to get started with ORS.

<br>

**_Notes:_**

- The calculation is based on ORS API export endpoint and post-processed in R.

- The targeted centrality uses the population grid aggregated to a 1km2 grid to define the sources of the paths to calculate and will use the health facilities set in the `scope` parameter as destination.

- The size of the bounding box of the area of interest would impact the computation time. The bigger the bbox, the more paths will be calculated and, thus, increasing the computation time.

- The script generates several outputs:
    - `unidirectional` vs. `bidirectional` network, considering whether the network edges are unidrectional or bidirectional. With `bidirectional` the centrality score will not take into account the direction of the path on the segment. With `unidirectional` the centrality score does take into account the direction, thus, if a segement is used by paths in both direction, the segment will be considered as 2 different segments with 2 differnet scores.
    - `targeted centrality` vs. `populated centrality`: the targeted centrality is an indicator inspired from the betweenness centrality by counting the occurence of the segment in the shortest paths between sources and destinations points. On the other hand, the populated centrality indicator sum the population that would potentially pass through the segment in the shortest paths between sources and destinations.


**_Parameters:_**

Some parameters **MUST** be set manually.

Open the scripts and adjust the 2.1 section accordingly:

- `profile`: refers to the transportation mean, choose between `foot-walking` and `driving-car`
- `scope`: level of healthcare facilities, choose between `primary`, `non_primary` and `all`
- `focus_area`: refers to the transportation mean, choose between `Dondo`, `Tica`, `Quelimane`, `Mocuba` and `Makambine`.
- `directionality`:  can be `bi` or `uni`
- `indicator`:  can be `tc` or `pc`
- `tc_cluster`: in `km`, refers to the maximum distance to be considered between a population nucleus and the health facilities (it is set to 20km by deafult)


**_Script:_**
- [1.0_targeted_main.R](../src/4_centrality/1.0_targeted_main.R)

**_Sub-scripts:_**
- [1.1_export_graph.R](../src/4_centrality/1.1_export_graph.R) 
- [1.2_network_creation.R](../src/4_centrality/1.2_network_creation.R) 
- [1.3_targeted_centrality_local.R](../src/4_centrality/1.3_targeted_centrality_local.R)

## 3. Centrality difference

**_Objective:_**
Compare the targeted score of the road segment before the floods and after the floods.

**_Parameters:_**

Some parameters **MUST** be set manually.

Open the scripts and adjust the 2.1 section accordingly:

- `profile`: refers to the transportation mean, choose between `foot-walking` and `driving-car`
- `scope`: level of healthcare facilities, choose between `primary`, `non_primary` and `all`
- `focus_area`: refers to the transportation mean, choose between `Dondo`, `Tica`, `Quelimane`, `Mocuba` and `Makambine`.
- `directionality`:  can be `bi` or `uni`
- `indicator`:  can be `tc` or `pc`
- `tc_cluster`: in `km`, refers to the maximum distance to be considered between a population nucleus and the health facilities (it is set to 20km by deafult)


**_Script:_**
- [1.4_centrality_difference.R](../src/4_centrality/1.4_centrality_difference.R)

</br>
</br>

# **V. OSM data completeness analysis**
## 1. Aggregation at country level

### **_Objective:_**
Using Ohsome API, analysis of the the contribution of entities in OSM:
1. roads length
2. Health facilties
3. User activity 

</br>

**Scripts:**
- [ohsome_stat.R](../src/5_data_completeness/ohsome_stat.R) : functions to send request to Ohsome API endpoints. The script is called byt the following script
- [osm_completeness_aggreg.R](../src/5_data_completeness/osm_completeness_aggreg.R) : retrieve the data from Ohsome and format it to be ploted afterwards.
- [osm_completeness_plot_aggreg.R](../src/5_data_completeness/osm_completeness_plot_aggreg.R) : plot and export the data


</br>
</br>

## 2. Disaggregation between flooded and non flooded regions

### **_Objective:_**
Using Ohsome API, analysis of the the contribution of entities in OSM:
1. roads length
2. Health facilties
3. User activity 

</br>

**Scripts:**
- [ohsome_stat.R](../src/5_data_completeness/ohsome_stat.R) : functions to send request to Ohsome API endpoints. The script is called byt the following script
- [osm_completeness_aggreg.R](../src/5_data_completeness/osm_completeness_aggreg.R) : retrieve the data from Ohsome and format it to be ploted afterwards.
- [osm_completeness_plot_aggreg.R](../src/5_data_completeness/osm_completeness_plot_aggreg.R) : plot and export the data
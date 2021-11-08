# System requirements
### Scripts have been tested on the following systems
|Versions|Linux|MacOS|
|---|---|---|
|OS|Ubuntu 20.04.2|11.3|
|R|4.0.5|4.0.5|
|GDAL|3.2.1|3.3.0|
|GEOS|3.9.0|3.9.1|
|PROJ|7.2.1|8.0.1|


**WARNING:** 
Make sure to use a version of GEOS > 3.9

Some issues on geometry operations (st_difference) were detected with the use of older libraries which don't include OverlayNG in JTS. It was implemented in JTS version 1.18.


# Running time estimation : (script organised is obsolete)

## Parameters of the estimation
We extracted the running time in order to give an estimation.

Scope of the estimation:
- Country: Mozambique
- Profile :  foot-walking
- Health care level  OSM tags :

    |OSM tags|All|
    |---|---:|
    |**amenity**|clinic,  health_post, doctors, hospital|
    |**healthcare**|clinic,  health_post, doctors, midwife, nurse, center, hospital|
    |**building**|hospital|
    |**_Total points_**|**_1060_**|

## Analysis steps

|**_I. Data Preparation_**|Tech| Duration (min) |
 |---|---:|---:|
|**_Total_**||**_143_**|
|**_1. Data download_** ||**_28_**|
|1.1 Main datasets|[R script](../src/1._data_preparation/1.1_datapreparation.R)|4|
|1.2 Preparation of the flood data|[R script](../src/1._data_preparation/1.2_floods_data_preparation.R)|24|
|**_2. Create a .osm.pbf file_** |[R script](../src/1._data_preparation/2._create_impacted_pbf.R)|**_115_**|

</br>
</br>

**_II. Healthcare accessibility analysis_**


|**_Vector-based access analysis_**|Tech| Driving car Duration (min) | Foot walking Duration (min)|
|---|---|---:|---:|
|**_Total_** || **_60_**|**_55_**|
|**_1. Launch ORS instances_**|[Docker](https://github.com/GIScience/openrouteservice/wiki/Installation-and-Usage)|19|19|
|**_2. Isochrone processing_**|[R script](../src/2._isochrones_alysis/isochrones_main.R)|41|36|

**_Note:_** The process depends on the data preparation. Therefore to get a total processing time, you should take into consideration both process steps.

</br>
</br>

|**_Raster-based access analysis_**|Tech| Multimodal car Duration (min) | Foot walking Duration (min)|
|---|---|---:|---:|
|**_Total_** |[R script](../src/3_raster_analysis/raster_main.R)|**_34_**|**_20_**|

**_Note:_**  The process depends only on the first section of the data preparation (I.1. Data download) of the data preparation and does not require the second section (I.2. Create a .os.pbf file). Therefore to get a total processing time, you should take into consideration the data download steps.

</br>
</br>

|**_III. Centrality analysis_**|Tech| Foot walking Duration (h)|
|---|---|---:|
|**_Total_** ||**_∼ 60_**|
|**_1. Launch ORS instances_**|[Docker](https://github.com/GIScience/openrouteservice/wiki/Installation-and-Usage)|0.3|
|**_3. Targeted centrality_**|[R script](../src/4_centrality/targeted_main.R)|∼ 60|


**_Note:_** the processing time was calculated for the Bbox corresponding to the whole Mozambique. The processing time is higly dependent of the chosen boundig box and a reduced area of interest would reduce the computation time.

</br>
</br>

|**_IV. OSM data completeness analysis_**|Tech| Duration (min)|
|---|---|---:|
|**_Total_** ||**__**|
|**_1. Aggregation at country level_**|[R script]()|||
|**_2. Disaggregation between flooded and non flooded regions_**|[R script]()|||


</br>
</br>

**_Note:_** the first step (set up local instances of ORS) only need to be done once. Afterward, it is possible to launch new analysis (steps 2 to 5) on the same country and changing the scope of health facilities and/or the profile.

This estimation was done with the following system:
|  |  |
|---|---|
|OS|MacOS 11.3|
|RAM|16 Go|
|R|4.0.5|
|GDAL|3.3.0|
|GEOS|3.9.1|
|PROJ|8.0.1|

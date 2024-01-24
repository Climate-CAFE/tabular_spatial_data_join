This directory provides a tutorial template for spatializing and mapping tabular temperature data at the county level.

## Scripts
There are two scripts in this directory that accomplish similar tasks: one in R and the other in Python. Both scripts demonstrate how to take tabular temperature data that has a unique county ID and create a basic map of the data.
1. R script: Join_by_ID_tidy_remote.R
2. Python script: merge_map.ipynb

## Input data
1. Mean_Tmax_2020_Counties_CONUS.Rds -- this file is a single R data file containing a dataframe of average daily maximum air temperatures for 2020 by county. It contains a unique county ID ("GEOID") as well as the annual average high temperature in degrees Celsius ("MeanTmaxC").

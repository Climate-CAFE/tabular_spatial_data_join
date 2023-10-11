# Join_by_ID_tidy_remote.R
# JC 2023-10-10

# Josh's modification of Keith's Join_by_ID.R script to use tidy functions for wrangling
#  and generating some maps with ggplot

# Original script is a simple example of spatializing tabular data for use in mapping.

# This script is being rewritten to load all data from remote-accessible sources
#  (originally was built with local data files)

## Packages & Data ----
require(pacman) ## my preferred package manager within R scripts
p_load(sf, tidyverse, maps, ggiraph, tigris)

# Read in the 2019 county shapefile obtained from 
# https://www.census.gov/cgi-bin/geo/shapefiles/index.php
#coshp <- st_read("tl_2019_us_county/tl_2019_us_county.shp") ## this is the local-load version

# We will load the county shapefile remotely via the tigris package
coshp <- tigris::counties(year = 2019)
head(coshp)

# Read in the tabular data, which is an annual average of daily Tmax 
# (maximum air temperature in deg. C) for 2020 by county
temp <- readRDS("Mean_Tmax_2020_Counties_CONUS.Rds")  ## this is the local-load version
#temp <- readRDS("https://dataverse.harvard.edu/api/access/datafile/MY_RDS_FILE_ADDRESS")  ## this is a template of the remote-load version
head(temp)

## once this data is uploaded to dataverse, we will replace the local-load RDS with a remote-load file.
## for now, users will need to download both the code and this RDS file to reproduce analysis here

# Note that two counties are expected to have missing temperature data due to
# unavailability of data for these locations in the ERA5-Land input data set
length(which(is.na(temp$MeanTmaxC))) # 2

# which counties are they?
missing_counties_fips <- temp$GEOID[is.na(temp$MeanTmaxC)]

# check names using the county.fips lookup table from the maps package
county.fips$polyname[county.fips$fips %in% as.numeric(missing_counties_fips)]

# Confirm that the GEOID variables in the table and shapefile are the same type
# and have leading 0's (counties with state FIPS < 10 have leading 0 that gets
# dropped when converting to numeric)
is(coshp$GEOID) # character
table(nchar(coshp$GEOID)) # all values are 5 characters long, as expected

is(temp$GEOID) # character
table(nchar(temp$GEOID)) # all values are 5 characters long

## Merge ----

# Merge the tabular data into the county shapefile by GEOID, this time using full_join() from tidy
merged_data <- full_join(coshp, temp, by = "GEOID")
head(merged_data)

# Compare the dimensions of the input and output objects
dim(coshp)[1] # 3233
dim(temp) [1] # 3108
dim(merged_data)[1] # 3233

# The county shapefile includes counties in AK, HI, PR, and other American island
# territories; the temperature data is only for CONUS and is missing for 2 counties
#
# We don't need a shapefile with missing data, so let's re-merge to keep only the 
# matching values

# To do this using the tidy join functions, we would use a right_join() with temp as "y"
#  because temp has all the relevant values we want to keep. Also, we'll drop the unwanted
#  columns here in this same step, to avoid too many variable overwrites
merged_data_final <- right_join(coshp, temp, by = "GEOID") %>%
  select(-c(COUNTYNS, NAME, LSAD, CLASSFP, MTFCC, CSAFP, METDIVFP, 
            FUNCSTAT))
head(merged_data_final)
dim(merged_data_final)[1] # 3108

# Confirm that all variable names are 10 characters or fewer
# (shapefile variable names are limited to 10 characters)
length(which(nchar(names(merged_data_final)) > 10)) # 0

# Confirm it has a coordinate reference system (CRS)
st_crs(merged_data_final) # yes, it was inherited from the original census shapefile. Confirm:

isTRUE(all.equal(st_crs(coshp), st_crs(merged_data_final))) # TRUE


## Maps ----
# Basic temperature map by county using shapefile and ggplot

# note: maps are large, may take a while to render

# use shape file as data argument and temperature variable as fill aesthetic in geom_sf()
p <- ggplot(data = merged_data_final) +
  geom_sf(aes(fill = MeanTmaxC)) +
  scale_fill_gradient(low = 'yellow', high = 'red')

p

# alternate without borders (lighter-weight)
p_no_borders <- ggplot(data = merged_data_final) +
  geom_sf(aes(fill = MeanTmaxC), lwd = 0) +
  scale_fill_gradient(low = 'yellow', high = 'red')

p_no_borders

# For an interactive plot, we can use the ggiraph package's special ggplot interactive functions
p_interactive <- ggplot(data = merged_data_final) +
  geom_sf_interactive(aes(fill = MeanTmaxC, tooltip = paste0(NAMELSAD, '\nMeanTmaxC = ', round(MeanTmaxC, 2), '°C'))) +
  scale_fill_gradient(low = 'yellow', high = 'red')

# render interactive plot in viewer
girafe(ggobj = p_interactive)

# We can export the interactive plot to an html file as well
##  (commented out because output file is large)
#htmltools::save_html(girafe(ggobj = p_interactive), file = 'Mean_Tmax_2020_Counties_CONUS_from_tidy_interactive_map.html')


## Export shapefile ----
# Write the shapefile as a geopackage, which is like a shapefile but so much 
# easier to work with because it's just one file instead of like 7.

# Give it the same name as the tabular data so that it's obvious they contain
# the same data.
##  (commented out because output file is large)
#st_write(merged_data_final, "Mean_Tmax_2020_Counties_CONUS_from_tidy.gpkg")

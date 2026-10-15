# Geocode property addresses
# ==========================
# Batch-geocodes PPR addresses with the Google API, then validates every point: Ireland bounding box, and a spatial join to OSi county boundaries to drop points that land in the wrong county.
# Part of: How Crime Shapes Property Values (MSc Business Analytics thesis, Ayoola Fadare, 2025)
# Inputs: outputs of 01, OSi county boundaries

# Geo_coding --------------------------------------------------------------


#Getting Latitude and longitude for the property data set


# get latitude and longitude for Property Data
# geocoded_Property <- geocode(property_ireland$Full_Address,
#                             output = "latlon",
#                             source = "google")

# property_ireland$lon <- geocoded_Property$lon
# property_ireland$lat <- geocoded_Property$lat
# # Combine the Geo-coded data with original data frame
# property_ireland <- cbind(property_ireland, geocoded_Property)

# get latitude and longitude for Crime Data
# geocoded_crime <- geocode(crime_ireland_wide$`Garda Location`,
#                           output = "latlon",
#                           source = "google")
# 
# crime_ireland_wide$lon <- geocoded_crime$lon
# crime_ireland_wide$lat <- geocoded_crime$lat
# # Combine the geocoded data with original data frame
# crime_ireland_wide <- cbind(crime_ireland_wide, geocoded_data)


# # #geo coding with tidygeocoder
# property_ireland <- property_ireland %>%
#     tidygeocoder::geocode(address = Full_Address,
#             method  = 'google',
#             lat     = latitude,
#             long    = longitude)


# Batch Geo coding --------------------------------------------------------
# names(batch)
# print(head(batches[[1]]))

# Filter rows with missing latitude or longitude
geo_property_missing <- geo_property %>%
    filter(is.na(latitude) | is.na(longitude)) %>%
    mutate(Full_Address = as.character(Full_Address))

# Split the data into batches of 1000
batches <- split(geo_property_missing, 
                 ceiling(seq_len(nrow(geo_property_missing)) / 1000))

# Initialize a list to store results
results <- vector("list", length(batches))

# LOOP through each batch and geocode
# start from first batch
# for (i in seq_along(batches)) 

# start from second batch
for (i in 1:length(batches)) 
    {
    batch <- batches[[i]]
    
    geocoded <- batch %>%
        tidygeocoder::geocode(
            address = Full_Address,
            method  = 'geoapify',
            lat     = "latitude",
            long    = "longitude",
            limit   = 1
                             )
    
    results[[i]] <- geocoded
    Sys.sleep(5)  # Pause to respect rate limits
    }

# Combine all results into a single data frame
geo_property_updated <- bind_rows(results)

# Merge the updated geocoded data back into the original dataset
lookup <- geo_property_updated %>%
    select(Full_Address, 
           new_lat  = `latitude...13`, 
           new_long = `longitude...14`) %>% 
    distinct(Full_Address, .keep_all = TRUE)

# Left join the lookup table to the original dataset.
# Then use coalesce() to update the missing values in latitude and longitude while retaining the original ones otherwise.
geo_property <- geo_property %>%
    left_join(lookup, 
              by           = "Full_Address",
              relationship = "many-to-many") %>%
    mutate(
        latitude  = coalesce(latitude, new_lat),
        longitude = coalesce(longitude, new_long)
    ) %>%
    # Remove the temporary columns created by the join.
    select(-new_lat, -new_long)




# REMOVE OUTLIERS in GEO CODED  Property data ---------------------------------------
# Set valid lat/lon bounds for Ireland
# Approximate: latitude 51 to 56, longitude -11 to -5
detail_prop <- geo_property %>%
    mutate(
        latitude = ifelse(latitude < 51 | latitude > 56, NA, latitude),
        longitude = ifelse(longitude < -11 | longitude > -5, NA, longitude)
    )

skim(detail_prop)
# remove rows without long and lat
detail_prop <- detail_prop %>%
    filter(
        !is.na(latitude) &   # latitude must not be NA
            !is.na(longitude)    # longitude must not be NA
    )

#  Load county shapefile (replace path with your file)
# Make sure it has a "County" or "NAME" column to match
ireland_counties <- st_read("data/Counties_NationalStatutoryBoundaries_Ungeneralised_2024_-2729281652066043984/cc884397-2c22-4325-9bdc-3370b2256500.gdb")
# ireland_counties <- read_csv("data/Counties___OSi_National_Statutory_Boundaries_132771218381663344.csv")

skim(ireland_counties)

# Convert data to an sf object
points_sf <- detail_prop %>%
    filter(!is.na(latitude), !is.na(longitude)) %>%
    st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

st_crs(points_sf)
st_crs(ireland_counties)

# If ireland_counties is not EPSG:4326, transform it
ireland_counties <- st_transform(ireland_counties, st_crs(points_sf))
# Pick a projected CRS (Irish Transverse Mercator)
proj_crs <- 2157

# Transform both layers
points_sf   <- st_transform(points_sf,       crs = proj_crs)
ireland_counties <- st_transform(ireland_counties, crs = proj_crs)

# Spatial join to get the actual county each point falls in
points_joined <- st_join(points_sf, ireland_counties, join = st_within)

# Compare and flag mismatches
points_joined <- points_joined %>%
    mutate(
        # convert both to title case
        County          = str_to_title(County),
        ENG_NAME_VALUE  = str_to_title(ENG_NAME_VALUE),
        # then match & set bad coords to NA
        match     = (County == ENG_NAME_VALUE),
        latitude  = ifelse(!match, NA, st_coordinates(geometry)[,2]),
        longitude = ifelse(!match, NA, st_coordinates(geometry)[,1])
    )

# filter for true matches
points_joined <- points_joined %>%
    filter(match)


# Drop geometry for regular data frame 
detail_prop <- st_drop_geometry(points_joined)

detail_prop %>% 
    count(match)

detail_prop <- detail_prop %>% 
    select(`Date of Sale (dd/mm/yyyy)`,Address,County,Eircode,`Price ()`,`Description of Property`,Full_Address,year_sale)

lookup <- geo_property %>%
    select(Full_Address, 
           latitude, 
           longitude) %>% 
    distinct(Full_Address, .keep_all = TRUE)

lookup <- lookup %>% 
    mutate(Full_Address =  str_to_lower(Full_Address))

# Left join the lookup table to the original dataset.
# Then use coalesce() to update the missing values in latitude and longitude while retaining the original ones otherwise.
detail_prop <- detail_prop %>%
    left_join(lookup, 
              by           = "Full_Address",
              relationship = "many-to-many")
    
# to get property details ---------------------------------
detail_prop <- detail_prop %>% 
    mutate(`Description of Property` = str_remove_all(`Description of Property`,
            "[\\p{C}]"           # remove all control/formatting chars
        ),
        `Description of Property` = str_squish(`Description of Property`)  
        # collapse any runs of spaces to one, trim ends
    )

skim(detail_prop)
# classify properties into new ans second hand
detail_prop <- detail_prop %>%
    mutate(property_type = case_when(
        str_detect(`Description of Property`, regex("new | Nua", 
                                                    ignore_case = TRUE)) ~ "New",
        str_detect(`Description of Property`, regex("second-hand | Atháimhe", 
                                                    ignore_case = TRUE)) ~ "Second-Hand",
        TRUE ~ "Other"
    ))

detail_prop %>% 
    filter(unit_type == "Apartment") %>% 
    view()

# categorise into house or apartment
detail_prop <- detail_prop %>% 
    mutate(Full_Address = str_to_lower(Full_Address))

pattern_housing <- paste0("\\b(",
                          # English indicators
                          "apartment|apt\\.?|",
                          "flat|flt\\.?|",
                          "unit|unt\\.?|",
                          "suite|ste\\.?|",
                          "floor|flr\\.?|",
                          "level|lvl\\.?|",
                          "block|blk\\.?|",
                          "tower|studio|std\\.?|",
                          "penthouse|residence|duplex|sub-building|",
                          # Irish indicators
                          "árasán|arasan|an t-árasán|t-árasán|",
                          "teaghais|aonad",
                          ")\\b")
    
detail_prop <- detail_prop %>%
    mutate(unit_type = case_when(
        str_detect(Full_Address, regex(pattern_housing, ignore_case = TRUE)) ~ "Apartment",
        TRUE ~ "House"
    ))

detail_prop %>% 
    distinct(Full_Address)

detail_prop <- detail_prop %>% 
    rename(Year = year_sale)


# Geocode and clean Garda station locations
# =========================================
# Re-geocodes Garda stations, fills gaps manually from the Garda station directory, assigns counties and aligns the crime and property tables.
# Part of: How Crime Shapes Property Values (MSc Business Analytics thesis, Ayoola Fadare, 2025)
# Inputs: outputs of 01-02, data/directory.csv

# Address OUTLIERS in crime data and CLEANING ------------------------------------------
crime_ireland_wide <- crime_ireland_wide %>%
    mutate(
        lat = ifelse(lat < 51 | lat > 56, NA, lat),
        lon = ifelse(lon < -11 | lon > -5, NA, lon)
    )
skim(crime_ireland_wide)
crime_ireland_wide %>%
    summarise_all(~sum(is.na(.)))

crime_ireland_wide %>% 
    filter(is.na(lat)) %>% 
    distinct(`Garda Location`) %>% 
    view()

# assuming the NAs in columns 3 - 14 IN the dataset equals to 0, i will replace those values with zero in df
crime_ireland_wide <- crime_ireland_wide %>% 
    mutate(
        across(
            3:14,
            ~ replace_na(.x, 0)
        )
    )
# trying to re-geocode the crime data
crime_ireland_wide <- crime_ireland_wide %>% 
    mutate(
        `Garda Location` = str_remove_all(
            `Garda Location`,
            "[\\p{C}]"           # remove all control/formatting chars
        ),
        `Garda Location` = str_squish(`Garda Location`)  
        # collapse any runs of spaces to one, trim ends
    )
# Filter rows with missing latitude or longitude
crime_ireland_wide_miss <- crime_ireland_wide %>%
    filter(is.na(lat) | is.na(lon)) %>%
    mutate(`Garda Location` = as.character(`Garda Location`))

# #geo coding with tidygeocoder
crime_ireland_wide_miss <- crime_ireland_wide_miss %>%
    tidygeocoder::geocode(address = `Garda Location`,
            method  = "geoapify",
            lat     = latitude,
            long    = longitude)

# Merge the updated geocoded data back into the original dataset
lookup_crime <- crime_ireland_wide_miss %>%
    select(`Garda Location`, 
           new_lat  = latitude...20, 
           new_long = longitude...21) %>% 
    distinct(`Garda Location`, .keep_all = TRUE)

# Left join the lookup table to the original dataset.
# Then use coalesce() to update the missing values in latitude and longitude while retaining the original ones otherwise.
crime_ireland_wide <- crime_ireland_wide %>%
    left_join(lookup_crime, 
              by           = "Garda Location",
              relationship = "many-to-many") %>%
    mutate(
        lat  = coalesce(lat, new_lat),
        lon = coalesce(lon, new_long)
    ) %>%
    # Remove the temporary columns created by the join.
    select(-new_lat, -new_long)

crime_ireland_wide %>% 
    distinct(`Garda Location`) %>% 
    view()

# get a county column
crime_ireland_wide <- crime_ireland_wide %>%
    mutate(
        county = str_extract(
            `Garda Station`,
            "(?<=, )[A-Za-z/ ]+(?= Division)"
        )
    )

# na county
crime_ireland_wide %>% 
    filter(is.na(county)) %>% 
    distinct(`Garda Location`) %>% 
    view()

# county showing na are D.M.R the regex didnt catch it replacing the NAs with dublin
crime_ireland_wide <- crime_ireland_wide %>%
    mutate(
        county = ifelse(is.na(county), "Dublin", county),  # fill missing
        county = str_to_title(county)                      # then title case
    )

# crime dataset geo_coding Fix
# crime_ireland_wide <- crime_ireland_wide %>% 
#     select(-lat, - lon)

crime_ireland_wide %>% 
    distinct(`Garda Location`) %>% 
    view()
# manually fill in latitude and longitude from (https://www.garda.ie/en/contact-us/station-directory/)
garda_station <- crime_ireland_wide %>% 
    distinct(`Garda Station`) %>% 
    mutate(latitude = "",
           longitude= "")

directory <- directory %>% 
    select(`Garda Location`,lat,lon)

directory <- na.omit(directory)

skim(directory)

# cleaning datasets to match
directory <- directory %>%
    mutate(`Garda Location` = str_trim(str_to_lower(`Garda Location`)))

crime_ireland_wide <- crime_ireland_wide %>%
    mutate(`Garda Location` = str_trim(str_to_lower(`Garda Location`)))

skim(crime_ireland_wide)
    
crime_ireland_wide <- stringdist_left_join(
    crime_ireland_wide,
    directory %>% 
        select(`Garda Location`, 
               newlat = lat,
               newlon =  lon),
    by = "Garda Location",
    method = "jw",         # Jaro-Winkler method (good for names)
    max_dist = 0.1,        # Adjust this — lower is stricter, higher is looser
    distance_col = "dist"  # optional: keep distance score
)
crime_ireland_wide <- crime_ireland_wide %>% 
    select(-`Garda Location.y`,-dist)

crime_ireland_wide <- crime_ireland_wide %>% 
    rename("Garda Location" = `Garda Location.x`)

crime_ireland_wide <- crime_ireland_wide %>% 
    mutate(
        lat  = if_else(is.na(newlat), lat, newlat),
        lon = if_else(is.na(newlon), lon, newlon)
    ) %>% 
    select(-newlat,-newlon)

directory %>% 
    filter(str_detect(tolower(`Garda Location`), "graiguenamanagh")) %>% 
    view()




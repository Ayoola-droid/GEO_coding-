# Load and prepare raw data
# =========================
# Reads the Property Price Register and Garda crime data, reshapes crime to one row per station-year, builds full addresses, removes duplicates.
# Part of: How Crime Shapes Property Values (MSc Business Analytics thesis, Ayoola Fadare, 2025)
# Inputs: data/PPR-ALL.csv, data/crime 2003-2023.csv

# Tables/DFs ------------------------------------------------------------------

property_ireland   <- read_csv("data/PPR-ALL.csv", 
                             locale = locale(encoding = "ISO-8859-1"))
crime_ireland      <- read_csv("data/crime 2003-2023.csv")
geo_property       <- read_csv("data/geo_property.csv")
detail_prop        <- read_csv("data/geo_property_true_match.csv")
crime_ireland_wide <- read_csv("data/geo_crime.csv")
housing            <- read_csv("data/housing stock.csv")
income             <- read_csv("data/median income.csv")
income10           <- read_csv("data/median income 2010.csv")
population_ireland <- read_csv("data/population at census.csv")
new_house_reg      <- read_csv("data/new house reg.csv")
county_size        <- read_csv("data/county_size.csv")
new_house_reg2     <- read_csv("data/new house reg2.csv")
city               <- st_read("data/Built_Up_Areas.geojson")
ireland_counties   <- st_read("data/Counties_NationalStatutoryBoundaries_Ungeneralised_2024_-2729281652066043984/cc884397-2c22-4325-9bdc-3370b2256500.gdb")
trainstation       <- st_read("data/train station.geojson")
airports           <- st_read("data/airport.geojson")
all_hos            <- read_csv("data/pub.csv",
                               locale = locale(encoding = "latin1"))
com_airports       <- read_csv("data/com_airport.csv")
# public_hos         <- read_csv("data/public_hos.csv")
# private_hos        <- read_csv("data/Private_hos.csv")
mortgage           <- read_csv("data/retail intrest rates.csv",
                               locale = locale(encoding = "ISO-8859-1"))
scsi               <- read_csv("data/scsi_index.csv")
directory          <- read_csv("data/directory.csv")
# crime_in_500m      <- read_csv("data/crime_in_500m.csv")
# crime_in_1000m     <- read_csv("data/crime_in_1000m.csv")
# crime_in_1500m     <- read_csv("data/crime_in_1500m.csv")
# crime_in_2000m     <- read_csv("data/crime_in_2000m.csv")
# crime_in_3000m     <- read_csv("data/crime_in_3000m.csv")
# crime_in_6000m     <- read_csv("data/crime_in_6000m.csv")
crime_in_500m      <- read_csv("data/crime_in_500m_lag1.csv")
crime_in_1000m     <- read_csv("data/crime_in_1000m_lag1.csv")
crime_in_1500m     <- read_csv("data/crime_in_1500m_lag1.csv")
crime_in_2000m     <- read_csv("data/crime_in_2000m_lag1.csv")
crime_in_3000m     <- read_csv("data/crime_in_3000m_lag1.csv")
crime_in_6000m     <- read_csv("data/crime_in_6000m_lag1.csv")
crime_in_500m_lag1 <- read_csv("data/crime_in_500m_lag2.csv")
crime_in_1000m_lag1<- read_csv("data/crime_in_1000m_lag2.csv")
crime_in_1500m_lag1<- read_csv("data/crime_in_1500m_lag2.csv")
crime_in_2000m_lag1<- read_csv("data/crime_in_2000m_lag2.csv")
crime_in_3000m_lag1<- read_csv("data/crime_in_3000m_lag2.csv")
crime_in_6000m_lag1<- read_csv("data/crime_in_6000m_lag2.csv")
crime_in_500m_lag2 <- read_csv("data/crime_in_500m_lag3.csv")
crime_in_1000m_lag2<- read_csv("data/crime_in_1000m_lag3.csv")
crime_in_1500m_lag2<- read_csv("data/crime_in_1500m_lag3.csv")
crime_in_2000m_lag2<- read_csv("data/crime_in_2000m_lag3.csv")
crime_in_3000m_lag2<- read_csv("data/crime_in_3000m_lag3.csv")
crime_in_6000m_lag2<- read_csv("data/crime_in_6000m_lag3.csv")



# Adjust crime Data by Garda Station --------------------------------------
# Reshape the data to wide format
crime_ireland_wide <- crime_ireland %>%
    # Select only the columns we need
    select(Year, `Garda Station`, `Type of Offence`, VALUE) %>%
    # Convert to wide format
    pivot_wider(
        id_cols = c(Year, `Garda Station`),
        names_from = `Type of Offence`,
        values_from = VALUE
    )
#remove the numbers
crime_ireland_wide <- crime_ireland_wide %>%
    mutate(
        # Remove just the numeric prefix
        `Garda Location` = paste0(
            sub("^\\d+\\s+", "", `Garda Station`)
        )
    )

crime_ireland_wide$`Garda Location` <- paste("Garda Station",
                                    crime_ireland_wide$`Garda Location`,
                                    "Ireland",
                                    sep = ", ")

# create a full address with "Ireland"
property_ireland <- property_ireland %>%
    mutate(
        Full_Address = str_c(
            str_replace_na(Address, ""),
            str_replace_na(County, ""),
            "Ireland",
            str_replace_na(Eircode, ""),
            sep = ", "
        )
    )

# EDA ---------------------------------------------------------------------
skim(crime_ireland_wide)

property_ireland <- property_ireland %>%
    mutate(Full_Address = as.character(Full_Address),
           `Date of Sale (dd/mm/yyyy)` = as.Date(`Date of Sale (dd/mm/yyyy)`,
                                                 format = "%d/%m/%Y"))
# fix data values of the data set
geo_property <- geo_property %>%
    mutate(Full_Address = as.character(Full_Address),
           `Date of Sale (dd/mm/yyyy)` = as.Date(`Date of Sale (dd/mm/yyyy)`,
                                                 format = "%d/%m/%Y"))

# Add a year column to property data
geo_property <- geo_property %>% 
    mutate(year_sale = year(`Date of Sale (dd/mm/yyyy)`)) 

# remove duplicate rows
geo_property <- geo_property %>% 
    distinct()

str(property_ireland$Full_Address)


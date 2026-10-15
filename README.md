# Geocoding & Validating 650,000 Irish Property Sales

**R · tidygeocoder · Google Geocoding API · sf · spatial joins**

Ireland's Property Price Register lists every home sale, but only as a free-text address with no coordinates. To measure how close each home is to crime, transport and services, I geocoded the addresses at scale and then checked that the results could be trusted.

## Business question

Can free-text Irish addresses be turned into reliable map coordinates at scale, and how do you catch the ones that are wrong?

## Approach

1. **Clean addresses:** build a full address string, standardise spacing and case, remove duplicate sales.
2. **Batch geocode** in batches of 1,000 through the Google API, with a progress bar and the ability to restart from a given batch. Results are cached in a lookup table so no address is paid for twice.
3. **Validate every point:**
    - drop coordinates outside Ireland's bounding box (latitude 51–56, longitude −11 to −5);
    - spatially join each point to the official OSi county boundaries (Irish Transverse Mercator, EPSG:2157);
    - **flag and drop points that land in a different county from the one in the address**.
4. **Garda stations:** geocode every station, then fill failures by hand from the Garda station directory (including Irish-language place names), and assign each station to a county.
5. **Classify properties** as new or second-hand and house or apartment, using English and Irish keywords in the description.

## Results

- Over 700000 sales geocoded; 556000 kept after validation. 
- 41000 coordinates dropped for falling outside Ireland, and 8500 for landing in the wrong county.
- Every Garda station located, including 4 fixed manually.

## Files

```
R/
├── 00_setup.R                     # libraries; API keys from .Renviron
├── 01_load_and_prepare.R          # read PPR and crime data, build addresses
├── 02_geocode_properties.R        # batch geocoding + county validation
└── 03_geocode_garda_stations.R    # station geocoding + manual fixes
data/
├── crime 2003-2023.csv            # CSO recorded crime by Garda station
├── directory.csv                  # Garda station coordinates (my geocoding + manual fixes)
└── geocoded_garda_crime.csv       # output: station-year crime with coordinates
```

The Property Price Register itself is too large for GitHub; download it from https://www.propertypriceregister.ie/.

## Running it

1. Create a file called `.Renviron` in the project folder containing `GOOGLE_MAPS_KEY=your-key`. It is git-ignored, so the key never reaches GitHub.
2. Run the scripts in order.

## Used in

[How Crime Shapes Property Values in Ireland](https://github.com/Ayoola-droid/irish-house-prices-crime), my MSc thesis.

## Author

Ayoola Fadare · MSc Business Analytics (2025) · [LinkedIn](https://www.linkedin.com/in/ayoola-fadare-78916b107)
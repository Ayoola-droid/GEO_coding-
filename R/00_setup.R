# Setup
# =====
# Libraries and API keys used by every script.
# Part of: How Crime Shapes Property Values (MSc Business Analytics thesis, Ayoola Fadare, 2025)
# Inputs: none

library(gratia)
library(mgcv)
library(caret)
library(corrplot)
library(xgboost)
library(DALEX)
library(parallel)
library(doParallel)
library(pdp)
library(vip)
library(modelsummary)
library(AER)
library(kableExtra)
library(randomForest)
library(plm)
library(mgwrsar)
library(GWmodel)
library(car)
library(spatialreg)
library(spdep)
library(fuzzyjoin)
library(timetk)
library(modeltime)
library(prophet)
library(data.table)
library(geodata)
library(httr)
library(osmextract)
library(progress)
library(osmdata)
library(janitor)
library(sp)
library(stringdist)
library(geosphere)
library(csodata)
library(tidygeocoder)
library(sf)
library(tidymodels)
library(ggcorrplot)
library(mice)
library(skimr)
library(babynames)
library(readxl)
library(tidyverse)
library(writexl)
library(scales)
library(ggthemes)
library(cli)
library(ggmap)




# API keys -----------------------------------------------------------------
# Keys are read from environment variables, never written in code.
# Put them in a file called .Renviron in the project folder (it is git-ignored):
#   GOOGLE_MAPS_KEY=your-google-key
#   GEOAPIFY_KEY=your-geoapify-key
register_google(key = Sys.getenv("GOOGLE_MAPS_KEY"))
# Progress bar ------------------------------------------------------------

pb <- progress_bar$new(
    total = nrow(detail_prop),
    format = "[:bar] :percent Completed: :current/:total (:eta remaining)"
)

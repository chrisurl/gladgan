library(rnoaa)
library(eurostat)
library(tidyverse)
library(stringr)
library(countrycode)

# Define the vector of FIPS codes you've provided for European countries
fips_europe <- c('AL', 'EN', 'AU', 'AJ', 'BO', 'BE', 'BK', 'BU', 'HR', 'CY', 
                 'EZ', 'DA', 'FI', 'FR', 'GG', 'GM', 'GR', 'HU', 'IC', 'EI', 
                 'IT', 'KZ', 'LG', 'LH', 'LU', 'MD', 'MJ', 'MK', 'NL', 'NO', 
                 'PL', 'PO', 'RI', 'LO', 'SI', 'SP', 'SW', 'TU', 'UP', 'UK')

# Convert FIPS to ISO 3166 Alpha-2
iso_alpha2_europe <- countrycode(fips_europe, "fips", "iso2c")

# Create a data frame
df_europe <- data.frame(FIPS = fips_europe, geo = iso_alpha2_europe)

# Print the data frame
print(df_europe)

a = tempdir()
set_eurostat_cache_dir(a)

# Fetch the industrial production index for Germany
gasm_data <- get_eurostat("nrg_cb_gasm")
df1 = gasm_data |>
  filter(nrg_bal =="IC_CAL_MG",
         unit == "TJ_GCV") 

eurostat::clean_eurostat_cache(a)

set_eurostat_cache_dir(a)

# Fetch the industrial production index for Germany
ind_prod_data <- get_eurostat("sts_inpr_m", 
                              filters = list(
                                indic_bt = "PROD",
                                nace_r2 = "B-D",
                                S_ADJ = "SCA", UNIT = "I15"
                              ))

eurostat::clean_eurostat_cache(a)

set_eurostat_cache_dir(a)

# Fetch the producer prce index
ind_ppi_data <- get_eurostat("STS_INPPD_M", 
                              filters = list(
                                indic_bt = "PRIN",
                                nace_r2 = "B-E36",
                                S_ADJ = "NSA", UNIT = "I15"
                              ))

eurostat::clean_eurostat_cache(a)


# From former competition we know: 
# (Eurobase code: STS_INPR_M, INDIC_BT: PROD, NACE_R2: B-D, S_ADJ:SCA, UNIT:I15)
ind_prod_germany <- ind_prod_data %>%
  # filter(geo == "DE") |>
  mutate(date = lubridate::ym(time)) |>
  select(geo, date, values) |>
  rename(pvi = values)

ind_ppi_germany <- ind_ppi_data %>%
  # filter(geo == "DE") |>
  mutate(date = lubridate::ym(time)) |>
  select(geo, date, values) |>
  rename(ppi = values)

# Get a list of GHCND stations for Germany
stations <- ghcnd_stations()

# Filter for stations with TAVG data
german_tavg_stations <- stations %>%
  # filter(substr(id,1,2) == "GM") |>
  filter(substr(id,1,2) %in% df_europe$FIPS) |>
  filter(grepl("TAVG", element)) |>
  filter(last_year > 2021) 

# Fetch the TAVG data for the selected stations
tavg_data <- ghcnd(german_tavg_stations$id, var = "TAVG", date_min = as.Date("2008-01-01"), date_max = Sys.Date())

# Convert daily data to monthly averages
germany_monthly_avg <- tavg_data |>
  mutate(FIPS = substr(id,1,2)) |>
  left_join(df_europe, by = "FIPS") %>%
  filter(element == "TAVG") |>
  mutate(date = ym(paste0(year, "-", month))) |>
  group_by(geo, date) %>%
  summarise(avg_temp = mean(VALUE1, na.rm = TRUE)/10)

# Assuming you've fetched and cleaned the gas consumption data as `df1` and weather data as `monthly_temp_germany`
merged_data <- df1 %>%
  rename(date = time) |>
  left_join(ind_prod_germany, by = c("geo","date")) %>%
  left_join(ind_ppi_germany, by = c("geo","date")) %>%
  left_join(germany_monthly_avg, by = c("geo","date")) |> # ensure the join works correctly
  arrange(geo, date)

df2 = merged_data |>
  group_by(geo) %>%
  mutate(pvi_lag = lag(pvi),
         ppi_lag = lag(ppi)) %>%
  ungroup()

write_rds(df2, file = "/Users/christianurl/projects/data/gas/df2.rds")

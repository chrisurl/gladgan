library(rnoaa)
library(eurostat)
library(tidyverse)
library(stringr)
library(countrycode)

# Define the vector of FIPS codes you've provided for European countries
fips_europe <- c('AL', 'EN', 'AU', 'AJ', 'BO', 'BE', 'BK', 'BU', 'HR', 'CY', 
                 'EZ', 'DA', 'FI', 'FR', 'GG', 'GM', 'GR', 'HU', 'IC', 'EI', 
                 'IT', 'KZ', 'LG', 'LH', 'LU', 'MD', 'MJ', 'MK', 'NL', 'NO', 
                 'PL', 'PO', 'RI', 'LO', 'SI', 'SP', 'SW', 'TU', 'UP', 'UK',
                 'RO', "MT")

# Convert FIPS to ISO 3166 Alpha-2
iso_alpha2_europe <- countrycode(fips_europe, "fips", "eurostat")

setdiff(eu_countries$code, iso_alpha2_europe)

# Create a data frame
df_europe <- data.frame(FIPS = fips_europe, geo = iso_alpha2_europe) %>%
  filter(geo %in% eurostat::eu_countries$code)
# Print the data frame
print(df_europe)

a = tempdir()
set_eurostat_cache_dir(a)

# Fetch the target data
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

# test1 = tavg_data %>%
#   mutate(value_sum = rowSums(pick(contains("VALUE"))))

# Convert daily data to monthly averages
germany_monthly_avg <- tavg_data |>
#  filter(substr(id,1,2) == "GM") %>%
  mutate(FIPS = substr(id,1,2)) |>
  left_join(df_europe, by = "FIPS") %>%
  filter(element %in% c("TAVG", "PRCP", "TMIN", "TMAX")) |>
  mutate(date = ym(paste0(year, "-", month))) |>
  select(id, geo, date, element, starts_with("VALUE")) %>%
  pivot_longer(
              cols = starts_with("VALUE"), 
              names_to = "day", 
              values_to = "value") %>%
  mutate(day = as.integer(str_replace(day, "VALUE", ""))) %>%
  pivot_wider(id_cols = c(id, geo, date, day), names_from = element, values_from = value) %>%
  group_by(geo, date) %>%
  summarise(temp_avg = mean(TAVG, na.rm = T)/10,
            prcp_sum = sum(PRCP, na.rm = T),
            t_min = min(TMIN, na.rm = T)/10,
            t_max = max(TMAX, na.rm = T)/10)

# Assuming you've fetched and cleaned the gas consumption data as `df1` and weather data as `monthly_temp_germany`
merged_data <- df1 %>%
  rename(date = time) |>
  left_join(ind_prod_germany, by = c("geo","date")) %>%
  left_join(ind_ppi_germany, by = c("geo","date")) %>%
  left_join(germany_monthly_avg, by = c("geo","date")) |> # ensure the join works correctly
  arrange(geo, date)

df2 = merged_data |>
  group_by(geo) %>%
  mutate(pvi_lag1 = lag(pvi),
         ppi_lag1 = lag(ppi),
         pvi_lag12 = lag(pvi, 12),
         ppi_lag12 = lag(ppi, 12)) %>%
  ungroup()

write_rds(df2, file = "/Users/christianurl/projects/data/gas/df2.rds")

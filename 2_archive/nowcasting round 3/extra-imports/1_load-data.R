library(tidyverse)
library(eurostat)

df = eurostat::get_eurostat("ei_eteu27_2020_m", 
  filters = list(
    partner = "EXT_EU27_2020",
    geo = c("EU27_2020", "BE", "BG", "CZ", "DK", "DE", "EE", "IE",
            "EL", "ES", "FR", "HR", "IT", "CY", "LV", "LT", "LU",
            "HU", "MT", "NL", "AT", "PL", "PT", "RO", "SI", "SK", 
            "FI", "SE"),
    indic = "ET-T",
    stk_flow = "IMP",
    unit = "MIO-EUR-NSA"),
  cache = FALSE)

monYear = substr(Sys.Date(),1,7)
write_rds(df, paste0("data_ignore/df_",monYear,".rds"))


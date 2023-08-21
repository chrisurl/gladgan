library(eurostat)
library(tidyverse)

table_id <- "nrg_cb_gasm"
gasm_data <- get_eurostat(id = table_id, type = "label")

df1 = gasm_data |>
  filter(nrg_bal == "Inland consumption - calculated as defined in MOS GAS" &
           siec == "Natural gas" & 
           unit == "Terajoule (gross calorific value - GCV)") |>
  arrange(geo, time)


# Downloading and reading monthly temperature data from Berkeley Earth for Germany (as an example)

# url <- "http://berkeleyearth.lbl.gov/auto/Regional/TAVG/Text/germany-TAVG-Trend.txt"
# temp_data_germany <- read.table(url, skip=48, header=FALSE, comment.char="%")
# 
# # Filter out just the monthly data
# monthly_temp_germany <- temp_data_germany[temp_data_germany$V2 != 0 & !is.na(temp_data_germany$V3), c(1, 2, 3)]
# 
# # Rename columns for clarity
# colnames(monthly_temp_germany) <- c("Year", "Month", "Temperature_Anomaly")
# 
# # To get the absolute average monthly temperature, you'd need a reference temperature for Germany. 
# # For this example, let's assume a base temperature (this would ideally be an average over a longer historical period)
# base_temp <- 8.5 # example value
# monthly_temp_germany$Avg_Temperature <- base_temp + monthly_temp_germany$Temperature_Anomaly
# 
# head(monthly_temp_germany)



# Retrieve the industrial production index for the EU27
ind_prod_data <- get_eurostat("sts_inpr_m", time_format = "date")
df1 = label_eurostat(ind_prod_data, fix_duplicated = T)

# Filter for total industry excluding construction for the EU27
ind_prod_eu27 <- df1 %>%
  filter(geo == "EU27_2020" & nace_r2 == "Total industry (except construction)" & s_adj == "Seasonally adjusted data (SA)") %>%
  select(time, values)

head(ind_prod_eu27)
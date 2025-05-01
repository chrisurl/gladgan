### Load Data ### 
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
    stk_flow = "EXP",
    unit = "MIO-EUR-NSA"),
  cache = FALSE)

monYear = substr(Sys.Date(),1,7)
write_rds(df, paste0("data_ignore/df_",monYear,".rds"))

write_csv(df, paste0("data_ignore/df_",monYear,".csv"))


### Set-up ### 
set.seed(505)
monYear = substr(Sys.Date(),1,7)
library(tidyverse)
library(eurostat)
library(forecast)
library(parallel)
library(jsonlite)

### Functions ### 
scale2 <- function(x, na.rm = TRUE) (x - mean(x, na.rm = na.rm)) / sd(x, na.rm)

clean_data <- function(df){
  df |> 
    select(geo, time, values) |> 
    group_by(geo) |> 
    mutate(values_scale = scale2(values),
           values_log = log(values),
           values_scale_mean = mean(values, na.rm = T),
           values_scale_sd = sd(values, na.rm = T)) |> 
    ungroup() 
}

process_subset <- function(sub_length, df) {
  cat("Running: ", sub_length, "\n")
  # Subset the data for the current length
  data_subset <- tail(df, sub_length)
  
  # Fit ARIMA model
  cat(" ..auto.arima \n")
  fit <- auto.arima(data_subset)
  pred <- forecast(fit, 2)
  
  forecasts = tibble(
    date = as_date(zoo::as.yearmon(time(pred$mean))),
    value = as.numeric(pred$mean)
  )
  
  # Calculate in-sample AIC
  model_aic <- AIC(fit)
  model_bic <- BIC(fit)
  
  # Cross-validation for out-of-sample RMSE
  cat(" ..cv \n")
  cv_errors <- tsCV(data_subset, forecastfunction = function(x,h) forecast(fit, h = h), h = 2)
  cv_errors <- na.omit(cv_errors)
  rmse <- sqrt(mean(cv_errors[,2]^2, na.rm = TRUE))
  rmse_model = forecast::accuracy(fit)[2]
  rmse_12 <- if(nrow(cv_errors)>12){
    sqrt(mean(cv_errors[(nrow(cv_errors)-12):nrow(cv_errors),2]^2, na.rm = TRUE))
  }else{NA}
  rmse_6 <- if(nrow(cv_errors)>6){
    sqrt(mean(cv_errors[(nrow(cv_errors)-6):nrow(cv_errors),2]^2, na.rm = TRUE))
  }else{NA}
  rmse_2 <- if(nrow(cv_errors)>2){
    sqrt(mean(cv_errors[(nrow(cv_errors)-2):nrow(cv_errors),2]^2, na.rm = TRUE))
  }else{NA}
  # Store results
  
  results <- tibble(sub_length, rmse, rmse_12, rmse_6, rmse_2, rmse_model, AIC = model_aic, BIC = model_bic, as_tibble_row(arimaorder(fit))) %>%
    bind_cols(forecasts)
  
  return(results)
}

estimate_arima_models = function(data, country, series, num_cores, sub = 6){
  stopifnot(sub>0)
  
  df2 = data |> 
    filter(geo == country) |> 
    select(time, !!sym(series)) |> 
    drop_na()
  
  minDate = min(df2$time)
  df_ts = ts(df2 %>% pull(!!sym(series)), start = c(year(minDate), month(minDate)), frequency = 12)
  
  # Define the length of subsets you want to test
  sub_lengths <- c(6*(1:floor(length(df_ts)/6)), length(df_ts))
  
  # Run the function in parallel over subset lengths
  results_list <- mclapply(sub_lengths, process_subset, mc.cores = num_cores, df = df_ts)
  
  # Combine the list of results into a single data frame
  results <- do.call(bind_rows, results_list)
  results = results %>%
    add_column(geo = country, series)
  return(results)
}

### Estimation ### 
df = read_rds("data_ignore/df_2024-11.rds")
monYear = substr(Sys.Date(),1,7)

df = df |> 
  clean_data()

estimation_grid = expand.grid(
  series = c("values", "values_log"), 
  geo = unique(df$geo), stringsAsFactors = F)
num_cores <- detectCores()

results_list = map2(estimation_grid$geo, estimation_grid$series, \(x,y) estimate_arima_models(df, country = x, series = y, num_cores = num_cores, sub = 6))

results = do.call(bind_rows, results_list)

write_rds(results, file = paste0(getwd(),"/data_ignore/results_",monYear,".rds"))

entry1 = results %>%
  filter(geo != "EU27_2020") %>%
  mutate(yhat = if_else(series == "values", value, exp(value))) %>%
  group_by(geo, series) %>%
  filter(rmse_2 == min(rmse_2, na.rm = T)) %>%
  filter(date == "2024-11-01") %>%
  group_by(geo) %>%
  summarise(result = mean(value, na.rm = T)) %>%
  arrange(geo)

entry2 = results %>%
  filter(geo != "EU27_2020") %>%
  mutate(yhat = if_else(series == "values", value, exp(value))) %>%
  group_by(geo, series) %>%
  filter(rmse_12 == min(rmse_12, na.rm = T)) %>%
  filter(date == "2024-11-01") %>%
  group_by(geo) %>%
  summarise(result = mean(value, na.rm = T)) %>%
  arrange(geo)

entry3 = results %>%
  filter(geo != "EU27_2020") %>%
  mutate(yhat = if_else(series == "values", value, exp(value))) %>%
  group_by(geo, series) %>%
  filter(rmse_model == min(rmse_model, na.rm = T) |
           rmse_2 == min(rmse_2, na.rm = T) |
           rmse_6 == min(rmse_6, na.rm = T) |
           rmse_12 == min(rmse_12, na.rm = T)) %>%
  filter(date == "2024-11-01") %>%
  group_by(geo) %>%
  summarise(result = mean(value, na.rm = T)) %>%
  arrange(geo)

write_csv(entry1, file = paste0(getwd(),"/data_ignore/results_",monYear,"_entry1.csv"))
write_csv(entry2, file = paste0(getwd(),"/data_ignore/results_",monYear,"_entry2.csv"))
write_csv(entry3, file = paste0(getwd(),"/data_ignore/results_",monYear,"_entry3.csv"))


### Export ### 
monYear = substr(Sys.Date(),1,7)
entry1 = read_csv("data_ignore/results_2024-11_entry1.csv") %>%
  mutate(entry = "entry_1")
entry2 = read_csv("data_ignore/results_2024-11_entry2.csv")%>%
  mutate(entry = "entry_2")
entry3 = read_csv("data_ignore/results_2024-11_entry3.csv")%>%
  mutate(entry = "entry_3")

df = bind_rows(entry1, entry2, entry3)

# Initialize an empty list to store the final JSON structure
json_structure <- list()
entries = unique(df$entry)
# Populate the structure
for (entry in entries) {
  # Filter data frame for the specific entry
  entry_data <- df[df$entry == entry, ]
  
  # Create a named list of predictions for each country
  entry_predictions <- setNames(as.list(entry_data$result), entry_data$geo)
  
  # Assign this list to the JSON structure under the entry name
  json_structure[[entry]] <- entry_predictions
}

# Convert the list to JSON and export to file
json_data <- toJSON(json_structure, pretty = TRUE, auto_unbox = TRUE, na = NULL)
write(json_data, paste0("results/",monYear,"/point_estimates.json"))

# Print JSON data to check the structure
cat(json_data)

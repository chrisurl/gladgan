monYear = substr(Sys.Date(),1,7)
df = read_rds(paste0("data_ignore/df_",monYear,".rds"))

df = df |> 
  clean_data()

estimation_grid = expand.grid(
  series = c("values", "values_log"), 
  geo = unique(df$geo), stringsAsFactors = F)
num_cores <- detectCores()

results_list = map2(estimation_grid$geo, estimation_grid$series, \(x,y) estimate_arima_models(df, country = x, series = y, num_cores = num_cores, sub = 6))

results = do.call(bind_rows, results_list)

write_rds(results, file = paste0(getwd(),"/data_ignore/results_",monYear,".rds"))

dateFilter = paste0(monYear,"-01")

entry1 = results %>%
  filter(geo != "EU27_2020") %>%
  mutate(yhat = if_else(series == "values", value, exp(value))) %>%
  group_by(geo, series) %>%
  filter(rmse_2 == min(rmse_2, na.rm = T)) %>%
  filter(date == dateFilter) %>%
  group_by(geo) %>%
  summarise(result = mean(yhat, na.rm = T)) %>%
  arrange(geo)

entry2 = results %>%
  filter(geo != "EU27_2020") %>%
  mutate(yhat = if_else(series == "values", value, exp(value))) %>%
  group_by(geo, series) %>%
  filter(rmse_12 == min(rmse_12, na.rm = T)) %>%
  filter(date == dateFilter) %>%
  group_by(geo) %>%
  summarise(result = mean(yhat, na.rm = T)) %>%
  arrange(geo)

entry3 = results %>%
  filter(geo != "EU27_2020") %>%
  mutate(yhat = if_else(series == "values", value, exp(value))) %>%
  group_by(geo, series) %>%
  filter(rmse_model == min(rmse_model, na.rm = T) |
           rmse_2 == min(rmse_2, na.rm = T) |
           rmse_6 == min(rmse_6, na.rm = T) |
           rmse_12 == min(rmse_12, na.rm = T)) %>%
  filter(date == dateFilter) %>%
  group_by(geo) %>%
  summarise(result = mean(yhat, na.rm = T)) %>%
  arrange(geo)

write_csv(entry1, file = paste0(getwd(),"/data_ignore/results_",monYear,"_entry1.csv"))
write_csv(entry2, file = paste0(getwd(),"/data_ignore/results_",monYear,"_entry2.csv"))
write_csv(entry3, file = paste0(getwd(),"/data_ignore/results_",monYear,"_entry3.csv"))

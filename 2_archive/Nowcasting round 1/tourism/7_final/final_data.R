library(tidyverse)

path = "../data/results/"

#### ARIMA #####
File = paste0(path, "arima_selector.csv")
selector = read_csv(file = File)
arima_sqrt = read_csv(paste0(path, "arima_sqrt.csv")) %>%
  select(date, country_code, yhat) %>%
  filter(date == "2023-04-01")
arima_std = read_csv(paste0(path, "arima_std.csv")) %>%
  select(date, country_code, yhat) %>%
  filter(date == "2023-04-01")

arima = full_join(arima_sqrt, arima_std, by = c("date", "country_code"))

out1 = selector %>%
  select(country_code, transform) %>%
  left_join(arima) %>%
  mutate(yhat = case_when(
    transform == "sqrt" ~ yhat.x,
    transform == "std" ~ yhat.y,
  )) %>%
  select(-c("yhat.x", "yhat.y"))

write_csv(out1, file=paste0(path,"arima_final.csv"))


##### ARIMAX ######
File = paste0(path, "arimax_fourier.csv")
ar1 = read_csv(File) %>%
  filter(date=="2023-04-01") %>%
  mutate(yhat = round(yhat, digits = 1))
write_csv(ar1, file=paste0(path,"arimax_final.csv"))

##### ARIMAX ######
File = paste0(path, "trends_results.csv")
ar1 = read_csv(File) %>%
  filter(date=="2023-04-01") %>%
  mutate(yhat = round(resid_total_hat, digits = 1)) %>%
  select(date, country_code, yhat) %>%
  arrange(country_code)
write_csv(ar1, file=paste0(path,"trends_final.csv"))

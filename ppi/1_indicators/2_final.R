library(tidyverse)

ar = read_csv(file="arima_forecasts.csv")
ar1 = ar %>%
  select(geo, date, yhat) %>%
  filter(date == "2023-04-01") %>%
  mutate(yhat = round(yhat,1))
write_csv(ar1, "arima_forecasts_final.csv")

ar = read_csv(file="arima_forecasts_short.csv")
ar1 = ar %>%
  select(geo, date, yhat) %>%
  filter(date == "2023-04-01") %>%
  mutate(yhat = round(yhat,1))
write_csv(ar1, "arima_forecasts_short_final.csv")

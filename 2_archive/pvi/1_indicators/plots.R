library(viridis)
library(scales)

df_ind %>%
  filter(geo == "AT") %>%
  ggplot(aes(x = date, y = obs_value_std)) +
  geom_line(size = 1) +
  #scale_color_viridis(discrete = T, option="turbo") +
  theme_bw() +
  labs(x = "Time", y = "PVI")

ts1 = ts(df_ind %>% filter(geo=="AT") %>% pull(obs_value_std), start = 1996, frequency = 12)
test1 = auto.arima(ts1)
test1
p1 = forecast(test1, h=4)

df1 = df_ind %>%
  filter(geo=="AT" & date >= "2022-03-01") %>%
  select(date, obs_value_std) %>%
  rename(y = obs_value_std) %>%
  add_column(type = "Actual")

df2 = tibble(date = zoo::as.Date(p1$mean), y=p1$mean, type = "Prediction") 

bind_rows(df1, df2) %>%
  ggplot(aes(x = date, y = y, color = type)) +
  geom_line(size = 1) +
  geom_point() +
  #scale_color_viridis(discrete = T, option="") +
  scale_x_date(date_breaks = "2 months") +
  theme_bw() +
  labs(x = "Time", y = "PVI", color = "Type")

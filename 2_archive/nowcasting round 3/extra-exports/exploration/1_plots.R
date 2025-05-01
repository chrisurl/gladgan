df %>%
  ggplot(aes(x = time, y = values)) + 
  geom_line() +
  theme_bw() +
  facet_wrap(vars(geo), ncol = 3, scales = "free_y")

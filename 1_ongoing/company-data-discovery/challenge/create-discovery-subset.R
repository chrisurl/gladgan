library(tidyverse)
set.seed(505)

runif(10,1,200)


a = discovery %>%
  distinct(NAME) %>%
  filter(row_number() %in% sample(1:200, 10))

write_csv(a, "1_ongoing/company-data-discovery/challenge/discovery-subset.csv")

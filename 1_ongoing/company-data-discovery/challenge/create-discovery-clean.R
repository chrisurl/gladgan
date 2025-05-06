library(tidyverse)

discovery = read_delim("1_ongoing/company-data-discovery/challenge/discovery.csv", delim = ";")

a = discovery %>%
  distinct(NAME)

write_csv(a, "1_ongoing/company-data-discovery/challenge/discovery-clean.csv")

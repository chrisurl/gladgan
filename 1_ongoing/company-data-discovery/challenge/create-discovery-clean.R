library(tidyverse)

discovery = read_delim("1_ongoing/company-data-discovery/challenge/discovery.csv", delim = ";")

a = discovery %>%
  distinct(NAME)

write_csv(a, "1_ongoing/company-data-discovery/challenge/discovery-clean.csv")

write_csv(a[1:100,], "1_ongoing/company-data-discovery/challenge/discovery-clean-h1.csv")
write_csv(a[101:200,], "1_ongoing/company-data-discovery/challenge/discovery-clean-h2.csv")

# Import data
library(data.table)
library(tidyverse)

### Indicators
datapath = "./tourism/data"
ind_path = paste0(datapath, "/indicators")
list.files(ind_path)
t_in = fread(paste0(ind_path,"/tour_occ_nim_linear.csv"))

df_t1 = t_in %>% as_tibble()

test1 = df_t1[,3:7] %>%
  filter(geo == 'EU27_2020') %>%
  distinct()
print(test1,  n=nrow(test1))

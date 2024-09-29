library(tidyverse)
library(rvest)

years = 2018:2023
months = 1:12  %>% as.character() %>% str_c("0",.) %>% str_sub(-2)

yearmonth = expand_grid(years, months) %>%
  mutate(all = str_c(years, months))

path = "https://ec.europa.eu/eurostat/api/dissemination/files?file=comext/COMEXT_DATA%2FPRODUCTS%2Ffull"
download_folder = "~/data/comext_raw/"

links = paste0(path, yearmonth$all, ".7z")
files = paste0(download_folder, yearmonth$all, ".7z")

map2(links, files, \(x,y) download.file(x,y))

# manual extraction necessary, too lazy to set up... 



### Background script for automatic download of GoogleTrends time series
# packages ####
library(data.table)
library(tidyverse)
library(lubridate)
library(gtrendsR)
library(trendecon)

# Set up ####
rm(list = ls())

### data path ####
datapath = "../data/"
trends_path = paste0(datapath, "googleTrendsAuto/")

### timeframe ####
time_set = "all"
sleep_mod = 3 # modolu: 1=sleep every time, the higher, the lesser
timeout_short_min = 1
timeout_short_max = 20
timeout_long_min = 45
timeout_long_max = 90

### valid countries ####
vol_ind = read_delim(paste0(datapath,"country_volatility_index.csv")) %>%
  mutate(geo = str_split(Countries, " ", simplify = T)[,1], .before = 1,
         country = str_remove(Countries, ".*\\("), 
         country = str_extract(country, ".*(?=\\))"))

country_code_list = unlist(vol_ind$geo)
country_list = unlist(vol_ind$country)
country_code_list[country_list=="Greece"] <- "GR"

# Download Data ####
### Searches with possible time lag ####
res_out = list()
print("Start: Trends for country")

for (i in seq_along(country_code_list)){
#for (i in 7:7){
  
  country_code = country_code_list[i]
  country = country_list[i]
  res1 = list()
  
  print(paste0("Country: ", country, " ", i, "/", length(country_list)))
  t_1 = Sys.time()
  test1 = ts_gtrends_mwd(keyword = country, 
                  geo=country_code,
                  
                  category = 67,
                  from="2022-01-01"
  )
  res1[[1]] = test1 %>% 
    add_column(country_code, .after = 1) %>%
    rename(country_cc_trav = value)
  
  z = runif(1,timeout_short_min,timeout_short_max)
  t_2 = Sys.time() - t_1
  print(paste0("   Part 1/7, Sleep: ",round(z,3)," sec, Dur:",round(t_2,3)))
  Sys.sleep(z)
  
  t_1 = Sys.time()
  test2 = ts_gtrends_mwd(keyword = country,
                   
                   category = 67
  )
  
  res1[[2]] = test2 %>% 
    add_column(country_code, .after = 1) %>%
    rename(country_trav = value)
  
  z = runif(1,timeout_short_min,timeout_short_max)
  t_2 = Sys.time() - t_1
  print(paste0("   Part 2/7, Sleep: ",round(z,3)," sec, Dur:",round(t_2,3)))
  Sys.sleep(z)
  
  t_1 = Sys.time()
  test3 = ts_gtrends_mwd(keyword = country, 
                  
                  category = 179
  )
  
  res1[[3]] = test3 %>%
    add_column(country_code, .after = 1) %>%
    rename(country_hotels = value)
  
  z = runif(1,timeout_short_min,timeout_short_max)
  t_2 = Sys.time() - t_1
  print(paste0("   Part 3/7, Sleep: ",round(z,3)," sec, Dur:",round(t_2,3)))
  Sys.sleep(z)
  
  t_1 = Sys.time()
  test4 = ts_gtrends_mwd(keyword = country, 
                  
                  category = 205
  )
  res1[[4]] = test4 %>%
    add_column(country_code, .after = 1) %>%
    rename(country_car_rent = value)
  
  z = runif(1,timeout_short_min,timeout_short_max)
  t_2 = Sys.time() - t_1
  print(paste0("   Part 4/7, Sleep: ",round(z,3)," sec, Dur:",round(t_2,3)))
  Sys.sleep(z)
  
  t_1 = Sys.time()
  test5 = ts_gtrends_mwd(keyword = country, 
                  
                  category = 378
  )
  res1[[5]] = test5 %>%
    add_column(country_code, .after = 1) %>%
    rename(country_appart = value)
    
  z = runif(1,timeout_short_min,timeout_short_max)
  t_2 = Sys.time() - t_1
  print(paste0("   Part 5/7, Sleep: ",round(z,3)," sec, Dur:",round(t_2,3)))
  Sys.sleep(z)
  
  t_1 = Sys.time()
  test6 = ts_gtrends_mwd(keyword = country, 
                  
                  category = 542
  )
  res1[[6]] = test6 %>% 
    add_column(country_code, .after = 1) %>%
    rename(country_hike = value)
  
  z = runif(1,timeout_short_min,timeout_short_max)
  t_2 = Sys.time() - t_1
  print(paste0("   Part 6/7, Sleep: ",round(z,3)," sec, Dur:",round(t_2,3)))
  Sys.sleep(z)
  
  t_1 = Sys.time()
  test7 = ts_gtrends_mwd(keyword = country, 
                  
                  category = 1011
  )
  res1[[7]] = test7 %>%
    add_column(country_code, .after = 1) %>%
    rename(country_trav_gui = value)
  
  z = runif(1,timeout_short_min,timeout_short_max)
  t_2 = Sys.time() - t_1
  print(paste0("   Part 7/7, Sleep: ",round(z,3)," sec, Dur:",round(t_2,3)))
  Sys.sleep(z)
  
  res_out[[i]] = reduce(res1, full_join)
  write_csv(res_out[[i]], file=paste0(trends_path, "part1_mwd/country_searches_",country_code,".csv"))
  
  if(i%%sleep_mod==0){
    z_2 = runif(1,timeout_long_min,timeout_long_max)
    print(paste0("   Extra sleep: ",round(z_2,3)," sec"))
    Sys.sleep(z_2)
  }else{
    print("   No extra sleep")
  }
}

#res_final = do.call(bind_rows,res_out)
#write_csv(res_final, file=paste0(trends_path, "country_searches.csv"))

### Searches in-country ####
res_in = list()
print("Trends for in-country searches")

for (i in seq_along(country_code_list)){
#for (i in 7:24){  
  country_code = country_code_list[i]
  country = country_list[i]
  res = list()
  print(paste0("Country: ", country, " ", i, "/", length(country_list)))
  
  t_1 = Sys.time()
  rest2 = ts_gtrends_mwd(keyword = , 
                  geo = country_code,
                  
                  category = 71 #food & drink
  )
  
  res[[1]] = rest2 %>%
    add_column(country_code, .after = 1) %>%
    rename(cc_fooddrink = value)
  
  z = runif(1,timeout_short_min,timeout_short_max)
  t_2 = Sys.time() - t_1
  print(paste0("   Part 1/4, Sleep: ",round(z,3)," sec, Dur:",round(t_2,3)))
  Sys.sleep(z)
  
  t_1 = Sys.time()
  rest3 = ts_gtrends_mwd(keyword = , 
                  geo = country_code,
                  
                 
                  category = 276 #restaurants
  )
  
  res[[2]] = rest3 %>%
    add_column(country_code, .after = 1) %>%
    rename(cc_restaurant = value) 
  
  z = runif(1,timeout_short_min,timeout_short_max)
  t_2 = Sys.time() - t_1
  print(paste0("   Part 2/4, Sleep: ",round(z,3)," sec, Dur:",round(t_2,3)))
  Sys.sleep(z)
  
  t_1 = Sys.time()
  rest4 = ts_gtrends_mwd(keyword = , 
                  geo = country_code,
                  
                  category = 121 #groceries
  )
  
  res[[3]] = rest4 %>%
    add_column(country_code, .after = 1) %>%
    rename(cc_groc = value) 
  
  z = runif(1,timeout_short_min,timeout_short_max)
  t_2 = Sys.time() - t_1
  print(paste0("   Part 3/4, Sleep: ",round(z,3)," sec, Dur:",round(t_2,3)))
  Sys.sleep(z)
  
  t_1 = Sys.time()
  rest5 = ts_gtrends_mwd(keyword = , 
                  geo = country_code,
                  
                  category = 918 #fast  food
  )
  
  res[[4]] = rest5 %>%
    add_column(country_code, .after = 1) %>%
    rename(cc_fastfood = value)
  
  z = runif(1,timeout_short_min,timeout_short_max)
  t_2 = Sys.time() - t_1
  print(paste0("   Part 4/4, Sleep: ",round(z,3)," sec, Dur:",round(t_2,3)))
  Sys.sleep(z)
  
  res_in[[i]] = reduce(res, full_join)
  write_csv(res_in[[i]], file=paste0(trends_path, "part2_mwd/country_searches_",country_code,".csv"))
  
  if(i%%sleep_mod==0 & i != 24){
    z_2 = runif(1,timeout_long_min,timeout_long_max)
    print(paste0("   Extra sleep: ", round(z_2,3)," sec"))
    Sys.sleep(z_2)
  }else{
    print("   No extra sleep")
  }
}

#res_incountry = do.call(bind_rows,res_in)
#write_csv(res_incountry, file=paste0(trends_path, "domnestic_searches.csv"))
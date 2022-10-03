### Background script for automatic download of GoogleTrends time series
# packages ####
library(data.table)
library(tidyverse)
library(lubridate)
library(gtrendsR)

# Set up ####
rm(list = ls())

### data path ####
datapath = "../data/"
trends_path = paste0(datapath, "googleTrendsAuto/")

### timeframe ####
time_set = "all"
sleep_mod = 3 # modolu: 1= extra sleep every time; higher sleep_mod, less sleep
timeout_short_min = 1
timeout_short_max = 10
timeout_long_min = 45
timeout_long_max = 90
wait_for = 5 # timeout before retry
tries = 5 # max number of retries

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
# for (i in 8:24){ 
  country_code = country_code_list[i]
  country = country_list[i]
  res1 = list()
  
  print(paste0("Country: ", country, " ", i, "/", length(country_list)))
  t_1 = Sys.time()
  test1 = retry::retry(gtrends(keyword = country, 
                  geo=country_code,
                  time=time_set,
                  gprop = c("web", "news", "images", "froogle", "youtube"),
                  category = 67,
                  onlyInterest = T
                  ),
    when = "Status code was not 200. Returned status code:429",
    interval = wait_for, 
    max_tries = tries
  )
  
  res1[[1]] = test1$interest_over_time %>% 
    as_tibble() %>%
    mutate(hits = case_when(hits == "<1" ~ 0.5,
                            TRUE ~ as.numeric(hits)),
           hits = as.numeric(hits),
           date = as_date(date)) %>%
    add_column(country_code, .after = 1) %>%
    rename(country_cc_trav = hits) %>%
    .[1:3]
  
  z = runif(1,timeout_short_min,timeout_short_max)
  t_2 = Sys.time() - t_1
  print(paste0("   Part 1/7, Sleep: ",round(z,3)," sec, Dur:",round(t_2,3)))
  Sys.sleep(z)
  
  t_1 = Sys.time()
  test2 = retry::retry(gtrends(keyword = country,
                   time=time_set,
                   gprop = c("web", "news", "images", "froogle", "youtube"),
                   category = 67,
                   onlyInterest = T
                  ),
  when = "Status code was not 200. Returned status code:429",
  interval = wait_for, 
  max_tries = tries
  )
  
  res1[[2]] = test2$interest_over_time %>% 
    as_tibble() %>%
    mutate(hits = case_when(hits == "<1" ~ 0.5,
                            TRUE ~ as.numeric(hits)),
           hits = as.numeric(hits),
           date = as_date(date)) %>%
    add_column(country_code, .after = 1) %>%
    rename(country_trav = hits) %>%
    .[1:3]
  
  z = runif(1,timeout_short_min,timeout_short_max)
  t_2 = Sys.time() - t_1
  print(paste0("   Part 2/7, Sleep: ",round(z,3)," sec, Dur:",round(t_2,3)))
  Sys.sleep(z)
  
  t_1 = Sys.time()
  test3 = retry::retry(gtrends(keyword = country, 
                  time=time_set,
                  gprop = c("web", "news", "images", "froogle", "youtube"),
                  category = 179,
                  onlyInterest = T
  ),
  when = "Status code was not 200. Returned status code:429",
  interval = wait_for, 
  max_tries = tries
  )
  
  res1[[3]] = test3$interest_over_time %>% 
    as_tibble() %>%
    mutate(hits = case_when(hits == "<1" ~ 0.5,
                            TRUE ~ as.numeric(hits)),
           hits = as.numeric(hits),
           date = as_date(date)) %>%
    add_column(country_code, .after = 1) %>%
    rename(country_hotels = hits) %>%
    .[1:3]
  
  z = runif(1,timeout_short_min,timeout_short_max)
  t_2 = Sys.time() - t_1
  print(paste0("   Part 3/7, Sleep: ",round(z,3)," sec, Dur:",round(t_2,3)))
  Sys.sleep(z)
  
  t_1 = Sys.time()
  test4 = retry::retry(gtrends(keyword = country, 
                  time=time_set,
                  gprop = c("web", "news", "images", "froogle", "youtube"),
                  category = 205,
                  onlyInterest = T
  ),
  when = "Status code was not 200. Returned status code:429",
  interval = wait_for, 
  max_tries = tries
  )
  
  res1[[4]] = test4$interest_over_time %>% 
    as_tibble() %>%
    mutate(hits = case_when(hits == "<1" ~ 0.5,
                            TRUE ~ as.numeric(hits)),
           hits = as.numeric(hits),
           date = as_date(date)) %>%
    add_column(country_code, .after = 1) %>%
    rename(country_car_rent = hits) %>%
    .[1:3]
  
  z = runif(1,timeout_short_min,timeout_short_max)
  t_2 = Sys.time() - t_1
  print(paste0("   Part 4/7, Sleep: ",round(z,3)," sec, Dur:",round(t_2,3)))
  Sys.sleep(z)
  
  t_1 = Sys.time()
  test5 = retry::retry(gtrends(keyword = country, 
                  time=time_set,
                  gprop = c("web", "news", "images", "froogle", "youtube"),
                  category = 378,
                  onlyInterest = T
  ),
  when = "Status code was not 200. Returned status code:429",
  interval = wait_for, 
  max_tries = tries
  )
  
  res1[[5]] = test5$interest_over_time %>% 
    as_tibble() %>%
    mutate(hits = case_when(hits == "<1" ~ 0.5,
                            TRUE ~ as.numeric(hits)),
           hits = as.numeric(hits),
           date = as_date(date)) %>%
    add_column(country_code, .after = 1) %>%
    rename(country_appart = hits) %>%
    .[1:3]
  
  z = runif(1,timeout_short_min,timeout_short_max)
  t_2 = Sys.time() - t_1
  print(paste0("   Part 5/7, Sleep: ",round(z,3)," sec, Dur:",round(t_2,3)))
  Sys.sleep(z)
  
  t_1 = Sys.time()
  test6 = retry::retry(gtrends(keyword = country, 
                  time=time_set,
                  gprop = c("web", "news", "images", "froogle", "youtube"),
                  category = 542,
                  onlyInterest = T
  ),
  when = "Status code was not 200. Returned status code:429",
  interval = wait_for, 
  max_tries = tries
  )
  
  res1[[6]] = test6$interest_over_time %>% 
    as_tibble() %>%
    mutate(hits = case_when(hits == "<1" ~ 0.5,
                            TRUE ~ as.numeric(hits)),
           hits = as.numeric(hits),
           date = as_date(date)) %>%
    add_column(country_code, .after = 1) %>%
    rename(country_hike = hits) %>%
    .[1:3]
  z = runif(1,timeout_short_min,timeout_short_max)
  t_2 = Sys.time() - t_1
  print(paste0("   Part 6/7, Sleep: ",round(z,3)," sec, Dur:",round(t_2,3)))
  Sys.sleep(z)
  
  t_1 = Sys.time()
  test7 = retry::retry(gtrends(keyword = country, 
                  time=time_set,
                  gprop = c("web", "news", "images", "froogle", "youtube"),
                  category = 1011,
                  onlyInterest = T
  ),
  when = "Status code was not 200. Returned status code:429",
  interval = wait_for, 
  max_tries = tries
  )
  
  res1[[7]] = test7$interest_over_time %>% 
    as_tibble() %>%
    mutate(hits = case_when(hits == "<1" ~ 0.5,
                            TRUE ~ as.numeric(hits)),
           hits = as.numeric(hits),
           date = as_date(date)) %>%
    add_column(country_code, .after = 1) %>%
    rename(country_trav_gui = hits) %>%
    .[1:3]
  z = runif(1,timeout_short_min,timeout_short_max)
  t_2 = Sys.time() - t_1
  print(paste0("   Part 7/7, Sleep: ",round(z,3)," sec, Dur:",round(t_2,3)))
  Sys.sleep(z)
  
  res_out[[i]] = reduce(res1, full_join)
  write_csv(res_out[[i]], file=paste0(trends_path, "part1/country_searches_",country_code,".csv"))
  
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
  
  country_code = country_code_list[i]
  country = country_list[i]
  res = list()
  print(paste0("Country: ", country, " ", i, "/", length(country_list)))
  
  t_1 = Sys.time()
  rest2 = retry::retry(gtrends(keyword = , 
                  geo = country_code,
                  time=time_set,
                  gprop = c("web", "news", "images", "froogle", "youtube"),
                  category = 71, #food & drink
                  onlyInterest = T
  ),
  when = "Status code was not 200. Returned status code:429",
  interval = wait_for, 
  max_tries = tries
  )
  
  res[[1]] = rest2$interest_over_time %>% 
    as_tibble() %>%
    mutate(hits = case_when(hits == "<1" ~ 0.5,
                            TRUE ~ as.numeric(hits)),
           hits = as.numeric(hits),
           date = as_date(date)) %>%
    add_column(country_code, .after = 1) %>%
    rename(cc_fooddrink = hits) %>%
    .[1:3]
  z = runif(1,timeout_short_min,timeout_short_max)
  t_2 = Sys.time() - t_1
  print(paste0("   Part 1/4, Sleep: ",round(z,3)," sec, Dur:",round(t_2,3)))
  Sys.sleep(z)
  
  t_1 = Sys.time()
  rest3 = retry::retry(gtrends(keyword = , 
                  geo = country_code,
                  time=time_set,
                  gprop = c("web", "news", "images", "froogle", "youtube"),
                  category = 276, #restaurants
                  onlyInterest = T
  ),
  when = "Status code was not 200. Returned status code:429",
  interval = wait_for, 
  max_tries = tries
  )
  
  res[[2]] = rest3$interest_over_time %>% 
    as_tibble() %>%
    mutate(hits = case_when(hits == "<1" ~ 0.5,
                            TRUE ~ as.numeric(hits)),
           hits = as.numeric(hits),
           date = as_date(date)) %>%
    add_column(country_code, .after = 1) %>%
    rename(cc_restaurant = hits) %>%
    .[1:3]
  z = runif(1,timeout_short_min,timeout_short_max)
  t_2 = Sys.time() - t_1
  print(paste0("   Part 2/4, Sleep: ",round(z,3)," sec, Dur:",round(t_2,3)))
  Sys.sleep(z)
  
  t_1 = Sys.time()
  rest4 = retry::retry(gtrends(keyword = , 
                  geo = country_code,
                  time=time_set,
                  gprop = c("web", "news", "images", "froogle", "youtube"),
                  category = 121, #groceries
                  onlyInterest = T
  ),
  when = "Status code was not 200. Returned status code:429",
  interval = wait_for, 
  max_tries = tries
  )
  
  res[[3]] = rest4$interest_over_time %>% 
    as_tibble() %>%
    mutate(hits = case_when(hits == "<1" ~ 0.5,
                            TRUE ~ as.numeric(hits)),
           hits = as.numeric(hits),
           date = as_date(date)) %>%
    add_column(country_code, .after = 1) %>%
    rename(cc_groc = hits) %>%
    .[1:3]
  z = runif(1,timeout_short_min,timeout_short_max)
  t_2 = Sys.time() - t_1
  print(paste0("   Part 3/4, Sleep: ",round(z,3)," sec, Dur:",round(t_2,3)))
  Sys.sleep(z)
  
  t_1 = Sys.time()
  rest5 = retry::retry(gtrends(keyword = , 
                  geo = country_code,
                  time=time_set,
                  gprop = c("web", "news", "images", "froogle", "youtube"),
                  category = 918, #fast  food
                  onlyInterest = T
  ),
  when = "Status code was not 200. Returned status code:429",
  interval = wait_for, 
  max_tries = tries
  )
  
  res[[4]] = rest5$interest_over_time %>% 
    as_tibble() %>%
    mutate(hits = case_when(hits == "<1" ~ 0.5,
                            TRUE ~ as.numeric(hits)),
           hits = as.numeric(hits),
           date = as_date(date)) %>%
    add_column(country_code, .after = 1) %>%
    rename(cc_fastfood = hits) %>%
    .[1:3]
  z = runif(1,timeout_short_min,timeout_short_max)
  t_2 = Sys.time() - t_1
  print(paste0("   Part 4/4, Sleep: ",round(z,3)," sec, Dur:",round(t_2,3)))
  Sys.sleep(z)
  
  res_in[[i]] = reduce(res, full_join)
  write_csv(res_in[[i]], file=paste0(trends_path, "part2/country_searches_",country_code,".csv"))
  
  if(i%%sleep_mod==0){
    z_2 = runif(1,timeout_long_min,timeout_long_max)
    print(paste0("   Extra sleep: ", round(z_2,3)," sec"))
    Sys.sleep(z_2)
  }else{
    print("   No extra sleep")
  }
}

#res_incountry = do.call(bind_rows,res_in)
#write_csv(res_incountry, file=paste0(trends_path, "domnestic_searches.csv"))
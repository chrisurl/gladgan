library(data.table)
library(lubridate)
library(xgboost)
library(caret)
library(rai)
library(forecast)
library(parallel)
library(doParallel)
library(doRNG)
library(tidyverse)


datapath = "../data/"
trends_path = paste0(datapath, "googleTrendsAuto/")
ind_path = paste0(datapath, "indicators/")
scale2 <- function(x, na.rm = TRUE) (x - mean(x, na.rm = na.rm)) / sd(x, na.rm)

lag_trends = function(lags, input_ds, col_pos){
  
  out = list()
  for(i in seq_along(col_pos)){
    col_sel = col_pos[i]
    t_out = list()
    for(j in seq_along(lags)){
      t_out[[j]] = dplyr::lag(input_ds[,col_sel],lags[j])
    }
    out[[i]] = do.call(cbind,t_out)
    if(ncol(out[[i]]) > 1){
      colnames(out[[i]]) = paste0(colnames(input_ds)[col_sel], "_lag", lags) 
    }
  }
  res = do.call(cbind,out)
  return(res)
}


vol_ind = read_delim(paste0(datapath,"country_volatility_index.csv")) %>%
  mutate(geo = str_split(Countries, " ", simplify = T)[,1], .before = 1,
         country = str_remove(Countries, ".*\\("), 
         country = str_extract(country, ".*(?=\\))"))

country_code_list = unlist(vol_ind$geo)
country_list = unlist(vol_ind$country)
country_code_list[country_list=="Greece"] <- "GR"

list.files(ind_path)
ind_in = fread(paste0(ind_path,"tour_occ_nim_linear_all.csv"))

ind_t1 = ind_in[,-c(1:3)] %>% 
  as_tibble() %>%
  mutate(geo = case_when(
    geo == "EL" ~ "GR",
    TRUE ~ geo
  )) %>%
  mutate(month_end = as_date(paste0(TIME_PERIOD,"-01")),.before=1) %>%
  filter(geo %in% country_code_list)

df_ind = ind_t1 %>%
  filter(nace_r2 == "I551-I553" & unit=="NR") %>%
  group_by(geo, c_resid) %>%
  mutate(obs_value_std = scale2(OBS_VALUE), mean=mean(OBS_VALUE), sd = sd(OBS_VALUE)) %>%
  ungroup()

ind_wide = ind_t1 %>%
  filter(nace_r2 == "I551-I553" & unit=="NR") %>%
  mutate(obs_value_std = OBS_VALUE) %>%
  pivot_wider(id_cols = c(month_end, geo), names_from=c_resid, values_from = obs_value_std, names_prefix="resid_") %>%
  group_by(geo) %>%
  mutate(resid_DOM = coalesce(resid_DOM, resid_NAT),
         share_FOR = resid_FOR / resid_TOTAL,
         month = month(month_end),
         year = year(month_end),
         resid_DOM_STD = scale2(resid_DOM),
         resid_FOR_STD = scale2(resid_FOR),
         resid_TOTAL_STD = scale2(resid_TOTAL),
  ) %>%
  select(!resid_NAT) %>%
  ungroup() %>%
  arrange(geo,month_end)

ind_wide %>%
  filter(is.na(resid_DOM)) %>%
  distinct(geo)

ind_stats = ind_wide %>%
  group_by(geo) %>%
  summarise(resid_TOTAL_mean=mean(resid_TOTAL, na.rm = T), 
            resid_TOTAL_sd=sd(resid_TOTAL, na.rm = T), 
            resid_TOTAL_max=max(resid_TOTAL, na.rm = T), 
            resid_TOTAL_norm=max(abs(resid_TOTAL-mean(resid_TOTAL, na.rm = T)), na.rm=T)
  )

geo_minmax = ind_wide %>%
  group_by(geo) %>%
  summarise(min = min(year), max = max(year), min_date = min(month_end)+years(x=1))

list.files(trends_path)
goo = read_csv(paste0(trends_path, "trends_full.csv"))
trends_100 = goo %>%
  mutate(across(3:13, ~.x/100))
trends_norm = goo %>%
  mutate(across(3:13, scale2))


lt100 = lag_trends(lags = 0:11,input_ds = trends_100, col_pos = 3:13)
ltnorm = lag_trends(lags = 0:11,input_ds = trends_norm, col_pos = 3:13)

c_filter = trends_100 %>%
  group_by(country_code) %>%
  summarise(min_date = min(date) + years(1)) %>%
  select(country_code, min_date)

trends_100_lag = cbind(trends_100[,1:2],lt100) %>%
  as_tibble() %>%
  left_join(c_filter) %>%
  filter(date >= min_date) %>%
  select(!min_date)

trends_norm_lag = cbind(trends_norm[,1:2],ltnorm) %>%
  as_tibble() %>%
  left_join(c_filter) %>%
  filter(date >= min_date)%>%
  select(!min_date)

trends100 = ind_wide %>%
  select(month_end, geo, resid_TOTAL_STD) %>%
  rename(date = month_end, country_code = geo) %>%
  inner_join(trends_100, by=c("date", "country_code"))

trendsnorm = ind_wide %>%
  select(month_end, geo, resid_TOTAL_STD) %>%
  rename(date = month_end, country_code = geo) %>%
  inner_join(trends_norm, by=c("date", "country_code"))

trends100_lag = ind_wide %>%
  select(month_end, geo, resid_TOTAL_STD) %>%
  rename(date = month_end, country_code = geo) %>%
  inner_join(trends_100_lag, by=c("date", "country_code"))

trendsnorm_lag = ind_wide %>%
  select(month_end, geo, resid_TOTAL_STD) %>%
  rename(date = month_end, country_code = geo) %>%
  inner_join(trends_norm_lag, by=c("date", "country_code"))



write_csv(trends100, paste0(datapath,"trends_100.csv"))
write_csv(trendsnorm, paste0(datapath,"trends_norm.csv"))
write_csv(trends100_lag, paste0(datapath,"trends_100_lag.csv"))
write_csv(trendsnorm_lag, paste0(datapath,"trends_norm_lag.csv"))
write_csv(ind_stats, paste0(datapath,"indicator_stats.csv"))
write_csv(ind_wide, paste0(datapath,"indicator_wide.csv"))

################# SELEKTOR ##################


model_google_trends <- function(trends, out_name, cl = detectCores()-1, country_code_list, country_list){
  #registerDoRNG(cl)
  
  out_list = list()
  
  out_list = foreach(i = 1:length(country_code_list), .packages=c("tidyverse","forecast", "rai", "caret"),
                     .verbose = F) %do% {
    registerDoParallel(cores = 7)
    print(paste0("Country ", i,"/24"))
    
    c_code = country_code_list[i]
    ctry = country_list[i]
    
    trends_cty = trends %>%
      filter(country_code == c_code) %>%
      zoo::na.locf() #carry last obs forward
    
    theData = trends_cty %>%
      .[,-c(1:3)]
    
    theResponse = trends_cty %>% 
      .$resid_TOTAL_STD
    
    stats_list = list()
    
    mod_rai = rai(theData = theData, theResponse = theResponse)
    (rai_sum = summary(mod_rai$model))
    
    sig_sq = (rai_sum$sigma)^2
    
    stats_list[[1]] = data.frame(country = unlist(ctry),
                                 TrainRMSE = RMSE(predict(mod_rai, theData),theResponse),
                                 TrainRsquared  = rai_sum$r.squared,
                                 TrainMAE = MAE(predict(mod_rai, theData),theResponse),
                                 method = "RAI")
    
    # X = as.matrix(theData)
    # mod1 = auto.arima(y = theResponse, max.order = 12, xreg = X,  max.D = 2)
    # ar_sum = summary(mod1)
    # 
    # stats_list[[2]] = data.frame(country = country_list[i],
    #                              TrainRMSE = RMSE(ar_sum$fitted, ar_sum$x),
    #                              TrainRsquared  = NA,
    #                              TrainMAE = MAE(ar_sum$fitted, ar_sum$x),
    #                              method = "ARIMAX")
    theData = as.data.frame(theData)
    
    fitControl <- caret::trainControl(method = "repeatedcv",
                                      number = 20, ## 20-fold CV..., only want to predict small amounts of data
                                      repeats = 10)  ## repeated 10 times
    mod_svn =caret::train(x=theData, y=theResponse, method="svmRadialSigma", trControl = fitControl)
    stats_list[[2]] = getTrainPerf(mod_svn) %>% 
      add_column(country = country_list[i], .before = 1)
    
    gbmGrid <-  expand.grid(interaction.depth = c(1:4), 
                            n.trees = c(20,50,75,100, 150, 200,350,500), 
                            shrinkage = 0.1,
                            n.minobsinnode = 5)
    mod_gbm =caret::train(x=theData, y=theResponse, method="gbm", trControl = fitControl, tuneGrid=gbmGrid, verbose=F)
    
    stats_list[[3]] = getTrainPerf(mod_gbm) %>% 
      add_column(country = country_list[i], .before = 1)
    
    mod_rf =caret::train(x=theData, y=theResponse, method="rf", trControl = fitControl, verbose=F)
    stats_list[[4]] = getTrainPerf(mod_rf) %>% 
      add_column(country = country_list[i], .before = 1)
    
    mod_brnn =caret::train(x=theData, y=theResponse, method="brnn", trControl = fitControl, verbose=F)
    stats_list[[5]] = getTrainPerf(mod_brnn) %>% 
      add_column(country = country_list[i], .before = 1)
    
    xgb_trcontrol = trainControl(
      method = "cv",
      number = 5,  
      allowParallel = FALSE,
      verboseIter = FALSE,
      returnData = FALSE
    )
    
    xgbGrid <- expand.grid(nrounds = c(50,100,200,250),  # this is n_estimators in the python code above
                           max_depth = c(1:4, 10, 15, 20, 25),
                           colsample_bytree = seq(0.5, 0.9, length.out = 5),
                           ## The values below are default values in the sklearn-api. 
                           eta = 0.1,
                           gamma=0,
                           min_child_weight = 1,
                           subsample = 1
    )
    xgb_model = caret::train(x=theData, y=theResponse,  
                             trControl = xgb_trcontrol,
                             tuneGrid = xgbGrid,
                             method = "xgbTree"
    )
    
    stats_list[[6]] = getTrainPerf(xgb_model) %>% 
      add_column(country = country_list[i], .before = 1)
    
    mod_svn2 =caret::train(x=theData, y=theResponse, method="svmPoly", trControl = fitControl, verbose=F)
    stats_list[[7]] = getTrainPerf(mod_svn2) %>% 
      add_column(country = country_list[i], .before = 1)
    
    
    mod_svn3 =caret::train(x=theData, y=theResponse, method="svmLinear3", trControl = fitControl, verbose=F)
    stats_list[[8]] = getTrainPerf(mod_svn3) %>% 
      add_column(country = country_list[i], .before = 1)
    
    stopImplicitCluster()
    res_df = do.call(rbind, stats_list)
  }
  
  #stopImplicitCluster()
  stats = do.call(bind_rows, out_list)
  
  write_csv(stats, paste0("stats_all",out_name,".csv"))
}

model_google_trends(trends = trends100, out_name="trends_100", cl = 4, 
                    country_code_list=country_code_list,  country_list=country_list)
model_google_trends(trends = trendsnorm, out_name="trends_norm", cl = 4,
                    country_code_list=country_code_list,  country_list=country_list)
model_google_trends(trends = trends100_lag, out_name="trends_100_lag",cl = 4,
                    country_code_list=country_code_list,  country_list=country_list)
model_google_trends(trends = trendsnorm_lag, out_name="trends_norm_lag", cl = 4,
                    country_code_list=country_code_list, country_list=country_list)

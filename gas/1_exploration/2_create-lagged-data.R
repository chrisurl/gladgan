# libs ----
library(tidyverse)
library(forecast)
library(rai)
library(xgboost)
library(caret)

library(doParallel)
registerDoParallel(10)


# functions ----
lag_trends = function(lags, input_ds, col_pos, group = NA){
  if(is.na(group)){
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
  }else{
    out = list()
    for(i in seq_along(col_pos)){
      col_sel = colnames(input_ds)[col_pos[i]]
      t_out = list()
      for(j in seq_along(lags)){
        t_out[[j]] = input_ds %>%
          select(all_of(c(col_sel,group))) %>%
          group_by(!!sym(group)) %>%
          mutate(new = dplyr::lag(!!sym(col_sel), n = lags[j])) %>%
          ungroup() %>%
          pull(new)
      }
      
      out[[i]] = do.call(cbind,t_out)
      if(ncol(out[[i]]) > 1){
        colnames(out[[i]]) = paste0(col_sel, "_lag", lags) 
      }
    }
    res = do.call(cbind,out)
    return(res)
  }
  
}

lag_trends_ts = function(lags, input_ts, col_pos){
  stopifnot(is.ts(input_ts))
  
  out = list()
  lags_neg = -1*lags
  
  for(i in seq_along(col_pos)){
    col_sel = col_pos[i]
    t_out = list()
    for(j in seq_along(lags)){
      t_out[[j]] = stats::lag(input_ts[,col_sel],lags_neg[j])
    }
    out[[i]] = do.call(cbind,t_out)
    if(ncol(out[[i]]) > 1){
      colnames(out[[i]]) = paste0(colnames(input_ts)[col_sel], "_lag", lags) 
    }
    out[[i]] = fable::as_tsibble(out[[i]]) #need this for binding the data accurately
  }
  res = as.ts(do.call(bind_rows,out))
  return(res)
}

# extend data set ----

df2 = read_rds("../data/gas/df2.rds")
dfIn = df2[,-c(13:16)]

df1 = dfIn %>%
  mutate(month = as.character(lubridate::month(date))) %>%
  bind_cols(lag_trends(1:12, dfIn, 6:8, group = "geo")) %>%
  bind_cols(lag_trends(1:3, dfIn, 9:12, group = "geo"))
  
df1_log = df1 %>%
  mutate(across(where(is.numeric) & -contains(c("temp_avg", "prcp_sum", "t_min", "t_max")), log))

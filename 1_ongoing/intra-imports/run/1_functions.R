scale2 <- function(x, na.rm = TRUE) (x - mean(x, na.rm = na.rm)) / sd(x, na.rm)

clean_data <- function(df){
  df |> 
    select(geo, time, values) |> 
    group_by(geo) |> 
    mutate(values_scale = scale2(values),
           values_log = log(values),
           values_scale_mean = mean(values, na.rm = T),
           values_scale_sd = sd(values, na.rm = T)) |> 
    ungroup() 
}

process_subset <- function(sub_length, df) {
  cat("Running: ", sub_length, "\n")
  # Subset the data for the current length
  data_subset <- tail(df, sub_length)
  
  # Fit ARIMA model
  cat(" ..auto.arima \n")
  fit <- auto.arima(data_subset)
  pred <- forecast(fit, 2)
  
  forecasts = tibble(
    date = as_date(zoo::as.yearmon(time(pred$mean))),
    value = as.numeric(pred$mean)
  )
  
  # Calculate in-sample AIC
  model_aic <- AIC(fit)
  model_bic <- BIC(fit)
  
  # Cross-validation for out-of-sample RMSE
  cat(" ..cv \n")
  cv_errors <- tsCV(data_subset, forecastfunction = function(x,h) forecast(fit, h = h), h = 2)
  cv_errors <- na.omit(cv_errors)
  rmse <- sqrt(mean(cv_errors[,2]^2, na.rm = TRUE))
  rmse_model = forecast::accuracy(fit)[2]
  rmse_12 <- if(nrow(cv_errors)>12){
    sqrt(mean(cv_errors[(nrow(cv_errors)-12):nrow(cv_errors),2]^2, na.rm = TRUE))
  }else{NA}
  rmse_6 <- if(nrow(cv_errors)>6){
    sqrt(mean(cv_errors[(nrow(cv_errors)-6):nrow(cv_errors),2]^2, na.rm = TRUE))
  }else{NA}
  rmse_2 <- if(nrow(cv_errors)>2){
    sqrt(mean(cv_errors[(nrow(cv_errors)-2):nrow(cv_errors),2]^2, na.rm = TRUE))
  }else{NA}
  # Store results
  
  results <- tibble(sub_length, rmse, rmse_12, rmse_6, rmse_2, rmse_model, AIC = model_aic, BIC = model_bic, as_tibble_row(arimaorder(fit))) %>%
    bind_cols(forecasts)
  
  return(results)
}

estimate_arima_models = function(data, country, series, num_cores, sub = 6){
  stopifnot(sub>0)
  
  df2 = data |> 
    filter(geo == country) |> 
    select(time, !!sym(series)) |> 
    drop_na()
  
  minDate = min(df2$time)
  df_ts = ts(df2 %>% pull(!!sym(series)), start = c(year(minDate), month(minDate)), frequency = 12)
  
  # Define the length of subsets you want to test
  sub_lengths <- c(6*(1:floor(length(df_ts)/6)), length(df_ts))
  
  # Run the function in parallel over subset lengths
  results_list <- mclapply(sub_lengths, process_subset, mc.cores = num_cores, df = df_ts)
  
  # Combine the list of results into a single data frame
  results <- do.call(bind_rows, results_list)
  results = results %>%
    add_column(geo = country, series)
  return(results)
}
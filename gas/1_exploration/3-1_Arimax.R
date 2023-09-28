library(tidyverse)
library(tseries)
library(forecast)

#df2 = read_rds("~/Desktop/df2.rds")

dfDe = df2 |>
  filter(geo == "DE")

df = dfDe |>
  select(-(nrg_bal:unit)) |>
  mutate(prcp_lag1 = lag(prcp_sum),
         year = year(date),
         month = as.character(month(date))) |>
  group_by(geo, year) |>
  mutate(prcp_lag1_cumsum = cumsum(coalesce(prcp_lag1,0)),
         target_log = log(values),
         target_sqrt = sqrt(values))

dfTs = ts(df$values, start = c(2008,1), frequency = 12)
plot(dfTs)
pacf(dfTs)
acf(dfTs)
adf.test(dfTs)
kpss.test(dfTs)



dfTsLog = ts(df$target_log, start = c(2008,1), frequency = 12)
pacf(dfTsLog)
acf(dfTsLog)
plot(dfTsLog)
adf.test(dfTsLog)
kpss.test(dfTsLog)
pp.test(dfTsLog)

auto.arima(dfTs)
mod0 = auto.arima(dfTsLog, stepwise = F)

X = cbind(temp = df$temp_avg, pvi1 = log(df$pvi_lag1), ppi1 = log(df$ppi_lag1), pvi12 = log(df$pvi_lag12), ppi12 = log(df$ppi_lag12), 
          prcp1 = log(df$prcp_lag1), prcp1Cum = log(df$prcp_lag1_cumsum))

#mod1 = auto.arima(dfTsLog, xreg = X[,c(1:3,6,7)])
#summary(mod1)
#plot(exp(mod1$residuals))

X2 = matrix(mapply(function(x) max(0,x), X), ncol = 7) |> na.omit()
colnames(X2) <- colnames(X)

mod2 = auto.arima(dfTsLog[-c(1:12)], xreg = X2)
summary(mod2)

fit_all_subsets <- function(dfTsLog, X2, criterion = "AICc") {
  
  ncol_X2 <- ncol(X2)
  all_models <- list()
  
  if (criterion == "AICc") {
    best_value <- Inf
  } else if (criterion == "BIC") {
    best_value <- Inf
  } else {
    stop("Invalid criterion. Please choose either 'AICc' or 'BIC'.")
  }
  
  best_model <- NULL
  
  for (i in 1:ncol_X2) {
    combos <- combn(ncol_X2, i)
    for (j in 1:ncol(combos)) {
      current_xreg <- X2[, combos[, j]]
      mod2 <- auto.arima(dfTsLog[-c(1:12)], xreg = current_xreg)
      all_models[[paste(colnames(X2)[combos[, j]], collapse = "_")]] <- mod2
      
      current_value <- ifelse(criterion == "AICc", mod2$aicc, mod2$bic)
      
      if (current_value < best_value) {
        best_value <- current_value
        best_model <- mod2
      }
    }
  }
  
  return(list(all_models = all_models, best_model = best_model))
}

# Usage:
result_aicc <- fit_all_subsets(dfTsLog, X2, criterion = "AICc")
best_model_aicc <- result_aicc$best_model
summary(best_model_aicc)

result_bic <- fit_all_subsets(dfTsLog, X2, criterion = "BIC")
best_model_bic <- result_bic$best_model
summary(best_model_bic)



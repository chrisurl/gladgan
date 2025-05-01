source("gas/1_exploration/2_create-lagged-data.R")

vol_index = read_delim("../data/gas/vol_index.csv", delim = ";")
volIndex = vol_index |>
  select(Countries, Weights) |>
  mutate(countryCode = substr(Countries, 1, 2))

clean_data <- function(df) {
  
  non_char_cols <- names(df)[sapply(df, function(col) !is.character(col))]
  
  cleaned_df <- df %>%
    rowwise() %>%
    filter(!any(is.infinite(c_across(all_of(non_char_cols)))) & 
             !any(is.na(c_across(all_of(non_char_cols)))))
  
  return(cleaned_df)
}

unique_geos <- unique(df1$geo) %>% intersect(volIndex$countryCode)
results <- list()
finalModelList = list()

for (i in seq_along(unique_geos)) {
  
  geoFilter = unique_geos[i]
  ## RAI Model ----
  theResponse = df1 %>%
    filter(geo== geoFilter & date >= "2009-01-01") %>%
    pull(values)
  
  theData = df1 %>%
    filter(geo==geoFilter & date >= "2009-01-01") %>%
    select(-c(1:6))
  
  theResponse2 = df1_log %>%
    filter(geo==geoFilter& date >= "2009-01-01") %>%
    pull(values)
  
  theData2 = df1_log %>%
    filter(geo==geoFilter & date >= "2009-01-01") %>%
    select(-c(1:6))
  
  cleaned_df <- theData2 |>
    mutate_if(is.character, as.numeric) |>
    bind_cols(theResponse2 = theResponse2) |>
    clean_data()
  
  theResponse3 = cleaned_df$theResponse2
  theData3 = cleaned_df |> select(-theResponse2)
  
  cleaned_df2 <- theData2 |>
    bind_cols(theResponse2 = theResponse2) |>
    clean_data()
  
  theResponse2 = cleaned_df2$theResponse2
  theData2 = cleaned_df2 |> select(-theResponse2)
  
  
  mod1 = rai(theData2, theResponse2)
  mod1RH = rai(theData2, theResponse2, alg = "RH")
  
  mod2 = rai(theData3, theResponse3)
  mod2RH = rai(theData3, theResponse3, alg = "RH")
  ## caret ----
  
  fitControl <- caret::trainControl(method = "repeatedcv",
                                    number = 15, ## 5-fold CV...
                                    repeats = 15)
  gbmGrid <-  expand.grid(interaction.depth = c(1:4), 
                          n.trees = c(50,75,100, 150, 200), 
                          shrinkage = 0.1,
                          n.minobsinnode = 5)
  
  mod_gbm =caret::train(x=theData3, y=theResponse3, method="gbm", trControl = fitControl, tuneGrid=gbmGrid, verbose=F)
  mod_rf =caret::train(x=theData3, y=theResponse3, method="rf")
  mod_svm1 =caret::train(x=theData3, y=theResponse3, method="svmPoly")
  mod_brnn =caret::train(x=theData3, y=theResponse3, method="brnn")
  mod_nnet =caret::train(x=theData3, y=theResponse3, method="pcaNNet", verbose = F)
  
  
  tuneGrid <- expand.grid(
    eta = c(0.01, 0.05, 0.1, 0.3),
    max_depth = c(3, 5, 7, 9),
    gamma = c(0, 0.1, 0.2, 0.3, 0.4),
    subsample = c(0.5, 0.75, 1),
    colsample_bytree = c(0.5, 0.75, 1),
    min_child_weight = c(1, 3, 5),
    nrounds = 100 # Again, you might also want to try other values
  )
  mod_xgb = caret::train(x = as.matrix(theData3), y = theResponse3, method = "xgbTree", verbose = F, tuneGrid = tuneGrid)
  
  
  tuneGrid <- expand.grid(
    eta = c(0.05, 0.1),
    max_depth = c(5, 7),
    gamma = c(0, 0.1, 0.2), # We can start with a single value like 0
    subsample = c(0.75, 1),
    colsample_bytree = 0.8,
    rate_drop = c(0.1, 0.2),
    skip_drop = c(0.1, 0.2),
    min_child_weight = 1, # Starting with a single common value like 1
    nrounds = 100
  )
  
  mod_xgb2 = caret::train(x = as.matrix(theData3), y = theResponse3, method = "xgbDART", verbose = F, tuneGrid = tuneGrid)
  
  tuneGrid <- expand.grid(
    alpha = c(0, 0.5, 1),  # L1 regularization
    lambda = c(0, 0.5, 1), # L2 regularization
    eta = c(0.01, 0.05, 0.1, 0.3),
    nrounds = c(50, 100, 150)
  )
  mod_xgb3 = caret::train(x = as.matrix(theData3), y = theResponse3, method = "xgbLinear", verbose = F, tuneGrid = tuneGrid)

   out <- list(
    mod1 = data.frame(TrainRMSE = RMSE(predict(mod1, theData2),theResponse2),
                      TrainRsquared  = summary(mod1)$stats$rS,
                      TrainMAE = MAE(predict(mod1, theData2),theResponse2),
                      method = "RAI full"),
    mod1RH = data.frame(TrainRMSE = RMSE(predict(mod1RH, theData2),theResponse2),
                        TrainRsquared  = summary(mod1RH)$stats$rS,
                        TrainMAE = MAE(predict(mod1RH, theData2),theResponse2),
                        method = "RAI RH full"),
    mod2 = data.frame(TrainRMSE = RMSE(predict(mod2, theData3),theResponse3),
                      TrainRsquared  = summary(mod2)$stats$rS,
                      TrainMAE = MAE(predict(mod2, theData3),theResponse3),
                      method = "RAI month num"),
    mod2RH = data.frame(TrainRMSE = RMSE(predict(mod2RH, theData3),theResponse3),
                        TrainRsquared  = summary(mod2RH)$stats$rS,
                        TrainMAE = MAE(predict(mod2RH, theData3),theResponse3),
                        method = "RAI month num RH"),
    mod_gbm = getTrainPerf(mod_gbm),
    mod_rf = getTrainPerf(mod_rf),
    mod_svm1 = getTrainPerf(mod_svm1),
    mod_brnn = getTrainPerf(mod_brnn),
    mod_nnet = getTrainPerf(mod_nnet),
    mod_xgb = getTrainPerf(mod_xgb),
    mod_xgb2 = getTrainPerf(mod_xgb2),
    mod_xgb3 = getTrainPerf(mod_xgb3)
  )
   
   results[[geoFilter]] = cbind(do.call(rbind, out), geoFilter)
}

write_rds(results, "gas/2_estimation/1_best-models.rds")

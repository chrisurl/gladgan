source("gas/1_exploration/2_create-lagged-data.R")

clean_data <- function(df) {
  
  non_char_cols <- names(df)[sapply(df, function(col) !is.character(col))]
  
  cleaned_df <- df %>%
    rowwise() %>%
    filter(!any(is.infinite(c_across(all_of(non_char_cols)))) & 
             !any(is.na(c_across(all_of(non_char_cols)))))
  
  return(cleaned_df)
}
## RAI Model ----
theResponse = df1 %>%
  filter(geo=="DE"& date >= "2009-01-01") %>%
  pull(values)

theData = df1 %>%
  filter(geo=="DE" & date >= "2009-01-01") %>%
  select(-c(1:6))

theResponse2 = df1_log %>%
  filter(geo=="DE"& date >= "2009-01-01") %>%
  pull(values)

theData2 = df1_log %>%
  filter(geo=="DE" & date >= "2009-01-01") %>%
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


cleaned_df0 <- theData |>
  mutate_if(is.character, as.numeric) |>
  bind_cols(theResponse = theResponse) |>
  clean_data()

theResponse = cleaned_df0$theResponse
theData = cleaned_df0 |> select(-theResponse)

mod0 = rai(theData, theResponse)
summary(mod0$model)

mod1 = rai(theData2, theResponse2)
summary(mod1$model)

mod1RH = rai(theData2, theResponse2, alg = "RH")
summary(mod1RH$model)

mod2 = rai(theData3, theResponse3)
summary(mod2$model)
mod2RH = rai(theData3, theResponse3, alg = "RH")
summary(mod2RH$model)

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

mod_gbm2 =caret::train(x=theData3, y=theResponse3, method="gbm", trControl = fitControl, tuneGrid=gbmGrid, verbose=F)
mod_gbm2
mod_rf2 =caret::train(x=theData3, y=theResponse3, method="rf")
mod_rf2

mod_svm1 =caret::train(x=theData3, y=theResponse3, method="svmPoly")
mod_svm1
mod_brnn =caret::train(x=theData3, y=theResponse3, method="brnn")
mod_brnn
mod_nnet =caret::train(x=theData3, y=theResponse3, method="pcaNNet", verbose = F)
mod_nnet

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
mod_xgb

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
mod_xgb2
mod_xgb21 = caret::train(x = as.matrix(theData3), y = theResponse3, method = "xgbDART", verbose = F)
mod_xgb21
mod_xgb3 = caret::train(x = as.matrix(theData3), y = theResponse3, method = "xgbLinear", verbose = F)
mod_xgb3

set.seed(505)
monYear = substr(Sys.Date(),1,7)
library(tidyverse)
library(eurostat)
library(forecast)
library(parallel)
library(jsonlite)
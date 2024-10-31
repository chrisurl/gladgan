set.seed(505)
library(tidyverse)
library(eurostat)
library(forecast)
library(parallel)
library(jsonlite)

source("run/1_functions.R")
source("run/2_estimation.R")
source("run/3_export-json.R")
q() #End process to end caffeinate
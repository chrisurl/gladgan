### Background script for aggregating automatic download of GoogleTrends time series
# packages ####
library(data.table)
library(tidyverse)
library(lubridate)
library(gtrendsR)

# Set up ####
rm(list = ls())


### data path trendecon ####
datapath = "../data/"
trends_path = paste0(datapath, "googleTrendsAuto/")
path_1 = paste0(trends_path,"part1/")
path_2 = paste0(trends_path,"part2/")

# read in part 1 ####

filelist1 = paste0(path_1, list.files(path_1))

in1 = map(filelist1, read_csv)

df1 = do.call(bind_rows, in1)
write_csv(df1, file = paste0(trends_path, "trends_part1.csv"))

# read in part 2 ####
filelist2 = paste0(path_2, list.files(path_2))

in2 = map(filelist2, read_csv)

df2 = do.call(bind_rows, in2)
write_csv(df2, file = paste0(trends_path, "trends_part2.csv"))


### data path trendecon ####
datapath = "../data/"
trends_path = paste0(datapath, "googleTrendsAuto/")
path_1 = paste0(trends_path,"part1_trendecon/")
path_2 = paste0(trends_path,"part2_trendecon/")

# read in part 1 ####

filelist1 = paste0(path_1, list.files(path_1))

in1 = map(filelist1, read_csv)

df1 = do.call(bind_rows, in1)
write_csv(df1, file = paste0(trends_path, "trends_part1_trendecon.csv"))

# read in part 2 ####
filelist2 = paste0(path_2, list.files(path_2))

in2 = map(filelist2, read_csv)

df2 = do.call(bind_rows, in2)
write_csv(df2, file = paste0(trends_path, "trends_part2_trendecon.csv"))

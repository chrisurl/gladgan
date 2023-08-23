library(future)
library(furrr)
library(dplyr)
library(purrr)

# Assuming you've already set up the parallel plan:
plan(multisession, workers = 6)

read_and_process_files <- function(path) {
  # List all files in the specified directory
  files <- list.files(path, full.names = TRUE, pattern = "\\.csv$")
  files_filtered = tibble(files = files) %>%
    mutate(cc = substr(files, 1, 2)) %>%
    filter(cc %in% df_europe$FIPS) %>%
    pull(files)
  # Group files by the substr(files, 1, 2)
  file_groups <- split(files_filtered, substr(basename(files_filtered), 1, 2))
  
  # Parallelize reading and processing by group
  processed_data_list <- future_map(file_groups, function(group_files) {
    
    # Read each file in the group into a list using map()
    data_list_group <- map(group_files, ~read_csv(.x))
    
    # Flatten the list for the group
    flattened_data <- do.call(rbind, data_list_group)
    
    # Apply additional data operations here
    # Example: (modify this section as needed)
    processed_data <- flattened_data %>%
      mutate(month = floor_date(DATE, unit = "months"),
             geo = substr(STATION,1,2)) %>%
      group_by(geo, month) %>%
      summarise(prcp_sum = sum(PRCP, na.rm = T),
                tavg_mean = mean(TAVG, na.rm = T),
                t_min = min(TMIN, na.rm = T),
                t_max = max(TMAX, na.rm = T),
                .groups = "drop")
      
    return(processed_data)
    
  }, .progress = TRUE)  # Optional progress bar
  
  return(processed_data_list)
}

# Use the function
folder_path <- "/var/folders/ct/rxywh28x5cz8wmvm7vqnsqw40000gn/T//RtmpIX7YsR/NOAA_data_2023-08-22/"
final_data_list <- read_and_process_files(folder_path)

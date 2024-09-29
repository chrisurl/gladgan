library(rvest)
library(dplyr)
library(tibble)
library(future)
library(furrr)

download_NOAA_data <- function(base_url, df_europe) {
  
  # Create a unique sub-directory within tempdir()
  tmp_subdir <- file.path(tempdir(), paste0("NOAA_data_", Sys.Date()))
  #dir.create(tmp_subdir)
  
  # Scrape links from the base URL
  cat("Scraping \n")
  webpage <- read_html(base_url)
  links <- webpage %>% html_nodes("a") %>% html_attr("href")
  
  # Filter links to only .csv files
  csv_links <- grep(".csv$", links, value = TRUE)
  
  # Select CSV links based on country codes in df_europe
  csv_links_select <- tibble(csv_links = csv_links) %>%
    mutate(cc = substr(csv_links, 1, 2)) %>%
    filter(cc %in% df_europe$FIPS) %>%
    pull(csv_links)
  
  csv_links_select = csv_links_select[-c(1:541)] # first error
 # data_list <- list()
  a = Sys.time()
  # Download each selected CSV
  for (link in csv_links_select) {
    csv_url <- paste0(base_url, link)
    dest_file <- file.path(tmp_subdir, basename(csv_url))
    
    cat("Downloading", dest_file, "\n")
    result <- try(download.file(csv_url, dest_file, mode = "wb"))
    
    if(inherits(result, "try-error")) {
      warning(paste("Failed to download:", csv_url))
      next  # skips the rest of the loop iteration and moves to the next url
    }
    
    # Read the CSV into a data frame and add it to the list
   # data_list[[basename(csv_url)]] <- read_csv(dest_file)
  }
  timing = Sys.time() - a
  cat("Download and read complete!\n")
  cat(paste0("Time: ", timing))
  return(data_list)
}

# Assuming df_europe is already defined in your environment:
data_list <- download_NOAA_data("https://www.ncei.noaa.gov/data/global-historical-climatology-network-daily/access/", df_europe)



### Clean up

delete_NOAA_temp_files <- function(subdir_name) {
  tmp_subdir <- file.path(tempdir(), subdir_name)
  
  # Ensure the directory exists
  if (dir.exists(tmp_subdir)) {
    unlink(tmp_subdir, recursive = TRUE)
    cat(subdir_name, "deleted successfully!\n")
  } else {
    cat(subdir_name, "does not exist!\n")
  }
}

# Use the function (replace 'NOAA_data_YYYY-MM-DD' with the actual folder name you want to delete)
delete_NOAA_temp_files("NOAA_data_2023-08-22")

plan(multisession, workers = 2)

## Parallel version ----
download_NOAA_data_parallel <- function(base_url, df_europe) {
  
  # Create a unique sub-directory within tempdir()
  tmp_subdir <- file.path(tempdir(), paste0("NOAA_data_", Sys.Date()))
  dir.create(tmp_subdir)
  
  # Scrape links from the base URL
  cat("Scraping \n")
  webpage <- read_html(base_url)
  links <- webpage %>% html_nodes("a") %>% html_attr("href")
  
  # Filter links to only .csv files
  csv_links <- grep(".csv$", links, value = TRUE)
  
  # Select CSV links based on country codes in df_europe
  csv_links_select <- tibble(csv_links = csv_links) %>%
    mutate(cc = substr(csv_links, 1, 2)) %>%
    filter(cc %in% df_europe$FIPS) %>%
    pull(csv_links)
  
  cat("Start of parallelized download and read \n")
  # Parallelized download and read
  data_list <- future_map(csv_links_select, function(link) {
    csv_url <- paste0(base_url, link)
    dest_file <- file.path(tmp_subdir, basename(csv_url))
    
    cat("Downloading", dest_file, "\n")
    download.file(csv_url, dest_file, mode = "wb")
    
    # Read the CSV into a data frame
    return(csv_url)
  }, .progress = TRUE)  # Optional progress bar
  
  cat("Download and read complete!\n")
  return(data_list)
}

# Assuming df_europe is already defined in your environment:
data_list <- download_NOAA_data_parallel("https://www.ncei.noaa.gov/data/global-historical-climatology-network-daily/access/", df_europe)


monYear = substr(Sys.Date(),1,7)
entry1 = read_csv(paste0("data_ignore/results_",monYear,"_entry1.csv")) %>%
  mutate(entry = "entry_1")
entry2 = read_csv(paste0("data_ignore/results_",monYear,"_entry2.csv"))%>%
  mutate(entry = "entry_2")
entry3 = read_csv(paste0("data_ignore/results_",monYear,"_entry3.csv"))%>%
  mutate(entry = "entry_3")

df = bind_rows(entry1, entry2, entry3)

# Initialize an empty list to store the final JSON structure
json_structure <- list()
entries = unique(df$entry)
# Populate the structure
for (entry in entries) {
  # Filter data frame for the specific entry
  entry_data <- df[df$entry == entry, ]
  
  # Create a named list of predictions for each country
  entry_predictions <- setNames(as.list(entry_data$result), entry_data$geo)
  
  # Assign this list to the JSON structure under the entry name
  json_structure[[entry]] <- entry_predictions
}

# Convert the list to JSON and export to file
json_data <- toJSON(json_structure, pretty = TRUE, auto_unbox = TRUE, na = NULL)
write(json_data, paste0("results/",monYear,"/point_estimates.json"))

# Print JSON data to check the structure
cat(json_data)

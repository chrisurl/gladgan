file = paste0("### Load Data ### \n",
              read_file("1_load-data.R"), "\n\n", 
              "### Set-up ### \n",
              read_file("run/0_set-up.R"), "\n\n", 
              "### Functions ### \n",
              read_file("run/1_functions.R"), "\n\n", 
              "### Estimation ### \n",
              read_file("run/2_estimation.R"), "\n\n", 
              "### Export ### \n",
              read_file("run/3_export-json.R")
)
write_file(file, paste0("results/",monYear,"/code.R"))

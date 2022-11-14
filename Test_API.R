## Test APIs

library("httr")
library("xml2")
library("XML")
library(lubridate)
library(tidyverse)
library(foreach)
library(doParallel)
library(parallel)

api = "https://web-api.tp.entsoe.eu/api"
token="746698cc-5179-45aa-901b-023146095a5b"
wait_for = 15
tries = 10

in1 = read_delim("pvi/data/country_volatility_index.csv", delim = ";")
in2 = read_delim("ppi/data/country_volatility_index.csv", delim = ";")
countries = str_split(union(in1$Countries, in2$Countries),pattern=" ", simplify = T)[,1]
countries[countries=="EL"] <- "GR"

codes = read_delim("codes_transparency_db.csv", delim=";")
testvec = map(countries,~paste0("\\(",.,"\\)"))
testvec = str_c(testvec, collapse = "|")

codes_list = codes %>%
  filter(str_detect(codes$Meaning,testvec)) %>%
  mutate(country_code = str_extract(Meaning,testvec),
         country_code = str_extract(country_code, "[A-Z]+"))

# grid
years = c(2015:2022)
rm(in1, in2)

selector = expand.grid(countries,years) %>%
  rename(country_code = Var1, year=Var2)  %>%
  as_tibble() %>%
  left_join(codes_list)

##### Actual total load ---------
cl = detectCores()
registerDoParallel(cl)
volume_long_list = list()

volume_long_list = foreach(j=1:nrow(selector), 
                           .packages = c("httr", "xml2","lubridate","tidyverse"))%dopar%{
  
    ccode = as.character(selector[j,1])
    year = as.character(selector[j,2])
    year_1 = as.character(selector[j,2]-1)
    domain = unlist(selector[j,3])
    #apiCall = paste0(api,"?documentType=A65&processType=A16&outBiddingZone_Domain=10Y",ccode,"-CEPS-----N&periodStart=",year_1,"12312300&periodEnd=",year,"12312300&securityToken=",token)
    #domain = "10YAT-APG------L"
    #domain = "10Y1001A1001A83F"
    
    apiCall = paste0(api,"?documentType=A65&processType=A16&outBiddingZone_Domain=",domain,"&periodStart=",year_1,"12312300&periodEnd=",year,"12312300&securityToken=",token)
    
    
    apiTest = retry::retry(GET(apiCall),
                           when = "Send failure: Connection was reset",
                           interval = wait_for, 
                           max_tries = tries
    )
    #status_code(apiTest)
    if (status_code(apiTest) == 429){
      warning("HTTP Status 429 - TOO MANY REQUESTS; Wait for 65s")
      Sys.sleep(65)
    } else if (status_code(apiTest) != 200){
      stop("HTTP Status is not 200")
    }
    par1 =  content(apiTest, as = "parsed")
    
    par2 = as_list(par1)
    par3 = par2 %>%
      tibble::as_tibble()
    
    if(colnames(par3)=="Acknowledgement_MarketDocument"){
      warning(paste0("No data found for Country: ",ccode,", Year: ",year))
      write_file(par3[[1]][[8]][["text"]][[1]],
                 file=paste0("pvi/data/transparency_data/no_data_found/",ccode,"_",year,".txt"))
      next
    }
    
    par_df = par3 %>%
      unnest_longer(GL_MarketDocument)
    par_df_2 = par_df %>%
      dplyr::filter(GL_MarketDocument_id=="Period")
    
    df1 = par_df_2 %>%
      mutate(id = seq(1:nrow(par_df_2)), .before = 1) %>%
      group_by(id) %>%
      # 1st time unnest to release the 2-dimension list?
      unnest(cols = names(.)) %>%
      # 2nd time to nest the single list in each cell?
      unnest(cols = names(.)) %>%
      # convert data type
      readr::type_convert() %>%
      ungroup()
    
    #test1 = str_replace_all(unlist(df1[1,2]),pattern = "[TZ]", replacement = " ") %>% str_trim()
    
    out = list()
    
    for(i in 1:max(df1$id)){
      
      df1_filtered = df1 %>% filter(id==i)
      
      df1_info = tibble(
        start=as_datetime(unlist(df1_filtered[1,2]), format="%Y-%m-%dT%H:%MZ"),
        end = as_datetime(unlist(df1_filtered[2,2]), format="%Y-%m-%dT%H:%MZ"),
        step = unlist(df1_filtered[3,2]))
      
      df2 = df1_filtered[-c(1:3),-1]
      
      n = nrow(df2)
      i_pos = seq(from = 1, to = n-1, by = 2)
      val_pos = seq(from=2, to = n, by = 2)
      
      df_wide = tibble(
        country_code = ccode,
        start = df1_info$start,
        end = df1_info$end,
        period = as.numeric(unlist(df2[[1]][i_pos])),
        val = as.numeric(unlist(df2[[1]][val_pos]))
      )
      
      if(df1_info$step == "PT15M"){
        out[[i]] = df_wide %>%
          mutate(timestamp = start + minutes(45+period*15),.before=4)
      }else if(df1_info$step == "PT30M"){
        out[[i]] = df_wide %>%
          mutate(timestamp = start + minutes(30+period*30),.before=4)
      }else if(df1_info$step == "PT60M"){
        out[[i]] = df_wide %>%
          mutate(timestamp = start + hours(period),.before=4)
      }else{
        stop("No suitable time interval found.")
      }
    }
    out_long = do.call(bind_rows, out)
    write_csv(out_long,file = paste0("pvi/data/transparency_data/files/vol_",ccode,"_",year,".csv"))
}
stopImplicitCluster()
volumeLong = do.call(bind_rows, volume_long_list)
write_csv(volumeLong, path="pvi/data/transparency_data/electricity_volumes.csv")
#### Day ahead prices -------
#GET /api?documentType=A44&in_Domain=10YCZ-CEPS-----N&out_Domain=10YCZ-CEPS-----N&periodStart=201512312300&periodEnd=201612312300
cl = detectCores()
registerDoParallel(cl)
price_long_list = list()
price_long_list = foreach(j=1:nrow(selector), 
                          .packages = c("httr", "xml2","lubridate","tidyverse"))%dopar%{
    
  ccode = as.character(selector[j,1])
  year = as.character(selector[j,2])
  year_1 = as.character(selector[j,2]-1)
  domain = unlist(selector[j,3])
  
  apiCall = paste0(api,"?documentType=A44&in_Domain=",domain,"&out_Domain=",domain,"&periodStart=",year_1,"12312300&periodEnd=",year,"12312300&securityToken=",token)
  
  #token= /api?securityToken=TOKEN (other parameters omitted)
  apiTest = retry::retry(GET(apiCall),
                         when = "Send failure: Connection was reset",
                         interval = wait_for, 
                         max_tries = tries
  )
  if (status_code(apiTest) == 429){
    warning("HTTP Status 429 - TOO MANY REQUESTS; Wait for 65s")
    Sys.sleep(65)
  } else if (status_code(apiTest) != 200){
    stop("HTTP Status is not 200")
  }
  
  par1 =  content(apiTest, as = "parsed")
  par2 = as_list(par1)
  par3 = par2 %>%
    tibble::as_tibble()
  
  if(colnames(par3)=="Acknowledgement_MarketDocument"){
    warning(paste0("No data found for Country: ",ccode,", Year: ",year))
    write_file(par3[[1]][[8]][["text"]][[1]],
               file=paste0("ppi/data/transparency_data/no_data_found/",ccode,"_",year,".txt"))
    next
  }
  par_df = par3 %>%
    unnest_longer(Publication_MarketDocument)
  par_df_2 = par_df %>%
    dplyr::filter(Publication_MarketDocument_id=="Period")
  
  df1 = par_df_2 %>%
    mutate(id = seq(1:nrow(par_df_2)), .before = 1) %>%
    group_by(id) %>%
    # 1st time unnest to release the 2-dimension list?
    unnest(cols = names(.)) %>%
    # 2nd time to nest the single list in each cell?
    unnest(cols = names(.)) %>%
    # convert data type
    readr::type_convert() %>%
    ungroup()
  
  out = list()
  
  for(i in 1:max(df1$id)){
    
    df1_filtered = df1 %>% filter(id==i)
    
    df1_info = tibble(
      start=as_datetime(unlist(df1_filtered[1,2]), format="%Y-%m-%dT%H:%MZ"),
      end = as_datetime(unlist(df1_filtered[2,2]), format="%Y-%m-%dT%H:%MZ"),
      step = unlist(df1_filtered[3,2]))
    
    df2 = df1_filtered[-c(1:3),-1]
    
    n = nrow(df2)
    i_pos = seq(from = 1, to = n-1, by = 2)
    val_pos = seq(from=2, to = n, by = 2)
    
    df_wide = tibble(
      country_code = ccode,
      start = df1_info$start,
      end = df1_info$end,
      period = as.numeric(unlist(df2[[1]][i_pos])),
      val = as.numeric(unlist(df2[[1]][val_pos]))
    )
    
    if(df1_info$step == "PT15M"){
      out[[i]] = df_wide %>%
        mutate(timestamp = start + minutes(45+period*15),.before=4)
    }else if(df1_info$step == "PT30M"){
      out[[i]] = df_wide %>%
        mutate(timestamp = start + minutes(30+period*30),.before=4)
    }else if(df1_info$step == "PT60M"){
      out[[i]] = df_wide %>%
        mutate(timestamp = start + hours(period),.before=4)
    }else{
      stop("No suitable time interval found.")
    }
  }
  out_long = do.call(bind_rows, out)
  write_csv(out_long,file = paste0("ppi/data/transparency_data/files/vol_",ccode,"_",year,".csv"))
}

stopImplicitCluster()
priceLong = do.call(bind_rows, price_long_list)
write_csv(priceLong, path="ppi/data/transparency_data/electricity_prices.csv")


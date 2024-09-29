library(tidyverse)
library(data.table)
library(doFuture)
plan(multisession, workers = 6)

filelist = list.files("~/data/comext_raw/", pattern = ".dat", full.names = T)

out = foreach(i = seq_along(filelist)) %dofuture% {
  df = fread(filelist[i], drop = c("PRODUCT_SITC", "PRODUCT_CPA2002", "PRODUCT_CPA2008",
                                   "PRODUCT_CPA2_1", "PRODUCT_BEC", "PRODUCT_BEC5",   
                                   "PRODUCT_SECTION"),
             index = "PERIOD,PRODUCT_NC,PARTNER_ISO,DECLARANT_ISO")
  df[substr(PRODUCT_NC,1,6) %in% chpi$CN6]
}

df = do.call(rbind, out)
setkey(df, PERIOD, PRODUCT_NC, PARTNER_ISO, DECLARANT_ISO, physical = T)
setindex(df, PERIOD, PRODUCT_NC, PARTNER_ISO, DECLARANT_ISO)

write_rds(df, "~/data/comext_bf.rds")

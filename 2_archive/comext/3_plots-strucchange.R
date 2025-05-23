library(tidyverse)
library(data.table)
library(strucchange)

df = read_rds("~/data/comext_bf.rds")
df[, CN6 := substr(PRODUCT_NC, 1, 6)]

system.time(df %>% 
  as_tibble() %>%
  #mutate(CN6 = substr(PRODUCT_NC, 1, 6)) %>%
  group_by(PERIOD, PRODUCT_NC) %>%
  summarise(trade = sum(VALUE_IN_EUROS, na.rm = T)))

system.time(df[, sum(VALUE_IN_EUROS, na.rm = T), by = c("PERIOD", "PRODUCT_NC")])


df2 = df[FLOW == 1 & TRADE_TYPE == "E", sum(VALUE_IN_EUROS, na.rm = T), by = c("PERIOD", "CN6")]
colnames(df2)[3] <- "VALUE_SUM"
df2[, PERIOD := ym(PERIOD)]

library(plotly)
p1 = ggplot(df2, mapping = aes(x = PERIOD, y = VALUE_SUM, color = CN6)) +
  geom_line()

ggplotly(p1)


df3 = df[FLOW == 1 & TRADE_TYPE == "E" & PARTNER_ISO %in% c("RU", "KG", "TR")
         , sum(VALUE_IN_EUROS, na.rm = T), 
         by = c("PERIOD", "PARTNER_ISO")]
colnames(df3)[3] <- "VALUE_SUM"
df3[, PERIOD := ym(PERIOD)]

p2 = ggplot(df3, mapping = aes(x = PERIOD, y = VALUE_SUM, color = PARTNER_ISO)) +
  geom_line()

ggplotly(p2)


df4 = df[FLOW == 1 & TRADE_TYPE == "E" & PARTNER_ISO %in% c("RU", "KG", "TR") &
           CN6 %in% chpi$CN6[chpi$tier <= 2]
         , sum(VALUE_IN_EUROS, na.rm = T), 
         by = c("PERIOD", "PARTNER_ISO")]
colnames(df4)[2:3] <- c("DESTINATION","VALUE_SUM")
df4[, PERIOD := ym(PERIOD)]
p4 = ggplot(df4, mapping = aes(x = PERIOD, y = VALUE_SUM, color = DESTINATION)) +
  geom_line()

ggplotly(p4)

bp1 = df4[DESTINATION=="TR",c("PERIOD", "VALUE_SUM")]
ts1 = ts(log(as.numeric(bp1$VALUE_SUM)), start = 2018, end = c(2023,12), frequency = 12)
bp.tr = breakpoints(ts1 ~ 1)
plot(bp.tr)
breakpoints(bp.tr)
summary(bp.tr)

fm0 <- lm(ts1 ~ 1)
fm1 <- lm(ts1 ~ breakfactor(bp.tr))
ci.bp = confint(bp.tr)
plot(ts1)
lines(ts(fitted(fm0), start = 2018, end = c(2023,12), frequency = 12), col = 3)
lines(ts(fitted(fm1),  start = 2018, end = c(2023,12), frequency = 12), col = 4)
lines(bp.tr)
lines(ci.bp)

gm.tr = gefp(ts1 ~1)
plot(gm.tr)
sctest(gm.tr)

grid1 = df[TRADE_TYPE == "E", 
           unique(.SD), .SDcols = c("CN6", "PARTNER_ISO")]

# flow: 1 = Import, 2 = Export

plot_breaks <- function(df, cn_code, country, measure, flow, metric, transformation = "log", confInt){
  
  stopifnot(measure %in% c("quantity", "value"), flow %in% 1:2, metric %in% c("BIC", "RSS"),
            transformation %in% c("none", "log"))
  
  df1= df[FLOW == flow & PARTNER_ISO == country & CN6 == cn_code, 
     .(VALUE_SUM = sum(VALUE_IN_EUROS, na.rm = T), QUANTITY_SUM = sum(QUANTITY_IN_KG, na.rm = T)), 
     by = c("PERIOD", "PARTNER_ISO")]
  colnames(df1)[2] <- c("DESTINATION")
  df1[, PERIOD := lubridate::ym(PERIOD)]
  
  years = 2018:2023
  months = 1:12  %>% as.character() %>% str_c("0",.) %>% str_sub(-2)
  
  naFillValue = switch(transformation,
                       "none" = 0,
                       "log" = 1)
  
  tsgrid =  expand_grid(years, months) %>%
    mutate(PERIOD = ym(str_c(years, months)),
           DESTINATION = country) %>%
    select(PERIOD, DESTINATION) %>%
    left_join(df1, by = join_by("PERIOD", "DESTINATION")) %>%
    mutate(QUANTITY_SUM = pmax(QUANTITY_SUM, naFillValue, na.rm = T),
           VALUE_SUM = pmax(VALUE_SUM, naFillValue, na.rm = T))
  rm(df1)
  tscol = switch(measure,
                 "quantity" = tsgrid$QUANTITY_SUM,
                 "value" = tsgrid$VALUE_SUM)
  
  tscolTrans = switch(transformation,
                      "none" = tscol,
                      "log" = log(tscol))
  
  ts1 = ts(tscolTrans, start = 2018, end = c(2023,12), frequency = 12)
  bp.tr = breakpoints(ts1 ~ 1)
  
  a = which(summary(bp.tr)$RSS["RSS",]==min(summary(bp.tr)$RSS["RSS",]))
  b = which(summary(bp.tr)$RSS["BIC",]==min(summary(bp.tr)$RSS["BIC",]))
  
  breaksNum = switch(metric,
                     "RSS" = as.numeric(names(a)),
                     "BIC" = as.numeric(names(b)))
  
  if(length(breaksNum) > 1) breaksNum = breaksNum[1]
  if(breaksNum==0){
    stop("No breaks estimated")
  }
  
  fm0 <- lm(ts1 ~ 1)
  fm1 <- lm(ts1 ~ breakfactor(bp.tr, breaks = breaksNum))
  ci.bp = confint(bp.tr, breaks = breaksNum)
  n = nrow(ci.bp$confint)
  narow = unique(which(is.na(ci.bp$confint))%%n)
  
  plot(ts1)
  title(paste0("Country: ", country, ", CN Code: ", cn_code))
  lines(ts(fitted(fm0), start = 2018, end = c(2023,12), frequency = 12), col = 3)
  lines(ts(fitted(fm1),  start = 2018, end = c(2023,12), frequency = 12), col = 4)
  if(!sum(narow) == 0 | !confInt) lines(bp.tr, breaks = breaksNum)
  if(sum(narow) == 0 & confInt) lines(ci.bp)
}

plot_breaks(df, "854110", "TR", "value",  2, "BIC", transformation = "log", confInt = T)
plot_breaks(df, "854110", "TR", "value",  2, "RSS", transformation = "log", confInt = F)
plot_breaks(df, "854110", "TR", "quantity",  2, "BIC", transformation = "log", confInt = T)
plot_breaks(df, "854110", "TR", "quantity",  2, "RSS", transformation = "log", confInt = F)

# to do: 
## seasonality estimation
## implement estimation function (i.e. also other estimators from the package)
## time selector
## na handling (e.g. ARIMA fill, or others)
## changepoint package

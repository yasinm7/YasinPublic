install.packages(c("DBI","RSQLite","dplyr","caTools","rpart","ggplot2"))

library(DBI)
library(RSQLite)
library(dplyr)
library(caTools)
library(rpart)
library(ggplot2)

con <- dbConnect(
  SQLite(),
  "project1_raw_data.db"
)

#joining train key weather
sql <- "SELECT
t.store_nbr,
t.item_nbr,
t.units,
w.*
  FROM train t
JOIN key k
ON t.store_nbr = k.store_nbr
JOIN weather w
ON k.station_nbr = w.station_nbr
AND t.date = w.date;
"
dbListTables(con)

joined_df <- dbGetQuery(con, sql)

#top 3 product sales
sql2 <- "
WITH top_3_products AS (
    SELECT
        item_nbr,
        SUM(units) AS total_units_sold
    FROM train
    GROUP BY item_nbr
    ORDER BY total_units_sold DESC
    LIMIT 3
)
SELECT *
FROM top_3_products
"
top_3_products <- dbGetQuery(con, sql2)

#Daily sale and tavg of one of top 3 products
#Item 45 is one of the top 3 from Above Query (Top 3 Product Sales) 
sql3 <- "SELECT sales.date, sales.units_sold_item_num_45, weather.avg_temp
FROM ( SELECT date, SUM(units) AS units_sold_item_num_45
    FROM train
    WHERE item_nbr = 45
    GROUP BY date
) sales
LEFT JOIN (
    SELECT date, AVG(tavg) AS avg_temp
    FROM weather
    GROUP BY date
) weather
ON sales.date = weather.date
ORDER BY sales.date;
"
one_of_top_3_products_sales_tavg <- dbGetQuery(con, sql3)

#replacing null values ,'T' and empty strings with NA values
joined_df <- joined_df %>%

  mutate(across(where(is.character), ~ na_if(., "NULL"))) %>%
  mutate(across(where(is.character), ~ if_else(. == "T", "0", .))) %>%
  mutate(across(where(is.character), ~ na_if(., ""))) %>%
  
  mutate(date = as.Date(date)) %>%
  
  mutate(across(c(tavg, preciptotal, avgspeed), as.numeric)) %>%
 
  #Replacing relevant NA values with means
   
  group_by(date) %>%
  mutate(
    across(
      c(tavg, preciptotal, avgspeed),
      ~ ifelse(
        is.na(.),
        ifelse(all(is.na(.)), NA_real_, mean(., na.rm = TRUE)),
        .
      )
    )
  ) %>%
  ungroup()

joined_df <- joined_df %>%
  mutate(units = as.numeric(units))

joined_df <- joined_df %>%
  filter(!is.na(units), units > 0)

Q1 <- quantile(joined_df$units, 0.25)
Q3 <- quantile(joined_df$units, 0.75)
IQR_val <- Q3 - Q1

sales_iqr <- joined_df %>%
  filter(
    units >= Q1 - 1.5 * IQR_val,
    units <= Q3 + 1.5 * IQR_val
  )

#Creating is_rainy_day variable
sales_iqr <- sales_iqr %>%
  mutate(
    is_rainy_day = ifelse(
      (!is.na(codesum) & grepl("ra", codesum, ignore.case = TRUE)) |
        (!is.na(preciptotal) & preciptotal > 0),
      1L,
      0L
    )
  )

#Creating low_vision_days variable for misty, foggy and haze days with Codesum
sales_iqr <- sales_iqr %>%
  mutate(low_vision_days = ifelse(codesum %in% c("BR","FG","HZ"), 1, 0))


  sales_iqr <- sales_iqr %>%
  mutate(
    is_rainy_day = factor(is_rainy_day, levels = c(0, 1)),
    low_vision_days = factor(low_vision_days, levels = c(0, 1))
  )

sales_iqr <- sales_iqr %>%
  mutate(date = as.Date(date))


sales_iqr <- sales_iqr %>% arrange(date)

itm_45 <- sales_iqr %>% filter(item_nbr == 45)
itm_9  <- sales_iqr %>% filter(item_nbr == 9)
itm_5  <- sales_iqr %>% filter(item_nbr == 5)

set.seed(123) 


#Splitting 80% of data in train data and 20% in test data for each item
split_45 <- sample.split(itm_45$units, SplitRatio = 0.8)
train_45 <- subset(itm_45, split_45 == TRUE)
test_45  <- subset(itm_45, split_45 == FALSE)

split_9 <- sample.split(itm_9$units, SplitRatio = 0.8)
train_9 <- subset(itm_9, split_9 == TRUE)
test_9  <- subset(itm_9, split_9 == FALSE)

split_5 <- sample.split(itm_5$units, SplitRatio = 0.8)
train_5 <- subset(itm_5, split_5 == TRUE)
test_5  <- subset(itm_5, split_5 == FALSE)

#Building Linear regression model for each item using weather variables effect on units
model_45 <- lm(units ~ tavg + preciptotal + avgspeed + is_rainy_day + low_vision_days, data = train_45)
pred_45 <- predict(model_45, test_45)

model_9  <- lm(units ~ tavg + preciptotal + avgspeed + is_rainy_day + low_vision_days, data = train_9)
pred_9  <- predict(model_9, test_9)

model_5  <- lm(units ~ tavg + preciptotal + avgspeed + is_rainy_day + low_vision_days, data = train_5)
pred_5  <- predict(model_5, test_5)

rmse <- function(actual, predicted) {
  sqrt(mean((actual - predicted)^2, na.rm = TRUE))
}

rmse_45 <- rmse(test_45$units, pred_45)
rmse_9  <- rmse(test_9$units, pred_9)
rmse_5  <- rmse(test_5$units, pred_5)

rmse_45
rmse_9
rmse_5


mae <- function(actual, predicted) {
  mean(abs(actual - predicted), na.rm = TRUE)
}

mae_45 <- mae(test_45$units, pred_45)
mae_9  <- mae(test_9$units, pred_9)
mae_5  <- mae(test_5$units, pred_5)

# Decision tree for Item 45
dt_45 <- rpart(units ~ tavg + preciptotal + avgspeed + is_rainy_day + low_vision_days, 
               data = train_45, method = "anova")
pred_dt_45 <- predict(dt_45, test_45)

# Decision tree for Item 9
dt_9 <- rpart(units ~ tavg + preciptotal + avgspeed + is_rainy_day + low_vision_days, 
              data = train_9, method = "anova")
pred_dt_9 <- predict(dt_9, test_9)

# Decision tree for Item 5
dt_5 <- rpart(units ~ tavg + preciptotal + avgspeed + is_rainy_day + low_vision_days, 
              data = train_5, method = "anova")
pred_dt_5 <- predict(dt_5, test_5)

# RMSE
rmse_dt_45 <- rmse(test_45$units, pred_dt_45)
rmse_dt_9  <- rmse(test_9$units, pred_dt_9)
rmse_dt_5  <- rmse(test_5$units, pred_dt_5)

# MAE
mae_dt_45 <- mae(test_45$units, pred_dt_45)
mae_dt_9  <- mae(test_9$units, pred_dt_9)
mae_dt_5  <- mae(test_5$units, pred_dt_5)

evaluation <- data.frame(
  item_nbr = c(45, 9, 5),
  RMSE_LM = c(rmse_45, rmse_9, rmse_5),
  MAE_LM  = c(mae_45, mae_9, mae_5),
  RMSE_DT = c(rmse_dt_45, rmse_dt_9, rmse_dt_5),
  MAE_DT  = c(mae_dt_45, mae_dt_9, mae_dt_5)
)

evaluation

#Plot of model item number 45

ggplot(train_45, aes(x = preciptotal, y = units)) +
  geom_point(color = "blue", alpha = 0.6) +       # points
  geom_smooth(method = "lm", se = TRUE, color = "red") +  # linear regression line
  labs(
    title = "Units vs Precipitation for Item 45",
    x = "Precipitation Total",
    y = "Units Sold"
  ) +
  theme_minimal()

coef(model_45)

#Plot of model item number 9
ggplot(train_9, aes(x = low_vision_days, y = units)) +
  geom_boxplot(fill = "skyblue", alpha = 0.6) +
  geom_jitter(width = 0.1, color = "darkblue") +
  labs(
    title = "Units Sold vs Low Vision Days (Item 9)",
    x = "Low Vision Day (0 = No, 1 = Yes)",
    y = "Units Sold"
  ) +
  theme_minimal()

coef(model_9)

#Plot of model item number 5

ggplot(train_5, aes(x = is_rainy_day, y = units)) +
  geom_boxplot(fill = "orange", alpha = 0.6) +
  geom_jitter(width = 0.1, color = "red") +
  labs(
    title = "Units Sold vs Rainy days (Item 5)",
    x = "Rainy day (0 = No, 1 = Yes)",
    y = "Units Sold"
  ) +
  theme_minimal()

coef(model_5)

















































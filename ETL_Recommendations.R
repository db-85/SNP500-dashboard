library(aws.s3)
library(jsonlite)
library(tidyverse)
library(purrr)
library(httr)
library(ggplot2)
Sys.setenv(AWS_DEFAULT_REGION = "eu-north-1")  # <- UPDATE THIS

bucket <- "snp500-stocks"
prefix <- "raw/stock_prices/finnhub_recommendations/"  # optional
objects <- get_bucket(bucket = bucket, prefix = prefix)


# Read JSON files
raw_data <- lapply(objects, function(obj) {
  tryCatch({
    s3read_using(FUN = fromJSON, 
                 object = obj$Key, 
                 bucket = bucket)
  }, error = function(e) NULL)
})

# Create data frame
recommendations_df <- map_dfr(raw_data, ~.)

# Cleaning step
recommendations_df_clean <- recommendations_df %>% distinct()

# Save to S3
s3write_using(recommendations_df_clean, 
              FUN = write.csv, 
              object = "processed/finnhub_recommendations.csv", 
              bucket = bucket,
              row.names = FALSE)
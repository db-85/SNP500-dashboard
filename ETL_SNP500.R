library(aws.s3)
library(jsonlite)
library(dplyr)
library(purrr)
library(httr)
library(ggplot2)


Sys.setenv(AWS_DEFAULT_REGION = "eu-north-1") 

bucket <- "snp500-stocks"
prefix <- "raw/stock_prices/finnhub_quotes/"  # optional
objects <- get_bucket(bucket = bucket, prefix = prefix)

# Read API key from file
api_key <- readLines("API_key.txt")

# Read JSON files
raw_data <- lapply(objects, function(obj) {
  tryCatch({
    s3read_using(FUN = fromJSON, 
                 object = obj$Key, 
                 bucket = bucket)
  }, error = function(e) NULL)
})

# Get companies
companies <- s3read_using(FUN = fromJSON, 
                          object = "companies/constituents.json", 
                          bucket = bucket)


# Create data frame
stock_df <- map_dfr(raw_data, ~.)

# Create data frame
companies_df <- map_dfr(companies, ~.)

# Define endpoint
companies_info_df <- data.frame()
for(symbol in unique(companies_df$Symbol))
{

  # URL
  url <- paste0("https://finnhub.io/api/v1/stock/profile2?symbol=", symbol, "&token=", api_key)

  # Make request
  response <- GET(url)

  # Parse response
  data <- map_dfr(fromJSON(content(response, "text")), ~.)

  companies_info_df <- rbind(companies_info_df, data)

  # Wait to ensure less than 60 API requests per minute
  Sys.sleep(1.01)
}

stock_df_clean <- stock_df %>%
  mutate(t = as.Date(as.POSIXct(t, origin = "1970-01-01")), change = (c-o)/o * 100) 

stock_df_joined <- stock_df_clean %>%
  left_join(companies_df, by = c("Symbol" = "Symbol")) %>%
  left_join(companies_info_df, by = c("Symbol" = "ticker")) %>% 
  na.omit(marketCap) %>% filter(t == max(t))

# Store in S3 bucket
s3write_using(stock_df_joined,
              FUN = write.csv,
              bucket = bucket,
              object = "processed/stock_df_joined.csv",
              row.names = FALSE)

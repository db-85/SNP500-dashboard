library(shiny)
library(treemap)
library(tidyverse)
library(aws.s3)

Sys.setenv("AWS_ACCESS_KEY_ID" = readLines("AWS_ACCESS_KEY"),
           "AWS_SECRET_ACCESS_KEY" = readLines("AWS_SECRET_ACCESS_KEY"),
           "AWS_DEFAULT_REGION" = "eu-north-1")  # or your region

company <- "AAPL"
# Define custom colors
rec_colors <- c(
  strongBuy = "#006400",  # dark green
  buy = "#00AA00",        # lime green
  hold = "#FFA500",       # orange
  sell = "#FF4500",       # orange-red
  strongSell = "#8B0000"  # dark red
)

ui <- fluidPage(
  titlePanel("Daily Stock Price Treemap"),

  mainPanel(
    plotOutput("treemapPlot"),
    plotOutput("recommendationPlot")
  )
)

server <- function(input, output) {
  output$treemapPlot <- renderPlot({
    # Replace with actual data source
    stock_df_joined <- s3read_using(FUN = read.csv, 
                                    object = "processed/stock_df_joined.csv", 
                                    bucket = "snp500-stocks")
    treemap(stock_df_joined,
            index = "Symbol",
            vSize = "marketCapitalization",
            vColor = "change",
            type = "value",
            palette = "RdYlGn",
            title = "Stock Price Changes")
  
  })
  output$recommendationPlot <- renderPlot({
    # Replace with actual data source
    recommendations_df_clean <- s3read_using(FUN = read.csv, 
                                             object = "processed/finnhub_recommendations.csv", 
                                             bucket = "snp500-stocks")
    # Pivot to long format
df_long <- recommendations_df_clean %>%
    filter(symbol == company) %>%  
    select(-symbol) %>%
    pivot_longer(cols = c(buy, hold, sell, strongBuy, strongSell),
               names_to = "recommendation",
               values_to = "count")

df_long <- df_long %>%
  mutate(recommendation = factor(recommendation, levels = c(
    "strongSell", "sell", "hold", "buy", "strongBuy"
  )))
  # Create the plot
ggplot(df_long, aes(x = period, y = count, fill = recommendation)) +
  geom_bar(stat = "identity") +
  scale_fill_manual(values = rec_colors) +
  labs(
    title = "Apple Stock Recommendations Over Time",
    x = "Date",
    y = "Number of Recommendations",
    fill = "Recommendation"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  theme(
  text = element_text(size = 14),             # overall default
  axis.title = element_text(size = 16),       # axis titles
  axis.text = element_text(size = 14),        # axis tick labels
  legend.title = element_text(size = 15),     # legend title
  legend.text = element_text(size = 13),      # legend labels
  plot.title = element_text(size = 18, face = "bold")  # plot title
)

  })
}

shinyApp(ui, server)

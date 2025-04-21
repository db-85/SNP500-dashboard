import finnhub
finnhub_client = finnhub.Client(api_key="")

print(finnhub_client.historical_market_cap('AAPL', _from="2020-06-01", to="2020-06-10"))

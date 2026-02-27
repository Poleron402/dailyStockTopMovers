# The script that fetches the data for requested stocks - "AAPL", "MSFT", "GOOGL", "AMZN", "TSLA" and "NVDA"
# this will be triggered by the cron job in aws

import requests
from datetime import date, timedelta
# from dotenv import load_dotenv
import os
import json
from decimal import Decimal
import time
import boto3


# Loading api key from the .env - DEV
# load_dotenv()
def lambda_handler(event, context):
    api_key = os.environ.get("API_KEY")

    # needed tickers
    watchlist = ["AAPL","MSFT","GOOGL","AMZN","TSLA","NVDA"]

    # today's date
    today = str(date.today()-timedelta(days=1))

    # to check the winner
    highest_change = 0

    # Data to store: Date, Ticker Symbol, Percent Change, and Closing Price.
    winner = {}

    for stock in watchlist:
        try:
            response = requests.get(f"https://api.massive.com/v1/open-close/{stock}/{today}?adjusted=true&apiKey={api_key}")
            data = response.json()
            print(data)
            if data["status"] != "OK":
                raise Exception("Bad request")
                

            diff = 100*((data["close"]-data["open"])/data["open"])
            if abs(diff)>highest_change:
                highest_change = abs(diff)
                winner = {
                    "date": today,
                    "ticker": stock,
                    "percent_change": diff,
                    "closing_price": data["close"]
                }
            # Adding sleep for 12 seconds to bypass free api tier limitation
            time.sleep(12)
        except requests.exceptions.HTTPError as e:
            print(f"HTTP error: {e}")
            pass

    winner = json.loads(json.dumps(winner), parse_float=Decimal)
    # dynamo db connection
    dynamodb = boto3.resource('dynamodb', region_name='us-west-1')
    table = dynamodb.Table(os.environ.get("DB_NAME"))

    db_response = table.put_item(
        Item=winner
    )

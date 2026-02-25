import boto3
from datetime import date, timedelta
import json
from decimal import Decimal

def handler(event, context):
    dynamodb = boto3.resource('dynamodb', region_name='us-west-1')
    table = dynamodb.Table('StockData')

    get_days = 0


    return_date = []
    while len(return_date)<7:
        try:
            today = str(date.today()-timedelta(days=get_days))
            db_response = table.get_item(
                Key={"date": today,
                        }
                )
            get_days += 1
        except Exception as e:
            print("No entry for the date exists")
            continue

        
        if "Item" in db_response:
            for key, value in db_response["Item"].items():
                if isinstance(value, Decimal):
                    db_response["Item"][key] = float(value)
            return_date.append(db_response["Item"])

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps(return_date)
    }

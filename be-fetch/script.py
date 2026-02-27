import boto3
from datetime import date, timedelta
import json
import os
from decimal import Decimal

def handler(event, context):
    dynamodb = boto3.resource('dynamodb', region_name='us-west-1')
    table = dynamodb.Table(os.environ.get("DB_NAME"))

    get_days = 0
    max_days = 15
    return_date = []
    while get_days<max_days:
        try:
            today = str(date.today()-timedelta(days=get_days))
            db_response = table.get_item(Key={"date": today,})
            
        except Exception as e:
             return {
                "statusCode": 500,
                "headers": {"Content-Type": "application/json", 
                            "Access-Control-Allow-Origin": "*"},
                "body": json.dumps({"message": "Internal server error"})
            }
        
        if "Item" in db_response:
            for key, value in db_response["Item"].items():
                if isinstance(value, Decimal):
                    db_response["Item"][key] = float(value)
            return_date.append(db_response["Item"])
            
        if len(return_date) == 7:
            break
        get_days += 1

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps(return_date)
    }

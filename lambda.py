import json 
import boto3 
from decimal import Decimal 

client = boto3.client('dynamodb')
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table('louisobriencv')
tableName = 'louisobriencv'


def lambda_handler(event, context):
    print(event)
    body = {}
    statusCode = 200
    headers = {
        "Content-Type": "application/json"
    }

    try:
        if event['routeKey'] == "POST /items/{id}":
            response = table_request(event)
            body = int(response['Attributes']['count'])
    except KeyError:
        statusCode = 400
        body = 'Unsupported route: ' + event['routeKey']
    res = {
        "statusCode": statusCode,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": body
    }
    return res

def table_request(event):
    return table.update_item(
        Key={'id': event['pathParameters']['id']},
        UpdateExpression='ADD #c :inc',
        ExpressionAttributeNames={'#c': 'count'},
        ExpressionAttributeValues={':inc': 1},
        ReturnValues='UPDATED_NEW'
    )
import json
import boto3
from botocore.exceptions import ClientError

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('VisitorsTable')

def lambda_handler(event, context):
    try:
        # Increment visitor count
        response = table.update_item(
            Key={'id': 'visitor_count'},
            UpdateExpression='ADD visitors :incr',
            ExpressionAttributeValues={':incr': 1},
            ReturnValues="UPDATED_NEW"
        )

        # Return the updated visitor count
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'visitor_count': int(response['Attributes']['visitors'])})
        }
    
    except ClientError as e:
        # Log error and return an appropriate response
        print(f"Error updating item: {e}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': 'Internal Server Error'})
        }

# tests/test_lambda.py
import os
import sys
import json
import boto3
from moto import mock_aws  # Updated import

# Add the lambda directory to the Python path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../infra/lambda')))

from lambda_function import lambda_handler

@mock_aws  # Updated decorator
def test_lambda_handler_success():
    # Set up environment variable for DynamoDB table name
    os.environ['DYNAMODB_TABLE'] = 'VisitorsTable'

    # Create a mock DynamoDB table
    dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
    table = dynamodb.create_table(
        TableName='VisitorsTable',
        KeySchema=[{'AttributeName': 'id', 'KeyType': 'HASH'}],
        AttributeDefinitions=[{'AttributeName': 'id', 'AttributeType': 'S'}],
        ProvisionedThroughput={'ReadCapacityUnits': 1, 'WriteCapacityUnits': 1}
    )

    # Insert initial data into the table
    table.put_item(Item={'id': 'visitor_count', 'visitors': 0})

    # Test the Lambda function
    event = {}
    context = {}
    response = lambda_handler(event, context)

    # Assert the response
    assert response['statusCode'] == 200
    assert json.loads(response['body'])['visitor_count'] == 1  # Visitor count should increment to 1

@mock_aws
def test_lambda_handler_error():
    # Set up environment variable for DynamoDB table name
    os.environ['DYNAMODB_TABLE'] = 'VisitorsTable'

    # Create a mock DynamoDB table
    dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
    table = dynamodb.create_table(
        TableName='VisitorsTable',
        KeySchema=[{'AttributeName': 'id', 'KeyType': 'HASH'}],
        AttributeDefinitions=[{'AttributeName': 'id', 'AttributeType': 'S'}],
        ProvisionedThroughput={'ReadCapacityUnits': 1, 'WriteCapacityUnits': 1}
    )

    # Delete the table to simulate an error
    table.delete()

    # Test the Lambda function
    event = {}
    context = {}
    response = lambda_handler(event, context)

    # Assert the response for error case
    assert response['statusCode'] == 500
    assert json.loads(response['body'])['error'] == 'Internal Server Error'
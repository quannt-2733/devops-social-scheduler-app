import json
import os
import boto3
from datetime import datetime

DB_TABLE = os.environ.get("DB_TABLE")
SECRET_ARN = os.environ.get("SECRET_ID")
REGION = "ap-southeast-1"

# Configure AWS clients
dynamodb = boto3.resource('dynamodb', region_name=REGION)
secrets_client = boto3.client('secretsmanager', region_name=REGION)
table = dynamodb.Table(DB_TABLE)

def get_social_tokens():
    """Get social media tokens from AWS Secrets Manager"""
    try:
        response = secrets_client.get_secret_value(SecretId=SECRET_ARN)
        if 'SecretString' in response:
            return json.loads(response['SecretString'])
    except Exception as e:
        print(f"Error getting secrets: {str(e)}")
        return {}

def post_to_social_media(platform, content, tokens):
    """Simulate social network API calls"""
    print(f"--- POSTING TO {platform.upper()} ---")
    token = tokens.get(f"{platform}_token", "No Token Found")
    print(f"Using Token: {token[:5]}***")
    print(f"Content: {content}")

    return True

def lambda_handler(event, context):
    print("Received event:", json.dumps(event))

    tokens = get_social_tokens()

    if 'Records' in event:
        for record in event['Records']:
            try:
                # Parse content from SQS
                payload = json.loads(record['body'])
                post_id = payload.get('post_id')
                user_id = payload.get('user_id')

                print(f"Processing Post ID: {post_id}")

                # Get article information from DynamoDB
                response = table.get_item(Key={'user_id': user_id, 'scheduled_time': payload.get('scheduled_time', '')})
                content = "Hello World content from DB"
                platform = "facebook"

                # Make a post
                if post_to_social_media(platform, content, tokens):
                    print(f"Post {post_id} published successfully!")

            except Exception as e:
                print(f"Error processing record: {str(e)}")

    return {"status": "success"}

import os
import boto3
import uuid
import json
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from datetime import datetime

app = FastAPI()

# Get configuration from Environment Variables
# We will set these variables in the ecs.tf file later
DYNAMODB_TABLE = os.environ.get("DB_TABLE", "devops-social-scheduler-app-dev-posts")
SCHEDULER_GROUP = os.environ.get("SCHEDULER_GROUP", "devops-social-scheduler-app-dev-schedule-group")
SQS_ARN = os.environ.get("SQS_QUEUE_ARN")
SCHEDULER_ROLE_ARN = os.environ.get("SCHEDULER_ROLE_ARN")
REGION = "ap-southeast-1"

# Initialize AWS Clients
dynamodb = boto3.resource('dynamodb', region_name=REGION)
scheduler = boto3.client('scheduler', region_name=REGION)
table = dynamodb.Table(DYNAMODB_TABLE)

# Define input data
class ScheduleRequest(BaseModel):
    user_id: str
    content: str
    platform: str
    schedule_time: str

@app.get("/health")
def health_check():
    return {"status": "healthy"}

@app.post("/schedule")
def create_schedule(request: ScheduleRequest):
    try:
        post_id = str(uuid.uuid4())

        # Save metadata to DynamoDB
        table.put_item(Item={
            'user_id': request.user_id,
            'scheduled_time': request.schedule_time,
            'post_id': post_id,
            'content': request.content,
            'platform': request.platform,
            'status': 'PENDING'
        })

        # Create a schedule on EventBridge Scheduler
        # When it's time G, Scheduler will send a message to SQS
        schedule_name = f"post-{post_id}"

        response = scheduler.create_schedule(
            Name=schedule_name,
            GroupName=SCHEDULER_GROUP,
            ScheduleExpression=f"at({request.schedule_time})",
            FlexibleTimeWindow={'Mode': 'OFF'},
            Target={
                'Arn': SQS_ARN,
                'RoleArn': SCHEDULER_ROLE_ARN,
                'Input': json.dumps({
                    'user_id': request.user_id,
                    'post_id': post_id,
                    'action': 'PUBLISH_POST',
                    'scheduled_time': request.schedule_time
                })
            }
        )

        return {
            "message": "Schedule created successfully",
            "post_id": post_id,
            "schedule_arn": response['ScheduleArn']
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

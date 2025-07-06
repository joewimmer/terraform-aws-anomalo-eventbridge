import json
import os
import boto3


print("Loading function")

# Initialize clients outside the handler for reuse
events_client = boto3.client("events")

# Get configuration from environment variables
EVENT_BUS_NAME = os.environ["EVENT_BUS_NAME"]


def main(event, context):
    print("Received event: " + json.dumps(event, indent=2))

    try:
        # --- Extract and prepare message ---
        message_body = json.loads(event.get("body", "{}"))
        check_run_event = message_body.get("check_runs", [{}])[0]
        print(f"Check run event: {json.dumps(check_run_event, indent=2)}")

        detail = json.dumps(check_run_event)

        response = events_client.put_events(
            Entries=[
                {
                    "Source": "com.anomalo.events",
                    "DetailType": "AnomaloCheckRun",
                    "Detail": detail,
                    "EventBusName": EVENT_BUS_NAME,
                }
            ]
        )

        print("EventBridge put_events response: " + json.dumps(response, indent=2))

        return {
            "statusCode": 202,
            "body": json.dumps(
                {
                    "message": "Event accepted",
                    "eventId": response["Entries"][0].get("EventId"),
                }
            ),
        }

    except Exception as e:
        print(f"Error processing request: {e}")
        return {
            "statusCode": 500,
            "body": json.dumps({"message": "Internal server error processing request"}),
        }

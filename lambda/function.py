import json
import os

import boto3


print("Loading function")

# Initialize clients outside the handler for reuse
secrets_client = boto3.client("secretsmanager")
events_client = boto3.client("events")

# Get configuration from environment variables
EVENT_BUS_NAME = os.environ["EVENT_BUS_NAME"]
SECRET_ARN = os.environ["EXPECTED_TOKEN_SECRET_ID"]  # Use the Secret ID or ARN

# Cache for the secret to reduce latency and cost
CACHED_SECRET = None


def get_expected_token():
    """Retrieves the expected API token from Secrets Manager, with basic caching."""
    global CACHED_SECRET
    if CACHED_SECRET:
        print("Using cached secret")
        return CACHED_SECRET

    print(f"Attempting to retrieve secret: {SECRET_ARN}")
    try:
        response = secrets_client.get_secret_value(SecretId=SECRET_ARN)
        if "SecretString" in response:
            CACHED_SECRET = response["SecretString"]
            print("Secret retrieved and cached successfully")
            return CACHED_SECRET
        else:
            print("SecretString not found in response.")
            return None
    except Exception as e:
        print(f"Error retrieving secret from Secrets Manager: {e}")
        raise e


def main(event, context):
    print("Received event: " + json.dumps(event, indent=2))

    try:
        expected_token = get_expected_token()
        if not expected_token:
            print("Failed to load expected token from Secrets Manager.")
            return {
                "statusCode": 500,
                "body": json.dumps(
                    {"message": "Internal server error: Configuration issue"}
                ),
            }

        # --- Authentication ---
        auth_header = None
        if event.get("headers"):
            auth_header = event["headers"].get("authorization") or event["headers"].get(
                "Authorization"
            )

        if not auth_header:
            print("Authorization header missing")
            return {
                "statusCode": 401,
                "body": json.dumps(
                    {"message": "Unauthorized: Authorization header missing"}
                ),
            }

        parts = auth_header.split()
        if len(parts) != 2 or parts[0].lower() != "bearer":
            print(f"Invalid Authorization header format: {auth_header}")
            return {
                "statusCode": 401,
                "body": json.dumps(
                    {"message": "Unauthorized: Invalid Authorization header format"}
                ),
            }

        provided_token = parts[1]

        if provided_token != expected_token:
            print("Provided token does not match expected token.")
            return {
                "statusCode": 403,
                "body": json.dumps({"message": "Unauthorized: Invalid token"}),
            }

        print("Authentication successful.")

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

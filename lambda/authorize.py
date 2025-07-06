import json
import os
import boto3


print("Loading function")

# Initialize clients outside the handler for reuse
secrets_client = boto3.client("secretsmanager")
SECRET_ARN = os.environ["SECRET_ARN"]  # Use the Secret ID or ARN


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


def generate_policy(principalId, effect, resource):
    """Generates an IAM policy document."""
    authResponse = {}
    authResponse["principalId"] = principalId
    if (effect and resource):
        policyDocument = {}
        policyDocument["Version"] = "2012-10-17"
        policyDocument["Statement"] = []
        statementOne = {}
        statementOne["Action"] = "execute-api:Invoke"
        statementOne["Effect"] = effect
        statementOne["Resource"] = resource
        policyDocument["Statement"].append(statementOne)
        authResponse["policyDocument"] = policyDocument
    authResponse["context"] = {
        "stringKey": "value",
        "numberKey": 123,
        "booleanKey": True
    }
    print(f"Generated policy: {json.dumps(authResponse)}")
    return authResponse

def generateAllow(principalId, resource):
    """Generates an IAM policy allowing access."""
    return generate_policy(principalId, "Allow", resource)

def generateDeny(principalId, resource):
    """Generates an IAM policy denying access."""
    return generate_policy(principalId, "Deny", resource)

def main(event, context):
    """Lambda function handler for API Gateway authorization."""
    resource = event.get("methodArn", "*")

    print("Fetching expected token from Secrets Manager")
    expected_token = get_expected_token()
    print("Expected token retrieved successfully")
    

    try:
        auth_header = None
        if event.get("headers"):
            auth_header = event["headers"].get("authorization") or event["headers"].get(
                "Authorization"
            )

        if not auth_header:
            print("Authorization header missing")
            return generateDeny("user", resource)

        parts = auth_header.split()
        if len(parts) != 2 or parts[0].lower() != "bearer":
            print(f"Invalid Authorization header format: {auth_header}")
            return generateDeny("user", resource)

        provided_token = parts[1]

        if provided_token != expected_token:
            print("Provided token does not match expected token.")
            return generateDeny("user", resource)

        print("Authentication successful.")
        return generateAllow("user", resource)
    except BaseException:
        print('denied')
        return generateDeny("user", resource)
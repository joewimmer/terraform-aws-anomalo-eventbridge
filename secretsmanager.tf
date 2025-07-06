# Add a secret for the Anomalo API key
# Ensures that the AWS Secret is unique by appending a random suffix due to the SM lifecycle limitations
resource "random_string" "anomalo_secret_suffix" {
  length  = 6
  upper   = false
  lower   = true
  special = false
}



resource "aws_secretsmanager_secret" "anomalo_eventbridge_publisher_api_key" {
  name        = "anomalo/event-bus/auth-${random_string.anomalo_secret_suffix.result}"
  description = "Anomalo API key for authentication to publish events to EventBridge"
}

resource "random_string" "anomalo_eventbridge_publisher_api_key" {
  length  = 32
  upper   = false
  lower   = true
  special = false
}
resource "aws_secretsmanager_secret_version" "anomalo_eventbridge_publisher_api_key_version" {
  secret_id     = aws_secretsmanager_secret.anomalo_eventbridge_publisher_api_key.id
  secret_string = random_string.anomalo_eventbridge_publisher_api_key.result
}

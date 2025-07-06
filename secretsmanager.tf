# Add a secret for the Anomalo API key
resource "random_string" "anomalo_secret_suffix" {
  length  = 12
  upper   = false
  lower   = true
  special = false
}

resource "aws_secretsmanager_secret" "anomalo_eventbridge_publisher_api_key" {
  name        = "anomalo/event-bus/auth-${random_string.anomalo_secret_suffix.result}"
  description = "Anomalo API key for authentication to publish events to EventBridge"
}

resource "aws_secretsmanager_secret_version" "anomalo_eventbridge_publisher_api_key_version" {
  secret_id     = aws_secretsmanager_secret.anomalo_eventbridge_publisher_api_key.id
  secret_string = var.eventbridge_api_key
}

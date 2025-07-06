output "api_endpoint" {
  value       = "${aws_api_gateway_stage.default_stage.invoke_url}/events/anomalo"
  description = "The endpoint URL of the Anomalo Events API"
}

output "event_bus_arn" {
  value       = aws_cloudwatch_event_bus.anomalo_event_bus.arn
  description = "The ARN of the Anomalo EventBridge event bus"
}

output "anomalo_api_key" {
  value       = random_string.anomalo_eventbridge_publisher_api_key.result
  description = "This is the Anomalo API key used to authenticate requests from Anomalo to EventBridge"
}
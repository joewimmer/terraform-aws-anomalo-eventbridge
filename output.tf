output "api_endpoint" {
  value       = aws_apigatewayv2_api.anomalo_http_api.api_endpoint
  description = "The endpoint URL of the Anomalo HTTP API"
}

output "event_bus_arn" {
  value       = aws_cloudwatch_event_bus.anomalo_event_bus.arn
  description = "The ARN of the Anomalo EventBridge event bus"
}

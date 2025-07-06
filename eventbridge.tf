# EventBridge Rule to trigger the Lambda function
resource "aws_cloudwatch_event_bus" "anomalo_event_bus" {
  name = "anomalo"
}

resource "aws_cloudwatch_event_archive" "anomalo_event_archive" {
  name             = "anomalo"
  event_source_arn = aws_cloudwatch_event_bus.anomalo_event_bus.arn
  description      = "Archive for Anomalo events"
  retention_days   = 7
}

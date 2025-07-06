# API Gateway configuration to trigger the Lambda function
resource "aws_apigatewayv2_api" "anomalo_http_api" {
  name          = "AnomaloEventsAPI"
  description   = "API Gateway for Anomalo events"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.anomalo_http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.eventbridge_publisher.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "events_route" {
  api_id    = aws_apigatewayv2_api.anomalo_http_api.id
  route_key = "POST /events/anomalo"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_lambda_permission" "allow_http_api" {
  statement_id  = "AllowHttpApiInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.eventbridge_publisher.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.anomalo_http_api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.anomalo_http_api.id
  name        = "$default"
  auto_deploy = true
}

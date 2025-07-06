data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}


resource "aws_lambda_function" "eventbridge_publisher" {
  function_name    = "${local.prefix}-Publisher"
  description      = "Lambda function to publish events to EventBridge"
  filename         = data.archive_file.lambda_zip.output_path
  handler          = "eventbridge.main"
  source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)
  runtime          = "python3.11"
  role             = aws_iam_role.default.arn
  environment {
    variables = {
      EVENT_BUS_NAME           = aws_cloudwatch_event_bus.anomalo_event_bus.name
    }
  }
}


resource "aws_lambda_permission" "allow_http_api" {
  statement_id  = "AllowHttpApiInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.eventbridge_publisher.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.anomalo_rest_api.execution_arn}/*/*"
}
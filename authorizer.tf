data "archive_file" "authorizer_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "authorizer" {
  function_name    = "${local.prefix}-Authorizer"
  description      = "Lambda function to authorize API Gateway requests"
  filename         = data.archive_file.authorizer_zip.output_path
  handler          = "authorize.main"
  source_code_hash = filebase64sha256(data.archive_file.authorizer_zip.output_path)
  runtime          = "python3.11"
  role             = aws_iam_role.default.arn
  environment {
    variables = {
      SECRET_ARN = aws_secretsmanager_secret.anomalo_eventbridge_publisher_api_key.arn
    }
  }
}


resource "aws_api_gateway_authorizer" "anomalo_authorizer" {
  name                   = "${local.prefix}-Authorizer"
  rest_api_id            = aws_api_gateway_rest_api.anomalo_rest_api.id
  authorizer_uri         = aws_lambda_function.authorizer.invoke_arn
  authorizer_credentials = aws_iam_role.default.arn
  identity_source        = "method.request.header.Authorization"
  type                   = "REQUEST"
}



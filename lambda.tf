locals {
  prefix = "Anomalo-EventBridge"
}
# This Lambda function consumes check run events from Anomalo via the API Gateway and publishes them to EventBridge.
resource "aws_iam_role" "anomalo_lambda_publisher_role" {
  name = "${local.prefix}-Publisher-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "anomalo_lambda_eventbridge_access" {
  name = "${local.prefix}-Publisher-Policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "events:PutEvents"
      ],
      Resource = aws_cloudwatch_event_bus.anomalo_event_bus.arn
      },
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Resource = aws_secretsmanager_secret.anomalo_eventbridge_publisher_api_key.arn
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "anomalo_lambda_publisher" {
  role       = aws_iam_role.anomalo_lambda_publisher_role.name
  policy_arn = aws_iam_policy.anomalo_lambda_eventbridge_access.arn
}
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.anomalo_lambda_publisher_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}


resource "aws_lambda_function" "eventbridge_publisher" {
  function_name    = "${local.prefix}-Publisher"
  description      = "Lambda function to publish events to EventBridge"
  filename         = data.archive_file.lambda_zip.output_path
  handler          = "function.main"
  source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)
  runtime          = "python3.11"
  role             = aws_iam_role.anomalo_lambda_publisher_role.arn
  environment {
    variables = {
      EXPECTED_TOKEN_SECRET_ID = aws_secretsmanager_secret.anomalo_eventbridge_publisher_api_key.id
      EVENT_BUS_NAME           = aws_cloudwatch_event_bus.anomalo_event_bus.name
    }
  }
}

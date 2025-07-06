locals {
  prefix = "Anomalo-EventBridge"
}


resource "aws_iam_role" "default" {
  name = "${local.prefix}-Role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }, {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
            Service = "apigateway.amazonaws.com"
        }
    }]
  })
}

resource "aws_iam_policy" "default" {
  name = "${local.prefix}-Policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
        Effect = "Allow",
        Action = [
            "events:PutEvents"
        ],
        Resource = aws_cloudwatch_event_bus.anomalo_event_bus.arn
    },{
        Effect = "Allow",
        Action = [
            "secretsmanager:GetSecretValue"
        ],
        Resource = aws_secretsmanager_secret.anomalo_eventbridge_publisher_api_key.arn
    },{
        Effect = "Allow",
        Action = [
            "lambda:InvokeFunction",
        ],
        Resource = [aws_lambda_function.authorizer.arn, aws_lambda_function.eventbridge_publisher.arn]
    }]
  })
}
  

resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.default.name
  policy_arn = aws_iam_policy.default.arn
}

resource "aws_iam_role_policy_attachment" "lambda_authorizer_logs" {
  role       = aws_iam_role.default.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

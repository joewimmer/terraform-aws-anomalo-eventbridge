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


resource "aws_wafv2_ip_set" "allow_ips" {
  name               = "allow-anomalo-api-ips"
  description        = "Allowed IP addresses for API Gateway"
  scope              = "REGIONAL" # For API Gateway, use REGIONAL
  ip_address_version = "IPV4"

  addresses = var.ip_allow_list
}

resource "aws_wafv2_web_acl" "api_acl" {
  name        = "anomalo-api-waf-acl"
  description = "WAF ACL to allow only specific IPs for API Gateway"
  scope       = "REGIONAL"

  default_action {
    block {}
  }

  rule {
    name     = "allow-listed-ips"
    priority = 1

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.allow_ips.arn
      }
    }

    visibility_config {
      sampled_requests_enabled = true
      cloudwatch_metrics_enabled = true
      metric_name = "allow-listed-ips"
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "anomalo-api-waf"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "api_acl_association" {
  resource_arn = aws_apigatewayv2_stage.default_stage.arn
  web_acl_arn  = aws_wafv2_web_acl.api_acl.arn
}

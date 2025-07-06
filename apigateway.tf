# API Gateway configuration to trigger the Lambda function
resource "aws_api_gateway_rest_api" "anomalo_rest_api" {
  name        = "AnomaloEventsAPI"
  description = "REST API Gateway for Anomalo events"
}

resource "aws_api_gateway_resource" "events_resource" {
  rest_api_id = aws_api_gateway_rest_api.anomalo_rest_api.id
  parent_id   = aws_api_gateway_rest_api.anomalo_rest_api.root_resource_id
  path_part   = "events"
}

resource "aws_api_gateway_resource" "anomalo_resource" {
  rest_api_id = aws_api_gateway_rest_api.anomalo_rest_api.id
  parent_id   = aws_api_gateway_resource.events_resource.id
  path_part   = "anomalo"
}

resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.anomalo_rest_api.id
  resource_id   = aws_api_gateway_resource.anomalo_resource.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.anomalo_authorizer.id
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.anomalo_rest_api.id
  resource_id             = aws_api_gateway_resource.anomalo_resource.id
  http_method             = aws_api_gateway_method.post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.eventbridge_publisher.invoke_arn
}

resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.eventbridge_publisher.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.anomalo_rest_api.execution_arn}/*/POST/events/anomalo"
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.anomalo_rest_api.id
  depends_on  = [aws_api_gateway_integration.lambda_integration]
}

# API Gateway stage to expose the API
resource "aws_api_gateway_stage" "default_stage" {
  rest_api_id = aws_api_gateway_rest_api.anomalo_rest_api.id
  stage_name  = "production"
  deployment_id = aws_api_gateway_deployment.deployment.id
  description = "Production stage for Anomalo Events API"
}



resource "aws_wafv2_ip_set" "allow_ips" {
  count              = length(var.ip_allow_list) > 0 ? 1 : 0
  name               = "allow-anomalo-api-ips"
  description        = "Allowed IP addresses for API Gateway"
  scope              = "REGIONAL" # For API Gateway, use REGIONAL
  ip_address_version = "IPV4"
  addresses          = var.ip_allow_list
}

resource "aws_wafv2_web_acl" "api_acl" {
  count       = length(var.ip_allow_list) > 0 ? 1 : 0
  name        = "anomalo-eventbridge-api-acl"
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
        arn = aws_wafv2_ip_set.allow_ips[0].arn
      }
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "allow-listed-ips"
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "anomalo-eventbridge-api-waf"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "api_acl_association" {
  count        = length(var.ip_allow_list) > 0 ? 1 : 0
  resource_arn = aws_api_gateway_stage.default_stage.arn
  web_acl_arn  = aws_wafv2_web_acl.api_acl[0].arn
}

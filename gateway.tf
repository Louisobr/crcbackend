resource "aws_apigatewayv2_api" "aws_apigatewayv2_api" {
  name          = "cvgateway"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = [ "https://${aws_cloudfront_distribution.s3_distribution.domain_name}", "https://${aws_cloudfront_distribution.s3_distribution.domain_name}" ]
    allow_headers = ["*", "access-control-allow-origin", "content-type"]
    allow_methods = ["POST", "OPTIONS"]
  }

}

resource "aws_apigatewayv2_integration" "cvintegration" {
  api_id           = aws_apigatewayv2_api.aws_apigatewayv2_api.id
  integration_type = "AWS_PROXY"

  connection_type           = "INTERNET"
#   content_handling_strategy = "CONVERT_TO_TEXT"
  integration_method        = "POST"
  integration_uri           = aws_lambda_function.increment.invoke_arn
#   passthrough_behavior      = "WHEN_NO_MATCH"

  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "cvroute" {
  api_id    = aws_apigatewayv2_api.aws_apigatewayv2_api.id
  route_key = "POST /items/{id}"

  target = "integrations/${aws_apigatewayv2_integration.cvintegration.id}"
}

output "domainname" {
    value = aws_cloudfront_distribution.s3_distribution.domain_name
}

resource "aws_apigatewayv2_stage" "cvstage" {
  api_id      = aws_apigatewayv2_api.aws_apigatewayv2_api.id
  name        = "$default"
  auto_deploy = true
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn
    format = jsonencode({
      requestId        = "$context.requestId"
      ip               = "$context.identity.sourceIp"
      requestTime      = "$context.requestTime"
      httpMethod       = "$context.httpMethod"
      routeKey         = "$context.routeKey"
      status           = "$context.status"
      protocol         = "$context.protocol"
      responseLength   = "$context.responseLength"
      errorMessage     = "$context.error.message"
      integrationError = "$context.integrationErrorMessage"
    })
  }
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name              = "/aws/api_gw/${aws_apigatewayv2_api.aws_apigatewayv2_api.name}"
  retention_in_days = 7
}
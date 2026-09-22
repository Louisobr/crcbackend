# IAM role for Lambda execution
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "example" {
  name               = "lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Package the Lambda function code
data "archive_file" "example" {
  type        = "zip"
  source_file = "lambda.py"
  output_path = "${path.module}/lambda/function.zip"
}

# Lambda function
resource "aws_lambda_function" "increment" {
  filename      = data.archive_file.example.output_path
  function_name = "lambda"
  role          = aws_iam_role.dynamodb_role.arn
  handler       = "lambda.lambda_handler"
#   code_sha256   = data.archive_file.example.output_base64sha256

  runtime = "python3.9"

  environment {
    variables = {
      ENVIRONMENT = "production"
      LOG_LEVEL   = "info"
    }
  }

  tags = {
    Environment = "production"
    Application = "example"
  }
}

# 1. Define the IAM Role and Trust Policy
resource "aws_iam_role" "dynamodb_role" {
  name = "dynamodb-full-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com" # Change to your target service (e.g., lambda.amazonaws.com)
        }
      }
    ]
  })
}

# 2. Attach the AmazonDynamoDBFullAccess_v2 Managed Policy
resource "aws_iam_role_policy_attachment" "dynamodb_full_access" {
  role       = aws_iam_role.dynamodb_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess_v2"
}

# resource "aws_lambda_resource_policy" "example" {
#   resource_arn = aws_lambda_function.example.arn
#   policy       = data.aws_iam_policy_document.example.json
# }

# data "aws_iam_policy_document" "example" {
#   statement {
#     sid    = "AllowInvokeFromGateway"
#     effect = "Allow"

#     principals {
#       type        = "Service"
#       identifiers = ["apigateway.amazonaws.com"]
#     }

#     actions   = ["lambda:InvokeFunction"]
#     resources = [aws_lambda_function.increment.arn]

#     condition {
#         test     = "ArnLike"
#         variable = "AWS:SourceArn"
#         values   = ["arn:aws:apigateway:eu-west-2::/apis/wvx8dre2vk/*/*/{id}"]
#     }
#   }
# }

resource "aws_lambda_permission" "apigateway_invoke" {
  statement_id  = "AllowInvokeFromGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.increment.function_name
  principal     = "apigateway.amazonaws.com"

  # SourceArn for API Gateway execution uses execute-api format:
  # arn:aws:execute-api:<region>:<account-id>:<api-id>/<stage>/<method>/<path>
  source_arn = "${aws_apigatewayv2_api.aws_apigatewayv2_api.execution_arn}/*/*/items/{id}"
}

resource "aws_lambda_permission" "apigateway_invoke2" {
  statement_id  = "AllowInvokeFromGateway2"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.increment.function_name
  principal     = "apigateway.amazonaws.com"

  # SourceArn for API Gateway execution uses execute-api format:
  # arn:aws:execute-api:<region>:<account-id>:<api-id>/<stage>/<method>/<path>
  source_arn = "${aws_apigatewayv2_api.aws_apigatewayv2_api.execution_arn}/*/*/items/{id}"
}
terraform {
  required_version = ">= 1.14.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}

# resource "aws_s3_bucket" "cvbucketstate" {
#   bucket = "cvbucketstate4949494state"
#   acl    = "private"

#   versioning {
#     enabled = true
#   }

#   server_side_encryption_configuration {
#     rule {
#       apply_server_side_encryption_by_default {
#         sse_algorithm = "AES256"
#       }
#     }
#   }
# }

terraform {
  backend "s3" {
    bucket         = "cvbucketstate4949494state"
    key            = "terraform.tfstate"
    region         = "eu-west-2"
    use_lockfile   = true
    encrypt        = true
  }
}

resource aws_ssm_parameter apiurl {
  name  = "apiuri"
  type  = "String"
  value = aws_apigatewayv2_api.aws_apigatewayv2_api.api_endpoint
}

resource aws_s3_bucket testbucket {
  bucket = "testalskdfjuoooo"
}
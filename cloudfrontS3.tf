resource "aws_s3_bucket" "cvbucket4949494" {
  bucket = "cvbucket4949494"
}

# See https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html
data "aws_iam_policy_document" "origin_bucket_policy" {
  statement {
    sid    = "AllowCloudFrontServicePrincipalReadWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.cvbucket4949494.arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.s3_distribution.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "b" {
  bucket = aws_s3_bucket.cvbucket4949494.bucket
  policy = data.aws_iam_policy_document.origin_bucket_policy.json
}

locals {
  s3_origin_id = "myS3Origin"
  my_domain    = "mydomain.com"
  bucketname = "cvbucket4949494"
}

# data "aws_acm_certificate" "my_domain" {
#   region   = "eu-west-2"
#   domain   = "*.${local.my_domain}"
#   statuses = ["ISSUED"]
# }

resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "default-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.cvbucket4949494.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"
  default_root_object = "index.html"

  # aliases = ["mysite.${local.my_domain}", "yoursite.${local.my_domain}"]

  default_cache_behavior {
    allowed_methods  = ["HEAD", "GET", "OPTIONS"]
    cached_methods   = ["HEAD", "GET", "OPTIONS"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    # min_ttl                = 0
    # default_ttl            = 86400
    # max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "/content/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    # acm_certificate_arn = data.aws_acm_certificate.my_domain.arn
    cloudfront_default_certificate = true
    # ssl_support_method  = "sni-only"
  }
}

# Create Route53 records for the CloudFront distribution aliases
# data "aws_route53_zone" "my_domain" {
#   name = local.my_domain
# }

# resource "aws_route53_record" "cloudfront" {
#   for_each = aws_cloudfront_distribution.s3_distribution.aliases
#   zone_id  = data.aws_route53_zone.my_domain.zone_id
#   name     = each.value
#   type     = "A"

#   alias {
#     name                   = aws_cloudfront_distribution.s3_distribution.domain_name
#     zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
#     evaluate_target_health = false
#   }
# }

# resource "aws_s3_object" "indexpage" {
#   bucket = aws_s3_bucket.cvbucket4949494.id
#   key    = "index.html"
#   source = "webfiles/index.html"
#   content_type = "text/html"
# }
# resource "aws_s3_object" "error404" {
#   bucket = aws_s3_bucket.cvbucket4949494.id
#   key    = "404.html"
#   source = "webfiles/404.html"
#   content_type = "text/html"
# }
# resource "aws_s3_object" "scriptjs" {
#   bucket = aws_s3_bucket.cvbucket4949494.id
#   key    = "script.js"
#   source = "webfiles/script.js"
#   content_type = "application/javascript"
# }
# resource "aws_s3_object" "stylecss" {
#   bucket = aws_s3_bucket.cvbucket4949494.id
#   key    = "styling.css"
#   source = "webfiles/styling.css"
#   content_type = "text/css"
# }

# data "aws_acm_certificate" "my_domain" {
#   domain   = "*.${local.my_domain}"
#   statuses = ["ISSUED"]
# }

# action "aws_cloudfront_create_invalidation" "invalidate" {
#   config {
#     distribution_id = aws_cloudfront_distribution.s3_distribution.id
#     paths           = ["/*"]
#   }
# }

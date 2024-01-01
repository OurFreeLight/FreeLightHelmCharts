# tf/aws/static_web_hosting.tf

data "aws_canonical_user_id" "current" {}

# S3 Bucket for static web hosting
resource "aws_s3_bucket" "freelight_s3_bucket" {
  bucket        = var.domain
  count         = var.frontend_deployment_type == "cloudfront" ? 1 : 0
  force_destroy = !var.delete_protection

  object_lock_enabled = false
}

resource "aws_s3_bucket_public_access_block" "freelight_s3_public_access_block" {
  bucket = aws_s3_bucket.freelight_s3_bucket[0].id
  count  = var.frontend_deployment_type == "cloudfront" ? 1 : 0

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "freelight_s3_bucket_ownership_controls" {
  bucket = aws_s3_bucket.freelight_s3_bucket[0].id
  count  = var.frontend_deployment_type == "cloudfront" ? 1 : 0

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "freelight_s3_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.freelight_s3_bucket_ownership_controls[0]]
  bucket     = aws_s3_bucket.freelight_s3_bucket[0].id
  count      = var.frontend_deployment_type == "cloudfront" ? 1 : 0

  access_control_policy {
    grant {
      grantee {
        id   = data.aws_canonical_user_id.current.id
        type = "CanonicalUser"
      }
      permission = "FULL_CONTROL"
    }

    owner {
      id = data.aws_canonical_user_id.current.id
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "freelight_s3_bucket_enc_config" {
  bucket = aws_s3_bucket.freelight_s3_bucket[0].id
  count  = var.frontend_deployment_type == "cloudfront" ? 1 : 0

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }

    bucket_key_enabled = false
  }
}

resource "aws_s3_bucket_versioning" "freelight_s3_bucket_versioning" {
  bucket       = aws_s3_bucket.freelight_s3_bucket[0].id
  count        = var.frontend_deployment_type == "cloudfront" ? 1 : 0

  versioning_configuration {
    status     = "Disabled"
    mfa_delete = "Disabled"
  }

  lifecycle {
    ignore_changes = [versioning_configuration[0].mfa_delete]
  }
}

resource "aws_s3_bucket_website_configuration" "freelight_s3_bucket_website_config" {
  bucket       = aws_s3_bucket.freelight_s3_bucket[0].id
  count        = var.frontend_deployment_type == "cloudfront" ? 1 : 0

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# ACM Certificate for CloudFront
resource "aws_acm_certificate" "freelight_acm_certificate" {
  provider      = aws.us_east_1
  domain_name   = var.domain
  key_algorithm = "RSA_2048"
  count         = var.frontend_deployment_type == "cloudfront" ? 1 : 0

  options {
    certificate_transparency_logging_preference = "ENABLED"
  }

  subject_alternative_names = [var.domain]

  tags = {
    Name = var.domain
  }

  tags_all = {
    Name = var.domain
  }

  validation_method = "DNS"
}

data "aws_route53_zone" "freelight_route53_zone" {
  name         = "${var.root_domain}."
  private_zone = false
}

resource "aws_route53_record" "freelight_acm_certificate_dns_record" {
  for_each = {
    for dvo in aws_acm_certificate.freelight_acm_certificate[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      value  = dvo.resource_record_value
    }
  }

  name    = each.value.name
  type    = each.value.type
  zone_id = data.aws_route53_zone.freelight_route53_zone.zone_id
  records = [each.value.value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "freelight_acm_certificate_validation" {
  provider                = aws.us_east_1
  count                   = var.frontend_deployment_type == "cloudfront" ? 1 : 0
  certificate_arn         = aws_acm_certificate.freelight_acm_certificate[0].arn
  validation_record_fqdns = [for record in aws_route53_record.freelight_acm_certificate_dns_record : record.fqdn]
}

# CloudFront distribution for static web hosting
resource "aws_cloudfront_cache_policy" "freelight_cloudfront_cache_policy" {
  name        = "freelight-caching-policy"
  depends_on  = [aws_acm_certificate_validation.freelight_acm_certificate_validation[0]]
  count       = var.frontend_deployment_type == "cloudfront" ? 1 : 0
  comment     = "Freelight cache policy"
  default_ttl = 50
  max_ttl     = 100
  min_ttl     = 1

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }

    enable_accept_encoding_gzip = false
    enable_accept_encoding_brotli = false

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

resource "aws_cloudfront_distribution" "freelight_cloudfront_distribution" {
  aliases    = [var.domain]
  depends_on = [aws_acm_certificate_validation.freelight_acm_certificate_validation[0]]
  count      = var.frontend_deployment_type == "cloudfront" ? 1 : 0

  default_cache_behavior {
    allowed_methods            = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cache_policy_id            = "${aws_cloudfront_cache_policy.freelight_cloudfront_cache_policy[0].id}"
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    smooth_streaming           = false
    target_origin_id           = aws_s3_bucket.freelight_s3_bucket[0].bucket_regional_domain_name
    viewer_protocol_policy     = "redirect-to-https"
  }

  enabled             = true
  http_version        = "http2"
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  origin {
    connection_attempts = 3
    connection_timeout  = 10

    origin_path = "/latest"

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_keepalive_timeout = 5
      origin_protocol_policy   = "http-only"
      origin_read_timeout      = 30
      origin_ssl_protocols     = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }

    domain_name = aws_s3_bucket.freelight_s3_bucket[0].bucket_regional_domain_name
    origin_id   = aws_s3_bucket.freelight_s3_bucket[0].bucket_regional_domain_name
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  retain_on_delete = false
  staging          = false

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/"
  }

  viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate.freelight_acm_certificate[0].arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
    cloudfront_default_certificate = false
  }
}

resource "aws_route53_record" "freelight_route53_zone_record" {
  depends_on = [aws_cloudfront_distribution.freelight_cloudfront_distribution[0]]
  count      = var.frontend_deployment_type == "cloudfront" ? 1 : 0

  zone_id = data.aws_route53_zone.freelight_route53_zone.zone_id
  name    = var.domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.freelight_cloudfront_distribution[0].domain_name
    zone_id                = aws_cloudfront_distribution.freelight_cloudfront_distribution[0].hosted_zone_id
    evaluate_target_health = false
  }
}

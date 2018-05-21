/*  Brendan McCloskey    mbrendan@vt.edu    www.brendanmccloskey.com
    Practice script, used for setting up infrastructure with AWS hosted website

    Route53 -> Cloudfront (for https) -> S3
    www.brendanmccloskey.com is the main website, all requests to brendanmccloskey.com are
    redirected to the main website (alias connecting it to the www cloudfront dist)

    Also will upload files, must run <python indexfiles.py> to create this file, then upload
        using <terraform apply>. Need to delete files before reuploading on main website.
*/

################################################################################
#   PROVIDER
################################################################################
provider "aws" {
  access_key  = "${var.aws_access_key}"
  secret_key  = "${var.aws_secret_key}"
  region      = "${var.aws_region}"
}

################################################################################
#   ALIAS, CERTIFICATE SETUP
################################################################################

# find specific route53 zone with correct ns setup
data "aws_route53_zone" "route53_zone" {
  zone_id = "${var.website_zone_id}"
}

# main alias, connect to main bucket
resource "aws_route53_record" "www-a-record" {
  zone_id = "${data.aws_route53_zone.route53_zone.zone_id}"
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                    = "${aws_cloudfront_distribution.www_cloudfront_dist.domain_name}"
    zone_id                 = "${aws_cloudfront_distribution.www_cloudfront_dist.hosted_zone_id}"
    evaluate_target_health  = false
  }
}

# redirect alias, connect to redirect bucket (which connects to main bucket)
resource "aws_route53_record" "redir-a-record" {
  zone_id = "${data.aws_route53_zone.route53_zone.zone_id}"
  name    = "${var.domain_name}"
  type    = "A"

  alias {
    name                    = "${aws_cloudfront_distribution.www_cloudfront_dist.domain_name}"
    zone_id                 = "${aws_cloudfront_distribution.www_cloudfront_dist.hosted_zone_id}"
    evaluate_target_health  = false
  }
}

# cloudfront distribution for www.brendanmccloskey.com (https certification)
resource "aws_cloudfront_distribution" "www_cloudfront_dist" {
  enabled             = true
  aliases             = ["www.${var.domain_name}", "${var.domain_name}"]
  price_class         = "${var.price_class}"

  origin {
    domain_name = "${aws_s3_bucket.www_bucket_main.website_endpoint}"
    origin_id   = "website_bucket_origin"

    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods  = ["HEAD", "GET"]
    "forwarded_values" {
      "cookies" {
        forward     = "none"
      }
      query_string  = true
    }
    target_origin_id        = "website_bucket_origin"
    viewer_protocol_policy  = "redirect-to-https"

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  viewer_certificate {
    minimum_protocol_version = "TLSv1"
    acm_certificate_arn = "${var.certificate_arn}"
    ssl_support_method = "sni-only"
  }

  restrictions {
    "geo_restriction" {
      restriction_type = "none"
    }
  }
}

################################################################################
#   STORAGE
################################################################################

# main website bucket (www.brendanmccloskey.com)
resource "aws_s3_bucket" "www_bucket_main" {
  bucket        = "www.${var.domain_name}"
  acl           = "public-read"
  force_destroy = true

  # policy allows website files (e.g. index.html) to be retrievable
  policy = <<POLICY
{
  "Version":"2012-10-17",
  "Statement":[{
    "Sid":"PublicReadForGetBucketObjects",
        "Effect":"Allow",
      "Principal": "*",
      "Action":"s3:GetObject",
      "Resource":["arn:aws:s3:::www.${var.domain_name}/*"
      ]
    }
  ]
}
POLICY

  # connect to main document and branch from there
  website {
    index_document = "index.html"
  }

  # point to log bucket
  logging {
    target_bucket = "${aws_s3_bucket.bucket_log.bucket}"
    target_prefix = "log/"
  }
}

# log bucket
resource "aws_s3_bucket" "bucket_log" {
  bucket        = "logs.${var.domain_name}"
  acl           = "log-delivery-write"
  force_destroy = true
}

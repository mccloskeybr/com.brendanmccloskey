# provider information
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region" {
  default = "us-east-1"
}

# dns/route53 information
variable "domain_name" {}
variable "website_zone_id" {}

# certificate/cloudfront information
variable "price_class" {
  default = "PriceClass_100"
}
variable "certificate_arn" {}

# provider information
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region" {
  default = "us-east-1"
}

# dns/route53 information
variable "domain_name" {}
variable "website_zone_id" {}


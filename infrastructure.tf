/*  Brendan McCloskey    mbrendan@vt.edu    www.brendanmccloskey.com
    Practice script, used for setting up infrastructure with AWS hosted website

    Route53 -> EC2 with Wordpress (Bitnami)
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
#   ALIAS SETUP
################################################################################

# find specific route53 zone with correct ns setup
data "aws_route53_zone" "route53_zone" {
  zone_id = "${var.website_zone_id}"
}

# main alias
resource "aws_route53_record" "www-a-record" {
  zone_id = "${data.aws_route53_zone.route53_zone.zone_id}"
  name    = "www.${var.domain_name}"
  type    = "A"
  ttl = 300
  records = ["${aws_eip.wordpress_eip.public_ip}"]
}

# redirect alias
resource "aws_route53_record" "redir-a-record" {
  zone_id = "${data.aws_route53_zone.route53_zone.zone_id}"
  name    = "${var.domain_name}"
  type    = "A"
  ttl = 300
  records = ["${aws_eip.wordpress_eip.public_ip}"]
}

################################################################################
#   SECURITY
################################################################################

resource "aws_security_group" "wordpress_securitygroup" {
  name = "WordPress-SecurityGroup"
  description = "Control access to wordpress ec2 instance (managed by terraform)"
}

# http
resource "aws_security_group_rule" "wordpress_security_ingress_http" {
  from_port = 80
  to_port = 80
  protocol = "tcp"
  security_group_id = "${aws_security_group.wordpress_securitygroup.id}"
  type = "ingress"
  cidr_blocks = ["0.0.0.0/0"]
}

# https
resource "aws_security_group_rule" "wordpress_security_ingress_https" {
  from_port = 443
  to_port = 443
  protocol = "tcp"
  security_group_id = "${aws_security_group.wordpress_securitygroup.id}"
  type = "ingress"
  cidr_blocks = ["0.0.0.0/0"]
}

# ssh
resource "aws_security_group_rule" "wordpress_security_ingress_ssh" {
  from_port = 22
  to_port = 22
  protocol = "tcp"
  security_group_id = "${aws_security_group.wordpress_securitygroup.id}"
  type = "ingress"
  cidr_blocks = ["0.0.0.0/0"]
}

# default in
resource "aws_security_group_rule" "wordpress_security_ingress_reply" {
  from_port = 1024
  to_port = 65535
  protocol = "tcp"
  security_group_id = "${aws_security_group.wordpress_securitygroup.id}"
  type = "ingress"
  cidr_blocks = ["0.0.0.0/0"]
}

# out
resource "aws_security_group_rule" "wordpress_security_egress_reply" {
  from_port = 0
  to_port = 0
  protocol = "all"
  security_group_id = "${aws_security_group.wordpress_securitygroup.id}"
  type = "egress"
  cidr_blocks = ["0.0.0.0/0"]
}

################################################################################
#   WORDPRESS
################################################################################

# Elastic ip allows for consistent ip
resource "aws_eip" "wordpress_eip" {
  instance = "${aws_instance.wordpress_ec2.id}"
  vpc = false
}

# Note: requires a pre-existing key named "wordpress" to already exist.
resource "aws_instance" "wordpress_ec2" {
  ami = "ami-cce584b3"
  instance_type = "t2.micro"
  key_name = "wordpress"
  associate_public_ip_address = true

  security_groups = [
    "${aws_security_group.wordpress_securitygroup.name}"
  ]

  root_block_device {
    volume_type = "standard"
    volume_size = 40
  }

  tags {
    Name = "WordPress"
    description = "managed by terraform"
  }
}


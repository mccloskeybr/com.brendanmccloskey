# com.brendanmccloskey
terraform infrastructure for aws hosted website

Creates a website using AWS services (you must purchase or own the domain name before running this script)

Uses route 53 to set up aliases between the given domain name and an ec2 instance running wordpress.

Prerequisites:
  Route53 Hosting Zone must already be created. The zone id of the hosting zone must be passed in to achieve expected functionality.
  A key pair for ec2 must be created named "wordpress". This is used to ssh into the ec2 instance.

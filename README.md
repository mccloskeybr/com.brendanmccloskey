# com.brendanmccloskey
terraform infrastructure for aws hosted website

Creates a website using AWS services (you must purchase or own the domain name before running this script)

Uses route 53 to set up aliases between the given domain name and cloudfront (used for https) which is then passed to Amazon S3.

Prerequisites:
  Route53 Hosting Zone must already be created. The zone id of the hosting zone must be passed in to achieve expected functionality.
  A certificate must already be given to your website (most likely through Amazon Certificate Manager). The ARN for this certificate must be passed into the script as well.

Results:
  Creates 2 S3 buckets: www.domainname and logs.domainname. www.domainname is the main host of the resulting website and logs are written to s3:logs.domainname/logs/
  Aliases are created, from your domainname to Cloudfront, for certification processing (redirection to https is automatic)

# Terraform-aws-iam-2FA
A set of group permissions that enforces 2FA and safety nets 

### Meta features
- S3 as state backend with dynamo DB locking

### IAM Features
- Sets password strength
- Forces 2FA
- Forces a single/group of regions allowed for ec2
- Forces a single/group of regions allowed for S3 buckets
- Optional admin group allows assuming a role for superuser

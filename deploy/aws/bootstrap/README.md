# Bootstrap - Terraform Backend Setup

Pure Terraform module to bootstrap your AWS backend infrastructure.

## Usage

```bash
cd deploy/aws/bootstrap
tofu init
tofu plan
tofu apply
```

This creates:
- S3 bucket with versioning and encryption
- DynamoDB table for state locking
- Output configuration for your deployments

## After Bootstrap

The module outputs the backend configuration. Use it in your deployments:

```hcl
terraform {
  backend "s3" {
    bucket         = "OUTPUT_FROM_BOOTSTRAP"
    key            = "preview/lambda/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "OUTPUT_FROM_BOOTSTRAP"
    encrypt        = true
  }
}
```
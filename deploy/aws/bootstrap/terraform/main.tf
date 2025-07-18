terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

locals {
  bucket_name = var.bucket_name != "" ? var.bucket_name : "terraform-state-${data.aws_caller_identity.current.account_id}-${random_id.bucket_suffix.hex}"
  table_name  = var.table_name != "" ? var.table_name : "terraform-state-locks"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_s3_bucket" "terraform_state" {
  bucket = local.bucket_name
  
  # Force destroy even if bucket contains objects
  # WARNING: This will delete all state files when destroying!
  force_destroy = true

  tags = merge(
    var.tags,
    {
      Name        = "Terraform State Bucket"
      Environment = "global"
      ManagedBy   = "terraform"
    }
  )
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "expire_old_versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = local.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(
    var.tags,
    {
      Name        = "Terraform State Lock Table"
      Environment = "global"
      ManagedBy   = "terraform"
    }
  )
}

resource "local_file" "backend_config" {
  content = templatefile("${path.module}/templates/backend.tf.tpl", {
    bucket         = aws_s3_bucket.terraform_state.id
    region         = data.aws_region.current.name
    dynamodb_table = aws_dynamodb_table.terraform_locks.id
  })
  filename = "${path.module}/../../backend-config.tf"
}


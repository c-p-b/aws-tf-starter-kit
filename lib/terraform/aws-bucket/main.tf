module "label" {
  source = "../aws-label"

  name        = var.name
  environment = var.environment
  team        = var.team
  tags        = var.tags
}

resource "aws_s3_bucket" "this" {
  count = var.aws_bucket_enabled ? 1 : 0

  bucket        = var.bucket_name_override ? module.label.name : null
  bucket_prefix = var.bucket_name_override ? null : module.label.prefix


  force_destroy = var.aws_bucket_destruction_enabled
  tags          = module.label.tags
}

resource "aws_s3_bucket_ownership_controls" "this" {
  count = var.aws_bucket_enabled ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  rule {
    object_ownership = var.aws_bucket_object_ownership
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  count = var.aws_bucket_enabled ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  # Never allow public access to buckets
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# TODO: support enabling MFA Delete
resource "aws_s3_bucket_versioning" "this" {
  count = var.aws_bucket_enabled ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  versioning_configuration {
    # TODO: support "Disabled" for importing pre-existing buckets that do not
    # have existing versioning configuration
    status = var.aws_bucket_versioning_enabled ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count = alltrue([var.aws_bucket_enabled, var.aws_bucket_encryption_enabled]) ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  rule {
    bucket_key_enabled = var.bucket_key_enabled

    apply_server_side_encryption_by_default {
      sse_algorithm = var.server_side_encryption_algorithm

      kms_master_key_id = null
    }
  }
}

locals {

  https_only_policy = <<EOL
     {"Version": "2012-10-17","Statement":[{"Sid": "AllowSSLRequestsOnly","Effect": "Deny","Action": "s3:*","Resource": ["${aws_s3_bucket.this[0].arn}", "${aws_s3_bucket.this[0].arn}/*"],"Principal":{"AWS": "*"},"Condition":{"Bool":{"aws:SecureTransport": "false"}}}]}
  EOL

  resource_list = var.aws_bucket_policy_json == null ? null : [for i in toset(flatten([for k in [
    for p in [jsondecode(var.aws_bucket_policy_json), jsondecode(local.https_only_policy)] :
    merge(p, {
      Statement = flatten([
        for s in p.Statement : [
          merge(s, {
            "Resource" : [
            toset(concat(flatten([s.Resource]), [aws_s3_bucket.this[0].arn]))]
          })
        ]
      ])
    })
  ] : k.Statement][*][*].Resource)) : i if i != "*"]

  statement_list = var.aws_bucket_policy_json == null ? null : flatten([for k in [
    for p in [jsondecode(var.aws_bucket_policy_json), jsondecode(local.https_only_policy)] :
    merge(p, {
      Statement = flatten([
        for s in p.Statement : [
          merge(s, {
            "Resource" : flatten(local.resource_list)
          })
        ]
      ])
    })
  ] : k.Statement])

  aws_bucket_policy = var.aws_bucket_policy_json == null ? null : jsonencode({ "Version" : "2012-10-17", "Statement" = "${local.statement_list}" })
}

resource "aws_s3_bucket_policy" "this" {
  count = var.aws_bucket_enabled && var.aws_bucket_policy_json != null ? 1 : 0

  bucket = aws_s3_bucket.this[0].id
  policy = local.aws_bucket_policy
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = var.aws_bucket_enabled && length(var.aws_bucket_lifecycle_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  dynamic "rule" {
    for_each = var.aws_bucket_lifecycle_rules

    content {
      id     = rule.value.id
      status = rule.value.enabled == true ? "Enabled" : "Disabled"


      dynamic "abort_incomplete_multipart_upload" {
        for_each = rule.value.abort_incomplete_multipart_upload != null ? [rule.value.abort_incomplete_multipart_upload] : []

        content {
          days_after_initiation = abort_incomplete_multipart_upload.value.days_after_initiation
        }
      }

      dynamic "expiration" {
        for_each = rule.value.expiration != null ? [rule.value.expiration] : []

        content {
          date                         = expiration.value.date
          days                         = expiration.value.days
          expired_object_delete_marker = expiration.value.expired_object_delete_marker
        }
      }

      dynamic "transition" {
        for_each = rule.value.transition != null ? rule.value.transition : []

        content {
          date          = transition.value.date
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration != null ? [rule.value.noncurrent_version_expiration] : []

        content {
          newer_noncurrent_versions = noncurrent_version_expiration.value.newer_noncurrent_versions
          noncurrent_days           = noncurrent_version_expiration.value.noncurrent_days
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = rule.value.noncurrent_version_transition != null ? rule.value.noncurrent_version_transition : []

        content {
          newer_noncurrent_versions = noncurrent_version_transition.value.newer_noncurrent_versions
          noncurrent_days           = noncurrent_version_transition.value.noncurrent_days
          storage_class             = noncurrent_version_transition.value.storage_class
        }
      }

      dynamic "filter" {
        # Filter is a required object, so wrap it in a list.
        for_each = [rule.value.filter]

        content {
          dynamic "and" {
            for_each = filter.value.and != null ? [filter.value.and] : []

            content {
              object_size_greater_than = and.value.object_size_greater_than
              object_size_less_than    = and.value.object_size_less_than
              prefix                   = and.value.prefix
              tags                     = and.value.tags
            }
          }

          prefix = filter.value.prefix

          dynamic "tag" {
            for_each = filter.value.tag != null ? [filter.value.tag] : []
            content {
              key   = tag.value.key
              value = tag.value.value
            }
          }

          object_size_greater_than = filter.value.object_size_greater_than
          object_size_less_than    = filter.value.object_size_less_than
        }
      }
    }
  }
}


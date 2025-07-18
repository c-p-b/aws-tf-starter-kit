data "aws_iam_policy_document" "ro" {
  count = var.aws_bucket_enabled ? 1 : 0

  statement {
    sid = "ObjectReaderPermissions"

    resources = [
      aws_s3_bucket.this[0].arn,
      "${aws_s3_bucket.this[0].arn}/*",
    ]

    actions = [
      "s3:GetBucket",
      "s3:GetBucketCORS",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:GetObjectAttributes",
      "s3:GetObjectLegalHold",
      "s3:GetObjectRetention",
      "s3:GetObjectTagging",
      "s3:GetObjectTorrent",
      "s3:GetObjectVersion",
      "s3:GetObjectVersionAttributes",
      "s3:GetObjectVersionTagging",
      "s3:GetObjectVersionTorrent",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListBucketVersions",
      "s3:ListBuckets",
      "s3:ListMultipartUploadParts",
      "s3:ListTagsForResource",
    ]
  }
}

data "aws_iam_policy_document" "rw" {
  count = var.aws_bucket_enabled ? 1 : 0

  source_policy_documents = [data.aws_iam_policy_document.ro[0].json]

  statement {
    sid = "ObjectWriterPermissions"

    resources = [
      aws_s3_bucket.this[0].arn,
      "${aws_s3_bucket.this[0].arn}/*",
    ]

    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:DeleteObjectTagging",
      "s3:DeleteObjectVersion",
      "s3:DeleteObjectVersionTagging",
      "s3:PutObject",
      "s3:PutObjectLegalHold",
      "s3:PutObjectRetention",
      "s3:ReplicateObject",
      "s3:ReplicateTags",
      "s3:RestoreObject",
    ]
  }
}

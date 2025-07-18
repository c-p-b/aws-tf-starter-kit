module "label" {
  count = var.aws_ecr_repo_enabled ? 1 : 0

  source = "../aws-label"

  name = var.name
  team = var.team
  tags = var.tags
}

resource "aws_ecr_repository" "this" {
  count = var.aws_ecr_repo_enabled ? 1 : 0

  name = module.label[0].id
  tags = module.label[0].tags

  image_tag_mutability = var.aws_ecr_repo_mutable_tags == false ? "IMMUTABLE" : "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  dynamic "encryption_configuration" {
    for_each = var.aws_ecr_repo_encryption == null ? [] : toset([
      var.aws_ecr_repo_encryption
    ])

    content {
      encryption_type = encryption_configuration.value.type
      kms_key         = encryption_configuration.value.kms_key_arn == null ? "" : encryption_configuration.value.kms_key_arn
    }
  }
}

resource "aws_ecr_repository_policy" "this" {
  count = alltrue([
    var.aws_ecr_repo_enabled,
    var.aws_ecr_repo_policy_json != null,
  ]) ? 1 : 0

  repository = aws_ecr_repository.this[0].name
  policy     = var.aws_ecr_repo_policy_json
}

data "aws_iam_policy_document" "this" {

}

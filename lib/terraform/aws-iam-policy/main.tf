module "label" {
  source = "../aws-label"

  name        = var.name
  environment = var.environment
  team        = var.team
  tags        = var.tags
}

resource "aws_iam_policy" "this" {
  name_prefix = module.label.prefix
  description = var.iam_policy_description
  path        = var.iam_policy_path
  policy      = var.iam_policy_document
  tags        = module.label.tags
}

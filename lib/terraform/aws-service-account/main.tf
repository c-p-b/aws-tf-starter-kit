locals {
  path = "/system/"
}

module "label" {
  source = "../aws-label"

  name = var.name
  team = var.team
  tags = var.tags
}

resource "aws_iam_user" "this" {
  count = var.service_account_enabled ? 1 : 0

  name = module.label.id
  tags = module.label.tags

  path          = local.path
  force_destroy = true
}

resource "aws_iam_access_key" "this" {
  count = var.service_account_enabled ? 1 : 0

  user = aws_iam_user.this[0].name


}

resource "aws_iam_policy" "inline" {
  for_each = var.service_account_enabled == false ? {} : {
    for p in var.service_account_inline_policies : p.key => p.json
  }

  name_prefix = module.label.prefix
  policy      = each.value
  path        = local.path

  description = "IAM policy for ${module.label.id}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_user_policy_attachment" "inline" {
  for_each = var.service_account_enabled == false ? [] : toset([
    for p in var.service_account_inline_policies : p.key
  ])

  user       = aws_iam_user.this[0].name
  policy_arn = aws_iam_policy.inline[each.value].arn
}

resource "aws_iam_user_policy_attachment" "managed" {
  for_each = var.service_account_enabled == false ? {} : {
    for p in var.service_account_managed_policies : split("/", p)[1] => p
  }

  user       = aws_iam_user.this[0].name
  policy_arn = each.value
}

# TODO: add key credentials to secret store
# TODO: support blue-green credential creation and rotation

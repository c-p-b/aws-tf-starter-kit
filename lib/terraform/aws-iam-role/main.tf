locals {

  role_name        = var.use_name_prefix ? null : module.label.id
  role_name_prefix = var.use_name_prefix ? module.label.prefix : null

  iam_policy_arns = toset(distinct(flatten([
    compact(var.iam_role_policy_arns),
    [
      var.iam_role_ssm_policies_enabled == false
      ? []
      : [
        "arn:aws:iam::aws:policy/AmazonSSMFullAccess",
        "arn:aws:iam::aws:policy/AmazonSSMPatchAssociation",
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
      ]
    ],
  ])))
}




module "label" {
  source = "../aws-label"

  name        = var.name
  environment = var.environment
  team        = var.team
  tags        = var.tags
}

resource "aws_iam_role" "this" {
  name               = local.role_name
  name_prefix        = local.role_name_prefix
  assume_role_policy = var.iam_role_trust_policy
  tags               = module.label.tags
  path               = var.iam_role_path

  description = (
    var.iam_role_description != ""
    ? var.iam_role_description
    : "IAM role for ${module.label.id}"
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_policy" "inline" {
  for_each = {
    for p in var.iam_role_policies : p.key => p.json
  }

  name        = local.role_name
  name_prefix = local.role_name_prefix
  policy      = each.value
  path        = var.iam_role_path

  description = "IAM policy for ${module.label.id}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_instance_profile" "this" {
  count = var.iam_role_instance_profile_enabled == true ? 1 : 0

  name        = local.role_name
  name_prefix = local.role_name_prefix
  path        = var.iam_role_path
  role        = aws_iam_role.this.name
  tags        = module.label.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "inline" {
  for_each = toset([
    for p in var.iam_role_policies : p.key
  ])

  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.inline[each.value].arn
}

resource "aws_iam_role_policy_attachment" "external" {
  for_each = {
    for p in local.iam_policy_arns : split("/", p)[1] => p
  }

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

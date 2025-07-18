locals {
  delimiter = "-"

  id = join(
    local.delimiter,
    compact(
      var.environment != null
      ? [var.name, var.environment]
      : [var.name]
    ),
  )

  tags = merge(
    {
      "Name"        = local.id
      "id"          = local.id
      "environment" = var.environment
      "team"        = var.team
      "terraformed" = true
    },
    {
      for k, v in var.tags : format("%s", k) => v
    }
  )
}


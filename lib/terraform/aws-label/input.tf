variable "name" {
  type        = string
  description = "Project name, e.g. `my-app-foo`"

  validation {
    condition     = length(var.name) >= 3
    error_message = "Must contain at least three characters."
  }
}

variable "ou" {
  type        = string
  description = "The organization unit that the resource belongs to"

  default = "default-ou-name"

  validation {
    condition     = var.ou == "default-ou-name"
    error_message = "Must be one of [default-ou-name]."
  }
}


variable "team" {
  type        = string
  description = "The identifier of the team that owns the resource or application"

  validation {
    condition     = length(var.team) >= 3
    error_message = "Must contain at least three characters."
  }

  validation {
    condition     = length(var.team) >= 1
    error_message = "Must be a non-empty string."
  }
}

variable "tags" {
  type        = map(any)
  default     = {}
  description = "Map of additional tags, eg. `map(foo = Bar)`"

  validation {
    condition     = can([for k, _ in var.tags : k == lower(k)])
    error_message = "Key names must not contain capital letters."
  }

  validation {
    condition     = can([for k, _ in var.tags : k != "Name"])
    error_message = "Key name `Name` is reserved."
  }

  validation {
    condition     = can([for k, _ in var.tags : k != "name"])
    error_message = "Key name `name` is reserved."
  }

  validation {
    condition     = can([for k, _ in var.tags : k != "environment"])
    error_message = "Key name `environment` is reserved."
  }

  validation {
    condition     = can([for k, _ in var.tags : k != "team"])
    error_message = "Key name `team` is reserved."
  }

  validation {
    condition     = can([for k, _ in var.tags : k != "terraformed"])
    error_message = "Key name `terraformed` is reserved."
  }

  validation {
    condition     = can([for k, _ in var.tags : k != "source"])
    error_message = "Key name `source` is reserved."
  }
}

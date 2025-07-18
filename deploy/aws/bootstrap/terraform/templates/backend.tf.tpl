terraform {
  backend "s3" {
    bucket         = "${bucket}"
    key            = "CHANGE_ME/terraform.tfstate"
    region         = "${region}"
    dynamodb_table = "${dynamodb_table}"
    encrypt        = true
  }
}
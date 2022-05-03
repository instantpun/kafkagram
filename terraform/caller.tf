data "aws_caller_identity" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "caller_arn" {
  value = data.aws_caller_identity.current.arn
}

output "caller_user" {
  value = data.aws_caller_identity.current.user_id
}

output "aws_access" {
  value = var.tfadmin_aws_access_key
}

output "aws_secret" {
  value = var.tfadmin_aws_secret_key
}
variable "AWS_REGION" {
  default = "us-west-2"
}

variable "tfadmin_aws_access_key" {
  default = ""
  type = string
}

variable "tfadmin_aws_secret_key" {
  default = ""
  type = string
}

variable "source_repo_name" {
  default = ""
  type = string
}
 
variable "source_repo_url" {
  default = ""
  type = string
}

variable "source_commit" {
  default = ""
  type = string
}
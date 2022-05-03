provider "aws" {
  access_key = var.tfadmin_aws_access_key
  secret_key = var.tfadmin_aws_secret_key
  region     = var.AWS_REGION
  default_tags {
    tags = {
      Environment = "Test"
      Owner       = "Aaron Robinett"
      Project     = "MSK Lab"
      plan_uuid   = "6ff206cc-1c33-4349-b674-a27a974978b3"
    }
  }
}


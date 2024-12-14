terraform {
    required_providers {
     aws = {
       source = "hashicorp/aws"
       version = "~>5.0"
    }
  }
# backend "s3" {
#     bucket         = "myorg-terraform-states"
#     key            = "expense_dev_bastion"
#     region         = "us-east-1"
#     dynamodb_table = "TableName"
#   }

}

provider "aws" {
    region = "us-east-1"
}


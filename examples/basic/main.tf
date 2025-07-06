terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-west-1"
}

module "anomalo_eventbridge" {
  source              = "git::https://github.com/joewimmer/terraform-aws-anomalo-eventbridge.git"
}

output "api_endpoint" {
  value       = module.anomalo_eventbridge.api_endpoint
  description = "The endpoint URL of the Anomalo HTTP API"
}

output "api_key" {
  value = module.anomalo_eventbridge.anomalo_api_key
}
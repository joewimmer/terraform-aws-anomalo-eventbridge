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

module "anomalo_eventbridge_base" {
  source              = "git::https://github.com/joewimmer/terraform-aws-anomalo-eventbridge.git"
  eventbridge_api_key = var.eventbridge_api_key
}

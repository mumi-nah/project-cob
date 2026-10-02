terraform {
  required_version = ">= 0.12"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "af-south-1"
}

module "cob-network" {
  source = "../../modules/cob_network"
}

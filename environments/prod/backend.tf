# environments/dev/backend.tf
terraform {
  backend "s3" {
    bucket       = "cob-terraform-state-prod"
    key          = "project-cob/vpc-prod/terraform.tfstate"
    region       = "af-south-1"
    use_lockfile = true  
  }
}
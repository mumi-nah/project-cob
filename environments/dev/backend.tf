terraform {
  backend "s3" {
    bucket          = "terraform-states-af-south"
    key             = "project-cob/vpc-dev/terraform.tfstate"
    region          = "af-south-1"
    use_lockfile    = true
    use_path_style  = true
  }
}
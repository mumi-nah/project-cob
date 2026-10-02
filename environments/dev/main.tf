terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 6.0"
        }
    }
}

provider aws {
    region = "af-south-1"
}


module "cob_network" {
  source = "../../modules/cob_network"

  project_name          = "test-cob-network"
  environment           = "dev"
  vpc_cidr              = "10.0.0.0/16"
  availability_zones    = ["af-south-1a", "af-south-1b"]
  public_subnet_cidrs   = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnet_cidrs  = ["10.0.10.0/24", "10.0.11.0/24"]
  enable_nat_gateway    = true
  single_nat_gateway    = true  
}

module "iam_instance" {
  source = "../../modules/iam"

  environment          = "dev"
  role_purpose         = "ec2-test"
  trusted_service      = "ec2.amazonaws.com"
  policy_statements    = []
}

module "ec2_test" {
  source = "../../modules/compute"

  environment      = "dev"
  instance_purpose = "test"
  vpc_id           = module.cob_network.vpc_id
  subnet_id        = module.cob_network.private_subnet_ids[0]
}

module "database_test" {
  source = "../../modules/databases"

  environment         = "dev"
  db_purpose          = "test"
  vpc_id              = module.cob_network.vpc_id
  private_subnet_ids  = module.cob_network.private_subnet_ids

  engine          = "postgres"
  engine_version  = "16.3"
  instance_class  = "db.t3.micro"
  multi_az        = false
  skip_final_snapshot = true
}  

module "storage_source" {
  source = "../../modules/storage"

  environment    = "dev"
  bucket_purpose = "source-data"
}

module "storage_results" {
  source = "../../modules/storage"

  environment    = "dev"
  bucket_purpose = "athena-results"
}

module "iam_glue_crawler" {
  source              = "../../modules/iam"
  environment         = "dev"
  role_purpose        = "glue-crawler"
  trusted_service     = "glue.amazonaws.com"
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"]

  policy_statements = [
    {
      sid       = "ReadSourceData"
      actions   = ["s3:GetObject", "s3:ListBucket"]
      resources = [module.storage_source.bucket_arn, "${module.storage_source.bucket_arn}/*"]
    }
  ]
}

module "data_platform_test" {
  source = "../../modules/data_platform"

  environment            = "dev"
  data_platform_purpose  = "test"
  s3_data_location       = "s3://${module.storage_source.bucket_name}/raw/"
  crawler_role_arn       = module.iam_glue_crawler.role_arn
  athena_results_s3_uri  = "s3://${module.storage_results.bucket_name}/athena-results/"
}
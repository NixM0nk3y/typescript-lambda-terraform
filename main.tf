provider "aws" {
  region = local.aws_region
  default_tags {
    tags = {
      Tenant      = var.tenant
      Product     = var.product
      Environment = local.environment
    }
  }
}

locals {
  envs = {
    "dev"     = "dev"
    "prod"    = "prod"
    "default" = "dev"

  }
  environment = local.envs[terraform.workspace]

  aws_regions = {
    "prod"    = var.default_region
    "dev"     = var.default_region
    "default" = var.default_region
  }

  aws_region = local.aws_regions[local.environment]
}

# setup our namespacing
module "this" {
  source = "./vendor/modules/terraform-null-label"

  namespace   = var.tenant
  environment = local.environment
  name        = var.product
  attributes  = []
  delimiter   = "-"

  label_order = ["namespace", "name", "environment", "attributes"]

  labels_as_tags = []
}

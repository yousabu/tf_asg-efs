provider "aws" {
  region = "us-east-1"
}

data "aws_availability_zones" "available" {}

locals {
  name   = "fw-efs-${var.env_prefix}"
  region = "us-east-1"
  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
  tags = {
    Example    = local.name
  }
}

## vpc ##
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 4.0"
  name = local.name
  cidr = local.vpc_cidr
  azs             = local.azs
  public_subnets  = var.public_subnets_cidr_blocks
  enable_dns_hostnames = true
  tags = local.tags
  enable_dhcp_options = true
}

### security group ##
resource "aws_security_group" "shared" {
  name_prefix = "${local.name}-shared"
  vpc_id      = module.vpc.vpc_id
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "fw-efs-sg" 
  }
}

## EFS ##
module "efs" {
  source = "./efs"
  sunbets_nums = module.vpc.public_subnets
  performance_mode = "generalPurpose"
  throughput_mode = "bursting"
  security_groups = [aws_security_group.shared.id]
  }

## Auto Scaling Group ##
module "asg" {
  source = "./asg"
  asg_name = "test"
  env_prefix = var.env_prefix
  ami_image = var.ami_image
  security_groups = [aws_security_group.shared.id]
  instance_type = var.instance_type
  key_name = "abuhamda"
  efs_dns_name = module.efs.value
  max_size = 2
  min_size = 1
  desired_capacity = 1
  sunbets_nums = module.vpc.public_subnets
  depends_on = [ module.efs , module.vpc ]
}

## Backup ##
resource "aws_backup_plan" "backup_asg" {
  name = "${var.env_prefix}backup_plan"
  rule {
    rule_name         = "${var.env_prefix}_backup_rule"
    target_vault_name = "${var.env_prefix}fw"
    schedule          = "cron(0 12 * * ? *)"
    lifecycle {
      delete_after = 14
    }
  }
  advanced_backup_setting {
    backup_options = {
      WindowsVSS = "enabled"
    }
    resource_type = "EC2"
  }
}
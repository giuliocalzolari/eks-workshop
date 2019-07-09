terraform {
  required_version = ">= 0.12.3"
  required_providers {
    aws        = ">= 2.18.0"
    kubernetes = ">= v1.8.0"
  }
}

provider "aws" {
  region = "${var.region}"
}



data "aws_availability_zones" "available" {}

locals {
  cluster_name = "gc-eks"
}

resource "aws_security_group" "all_worker_mgmt" {
  name_prefix = "all_worker_management"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
      "88.217.255.228/32",
    ]
  }
}



module "vpc" {
  source         = "terraform-aws-modules/vpc/aws"
  version        = "2.7.0"
  name           = "eks-vpc"
  cidr           = "10.0.0.0/16"
  azs            = data.aws_availability_zones.available.names
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

  tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "dev"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "dev"
  }
}



# resource "aws_cloudwatch_log_group" "cwlog" {
#   name = "/aws/eks/${local.cluster_name}/cluster"
# }


module "eks-cluster" {
  source                    = "terraform-aws-modules/eks/aws"
  version                   = "5.0.0"
  write_kubeconfig          = true
  write_aws_auth_config     = false
  cluster_name              = local.cluster_name
  subnets                   = module.vpc.public_subnets
  vpc_id                    = module.vpc.vpc_id
  cluster_enabled_log_types = ["api", "authenticator", "controllerManager", "scheduler"]


  worker_groups = [
    {
      instance_type        = "t3.small"
      asg_max_size         = 3
      asg_desired_capacity = 3
      public_ip            = true
      ebs_optimized        = false
    }
  ]

  tags = {
    environment = "gc"
  }

  worker_security_group_id = aws_security_group.all_worker_mgmt.id
  map_accounts             = var.map_accounts
}


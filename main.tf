terraform {
  required_version = ">= 0.11.8"
}

provider "aws" {
  version = ">= 2.6.0"
  region  = "${var.region}"
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
  version        = "1.60.0"
  name           = "eks-vpc"
  cidr           = "10.0.0.0/16"
  azs            = ["${data.aws_availability_zones.available.names}"]
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

  tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }
}

resource "aws_cloudwatch_log_group" "cwlog" {
  name = "/aws/eks/${local.cluster_name}/cluster"
}

module "eks-cluster" {
  source                                   = "terraform-aws-modules/eks/aws"
  config_output_path                       = "kubeconfig/"
  write_aws_auth_config                    = false
  cluster_name                             = "${local.cluster_name}"
  subnets                                  = ["${module.vpc.public_subnets}"]
  vpc_id                                   = "${module.vpc.vpc_id}"
  cluster_enabled_log_types                = ["api", "authenticator", "controllerManager", "scheduler"]
  worker_group_count                       = 0
  worker_group_launch_template_mixed_count = 1

  worker_groups_launch_template_mixed = [
    {
      name                 = "minion-1"
      instance_type        = "t2.small"
      asg_max_size         = 3
      asg_desired_capacity = 3
      public_ip            = true
      ebs_optimized        = false
    },
  ]

  tags = {
    environment = "gc"
  }

  worker_additional_security_group_ids = ["${aws_security_group.all_worker_mgmt.id}"]
  map_accounts                         = "${var.map_accounts}"
  map_accounts_count                   = "${var.map_accounts_count}"
}

data "aws_eks_cluster_auth" "auth" {
  name = "${local.cluster_name}"
}

provider "kubernetes" {
  host                   = "${module.eks-cluster.cluster_endpoint}"
  cluster_ca_certificate = "${base64decode(module.eks-cluster.cluster_certificate_authority_data)}"
  token                  = "${data.aws_eks_cluster_auth.auth.token}"
}

resource "kubernetes_storage_class" "io1" {
  metadata {
    name = "io1"
  }

  storage_provisioner = "kubernetes.io/aws-ebs"
  reclaim_policy      = "Retain"

  parameters = {
    type   = "io1"
    fsType = "ext4"
  }
}


resource "kubernetes_namespace" "ns_dev" {
  metadata {
    annotations = {
      name = "dev"
    }

    labels = {
      mylabel = "dev"
    }

    name = "dev"
  }
}

module "guestbook-dev" {
  source    = "./apps/guestbook"
  namespace = "dev"
  stage     = "dev"

}



resource "kubernetes_namespace" "ns_prod" {
  metadata {
    annotations = {
      name = "prod"
    }

    labels = {
      mylabel = "prod"
    }

    name = "prod"
  }
}

module "guestbook-prod" {
  source    = "./apps/guestbook"
  namespace = "prod"
  stage     = "prod"

}
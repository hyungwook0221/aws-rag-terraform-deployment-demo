terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "5.61.0"
        }
        random = {
            source  = "hashicorp/random"
            version = "3.1.0"
        }
    }
}

provider "aws" {
    region = var.region 
}


resource "random_string" "demo_suffix" {
  length  = 8
  upper   = false
  number = true
  special = false
}

resource "random_password" "password" {
  length      = 16
  special     = false
  min_numeric = 1
  min_special = 1
  min_upper   = 1
}

data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.demo.name
}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.demo.name
}

# Configure the Kubernetes provider
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  token                  = data.aws_eks_cluster_auth.cluster.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
}

# Configure the Helm provider
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    token                  = data.aws_eks_cluster_auth.cluster.token
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  }
}
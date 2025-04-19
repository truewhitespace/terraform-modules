variable "vpc_id" {}
variable "subnets" {}
variable "cluster_security_group_id" {}
variable "cluster_name" {}
variable "environment" {}
variable "external_access_cidr" {}
variable "access_entries" {}
variable "instance_type" {default="t3.2xlarge"}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }
  # Extend node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
  }
  cluster_endpoint_public_access       = true
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access_cidrs = [var.external_access_cidr]

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  vpc_id                   = var.vpc_id
  subnet_ids               = var.subnets
  control_plane_subnet_ids = var.subnets

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
    block_device_mappings = {
      xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 1000
            volume_type           = "gp3"
            iops                  = 3000
            #throughput            = 150
            #encrypted             = true
            delete_on_termination = true
          }
        }
      }
    }

  eks_managed_node_groups = {
    cluster = {
      min_size     = 3
      max_size     = 10
      desired_size = 3

      instance_types = [var.instance_type]
      capacity_type  = "SPOT"
      block_device_mappings = {
        xvda = {
            device_name = "/dev/xvda"
            ebs = {
              volume_size           = 1000
              volume_type           = "gp3"
              iops                  = 3000
              #throughput            = 150
              #encrypted             = true
              delete_on_termination = true
            }
          }
        }
      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }
    }
  }

  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true

  access_entries = var.access_entries

  tags = {
    Environment = var.environment
    Repo = "truewhitespace/terraform-modules"
    Terraform   = "true"
  }
}

output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "oidc_provider_arn" {
    value = module.eks.oidc_provider_arn
}

output "cluster_id" {
    value = module.eks.cluster_id
}

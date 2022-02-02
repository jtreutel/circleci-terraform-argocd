module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.11.5"

  name = "${var.resource_prefix}-vpc"
  cidr = "10.0.0.0/16"

  azs = [
    "${var.region}a",
    "${var.region}b",
    "${var.region}c"
  ]
  private_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]
  public_subnets = [
    "10.0.101.0/24",
    "10.0.102.0/24",
    "10.0.103.0/24"
  ]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.2.4"

  cluster_name                    = "${var.resource_prefix}-eks"
  cluster_version                 = "1.21"
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = concat(module.vpc.public_subnets, module.vpc.private_subnets)


  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  cluster_encryption_config = [{
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }]

  eks_managed_node_group_defaults = {
    ami_type               = "AL2_x86_64"
    vpc_security_group_ids = [aws_security_group.k8s_nodes.id]
  }

  eks_managed_node_groups = {
    "${var.resource_prefix}" = {
      min_size     = 3
      max_size     = 10
      desired_size = 3

      disk_size = 100

      key_name = module.ssh_key.key_name

      instance_types = ["m5.xlarge"]
      labels = {
        Environment = "demo"
      }
      taints = {}
      tags = {
        Owner = "jennings"
      }
    }
  }

  tags = {
    Environment = "demo"
    Terraform   = "true"
  }
}


resource "aws_kms_key" "eks" {

  description             = "For encrypting EKS secrets used by ${var.resource_prefix}."
  deletion_window_in_days = 14

  tags = {
    Name = "${var.resource_prefix}-kms-key"
  }
}



resource "aws_security_group" "k8s_nodes" {
  name        = "${var.resource_prefix}-k8s-nodes-sg"
  description = "SG for ${var.resource_prefix} k8s nodes"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "${var.resource_prefix}-k8s-nodes-sg"
  }
}
resource "aws_security_group_rule" "allow_ssh" {
  type              = "ingress"
  to_port           = 22
  from_port         = 22
  protocol          = "tcp"
  cidr_blocks       = ["183.76.172.112/32"]
  security_group_id = aws_security_group.k8s_nodes.id
}
resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  to_port           = 0
  from_port         = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.k8s_nodes.id
}



# Make an SSH key for debugging purposes
module "ssh_key" {
  source   = "git::https://github.com/jtreutel/terraform-ec2-keypair.git"
  key_name = "${var.resource_prefix}-k8s-nodes-key-${random_string.key_suffix.result}"
}
resource "local_file" "ssh_key_private" {
  content         = module.ssh_key.private_key
  filename        = "${path.root}/sshkeys/ssh_key.pem"
  file_permission = "0600"
}
resource "local_file" "ssh_key_public" {
  content  = module.ssh_key.public_key
  filename = "${path.root}/sshkeys/ssh_key.pub"
}
resource "random_string" "key_suffix" {
  length  = 8
  special = false
}


#Generate kubeconfig file
resource "local_file" "kubeconfig" {
  filename = "${path.module}/kubeconfig"
  content = templatefile(
    "${path.module}/templates/kubeconfig.tpl",
    {
      cluster_name     = module.eks.cluster_id,
      cluster_endpoint = module.eks.cluster_endpoint,
      ca_data          = module.eks.cluster_certificate_authority_data,
      region           = var.region,
      aws_profile      = var.profile
    }
  )
}

#output "kubeconfig" {
#  value = "${local.kubeconfig}"
#}
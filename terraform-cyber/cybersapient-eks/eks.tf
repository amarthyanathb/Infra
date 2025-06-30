
provider "aws" {
  region = var.aws_region
}

provider "kubernetes" {
  host                   = module.cybersapient-eks-cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(module.cybersapient-eks-cluster.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.default.token
}

data "aws_eks_cluster_auth" "default" {
  name = module.cybersapient-eks-cluster.cluster_name
}

data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}

module "cybersapient-eks-cluster" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.23.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  # Cluster endpoint access is set to public and private.
  # In this config, the cluster endpoint is accessible from outside of the VPC. Worker node traffic to the endpoint will stay within the VPC.
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = flatten([module.vpc.private_subnets, module.vpc.public_subnets])

  enable_irsa = "true"
  # EKS Addons
  cluster_addons = {
    # Enable EBS CSI Driver by default
    aws-ebs-csi-driver = {
      service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
    }
  }
  enable_cluster_creator_admin_permissions = true
  eks_managed_node_group_defaults = {
    disk_size = 20
    disk_type = "gp3"
  }

  eks_managed_node_groups = {
    cybersapient_spot_nodes = {
      name           = "spot-node-group"
      instance_types = ["${var.node_type}"]
      ami_type       = "AL2_x86_64"
      capacity_type  = "SPOT"


      min_size     = 1
      max_size     = 1
      desired_size = 1

      disk_size = 20
      disk_type = "gp3"

      labels = {
        Environment = "development"
        NodeType    = "spot"
        Project     = "cybersapient"
      }
      subnet_ids = module.vpc.private_subnets
    }

    cybersapient_ondemand_nodes = {
      name           = "ondemand-node-group"
      instance_types = ["${var.node_type}"]
      ami_type       = "AL2_x86_64"
      capacity_type  = "ON_DEMAND"

      min_size     = 1
      max_size     = 1
      desired_size = 1

      disk_size = 20
      disk_type = "gp3"

      labels = {
        Environment = "development"
        NodeType    = "on-demand"
        Project     = "cybersapient"
      }

      subnet_ids = module.vpc.private_subnets
    }
  }
}

data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

module "irsa-ebs-csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.39.0"

  create_role                   = true
  role_name                     = "CyberSapientEKSEBSCSIRole-${module.cybersapient-eks-cluster.cluster_name}"
  provider_url                  = module.cybersapient-eks-cluster.oidc_provider
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}

module "aws-auth" {
  source  = "terraform-aws-modules/eks/aws//modules/aws-auth"
  version = "~> 20.0"

  manage_aws_auth_configmap = true

  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/cybersapient-admin"
      username = "cybersapient-admin"
      groups   = ["system:masters"]
    },
  ]
  depends_on = [module.cybersapient-eks-cluster, module.irsa-ebs-csi]
}

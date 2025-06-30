# Network configuration for CyberSapient EKS cluster
# Optimized for cost efficiency with single NAT gateway

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.1"

  name            = var.vpc_name
  cidr            = var.vpc_cidr
  azs             = var.vpc_network_azs
  private_subnets = var.private_subnet_cidr
  public_subnets  = var.public_subnet_cidr

  enable_nat_gateway                   = true
  single_nat_gateway                   = true
  enable_dns_hostnames                 = true
  enable_dns_support                   = true
  enable_flow_log                      = false
  create_flow_log_cloudwatch_iam_role  = false
  create_flow_log_cloudwatch_log_group = false

  nat_gateway_tags = {
    Name        = "${var.vpc_name}-nat-gw"
    Project     = "cybersapient"
    Environment = "development"
  }

  igw_tags = {
    Name        = "${var.vpc_name}-igw"
    Project     = "cybersapient"
    Environment = "development"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = 1
    Project                                     = "cybersapient"
    Environment                                 = "development"
    SubnetType                                  = "public"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = 1
    Project                                     = "cybersapient"
    Environment                                 = "development"
    SubnetType                                  = "private"
  }

  tags = {
    Terraform   = "true"
    Environment = "cybersapient-development"
    Project     = "cybersapient"
    ManagedBy   = "terraform"
    CostCenter  = "development"
    Owner       = "cybersapient-team"
  }
}

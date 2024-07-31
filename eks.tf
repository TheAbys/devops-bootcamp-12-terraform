module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.15.0"

  cluster_name = "myapp-eks-cluster"
  cluster_version = "1.27"

  subnet_ids = module.myapp-vpc.private_subnets
  vpc_id = module.myapp-vpc.vpc_id

  create_iam_role = false

  tags = {
    environment = "development"
    application = "myapp"
  }

  eks_managed_node_groups = {
    dev = {
        min_size = 1
        max_size = 3
        desired_size = 3

        instance_type = ["t2.small"]
    }
  }
}


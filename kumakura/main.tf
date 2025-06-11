module "kumakura" {
  source = "../../modules"
    env  = "iac"
    name = "kumakura"

    vpc_cidr = "10.0.0.0/16"
    pri_subnet_count = "3"

    desired_size = "3"
    max_size = "3"
    min_size = "1"
    eks_ami_type = "AL2_x86_64"
    eks_instance_types = "t3.large"
}
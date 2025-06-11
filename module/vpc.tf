#使用したいAWSリージョンを指定
provider "aws" {
  region = "ap-northeast-1"
}

# アベイラビリティゾーンのデータソースを宣言
data "aws_availability_zones" "available" {
  state = "available"
}

#VPCを作成
resource "aws_vpc" "vpc_iac_terraform" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_support   = true #VPC内でDNS解決をサポート（エンドポイント用）
  enable_dns_hostnames = true #VPC内のパブリックDNSホスト名の割り当て有効（エンドポイント用）

  tags = {
    Name = "vpc_${var.env}_${var.name}_terraform"
  }
}

#サブネットを作成（パブリック）
resource "aws_subnet" "pub_subnet_iac_terraform" {
  vpc_id            = aws_vpc.vpc_iac_terraform.id
  cidr_block        = cidrsubnet(aws_vpc.vpc_iac_terraform.cidr_block, 8, 0)
  availability_zone = element(data.aws_availability_zones.available.names, 0)
  map_public_ip_on_launch = true  # パブリックIPの自動割り当てを有効にする

  tags = {
    Name = "pub_subnet_${var.env}_${var.name}_ terraform"
  }
}

#サブネットを作成（プライベート）
resource "aws_subnet" "pri_subnet_iac_terraform" {
  count             = "${var.pri_subnet_count}"
  vpc_id            = aws_vpc.vpc_iac_terraform.id
  cidr_block        = cidrsubnet(aws_vpc.vpc_iac_terraform.cidr_block, 8, count.index + 1)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = false  #プライベートサブネットなので無効

  tags = {
    Name = "pri_subnet_${var.env}_${var.name}_terraform_${count.index}"
  }
}

#インターネットゲートウェイを作成
resource "aws_internet_gateway" "igw_iac_terraform" {
  vpc_id = aws_vpc.vpc_iac_terraform.id

  tags = {
    Name = "igw_${var.env}_${var.name}_terraform"
  }
}

#NAT用固定IP作成
resource "aws_eip" "nat_eip_iac_terraform" {
  domain = "vpc"

  tags = {
    Name = "nat_eip_${var.env}_${var.name}_terraform"
  }
}

#NATゲートウェイを作成
resource "aws_nat_gateway" "ngw_iac_terraform" {
  allocation_id = aws_eip.nat_eip_iac_terraform.id
  subnet_id     = aws_subnet.pub_subnet_iac_terraform.id

  tags = {
    Name = "ngw_${var.env}_${var.name}_terraform"
  }
}

#ルートテーブルを作成（パブリック）
resource "aws_route_table" "pub_rt_iac_terraform" {
  vpc_id = aws_vpc.vpc_iac_terraform.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_iac_terraform.id
  }

  tags = {
    Name = "pub_rt_${var.env}_${var.name}_terraform"
  }
}

resource "aws_route_table_association" "pub_subnet_association_iac" {
  subnet_id      = aws_subnet.pub_subnet_iac_terraform.id
  route_table_id = aws_route_table.pub_rt_iac_terraform.id
}

#ルートテーブルを作成（プライベート）
resource "aws_route_table" "pri_rt_iac_terraform" {
  vpc_id = aws_vpc.vpc_iac_terraform.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw_iac_terraform.id
  }

  tags = {
    Name = "pri_rt_${var.env}_${var.name}_terraform"
  }
}

resource "aws_route_table_association" "pri_subnet_association_iac" {
  count          = length(aws_subnet.pri_subnet_iac_terraform)
  subnet_id      = aws_subnet.pri_subnet_iac_terraform[count.index].id
  route_table_id = aws_route_table.pri_rt_iac_terraform.id
}

#セキュリティグループを作成(EKS)
resource "aws_security_group" "eks_sg_iac_terraform" {
  vpc_id = aws_vpc.vpc_iac_terraform.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks_sg_${var.env}_${var.name}_terraform"
  }
}

#セキュリティグループを作成(EC2)
resource "aws_security_group" "ec2_sg_iac_terraform" {
  vpc_id = aws_vpc.vpc_iac_terraform.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2_sg_${var.env}_${var.name}_terraform"
  }
}

#セキュリティグループを作成(VPCエンドポイント)
resource "aws_security_group" "end_sg_iac_terraform" {
  vpc_id = aws_vpc.vpc_iac_terraform.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "end_sg_${var.env}_${var.name}_terraform"
  }
}

#VPCエンドポイントを作成（X-Ray）
resource "aws_vpc_endpoint" "end_xray_iac_terraform" {
  vpc_id            = aws_vpc.vpc_iac_terraform.id
  service_name      = "com.amazonaws.ap-northeast-1.xray"
  vpc_endpoint_type = "Interface"
  subnet_ids        = aws_subnet.pri_subnet_iac_terraform[*].id
  security_group_ids = [aws_security_group.end_sg_iac_terraform.id]

  private_dns_enabled = true

  tags = {
    Name = "end_xray_${var.env}_${var.name}_terraform"
  }
}

#VPCエンドポイントを作成（CloudWatchLogs）
resource "aws_vpc_endpoint" "end_cw_iac_terraform" {
  vpc_id            = aws_vpc.vpc_iac_terraform.id
  service_name      = "com.amazonaws.ap-northeast-1.logs"
  vpc_endpoint_type = "Interface"
  subnet_ids        = aws_subnet.pri_subnet_iac_terraform[*].id
  security_group_ids = [aws_security_group.end_sg_iac_terraform.id]

  private_dns_enabled = true

  tags = {
    Name = "end_cw_${var.env}_${var.name}_terraform"
  }
}

#VPCエンドポイントを作成（ECR_API）
resource "aws_vpc_endpoint" "end_ecr_api_iac_terraform" {
  vpc_id            = aws_vpc.vpc_iac_terraform.id
  service_name      = "com.amazonaws.ap-northeast-1.ecr.api"
  vpc_endpoint_type = "Interface"
  subnet_ids        = aws_subnet.pri_subnet_iac_terraform[*].id
  security_group_ids = [aws_security_group.end_sg_iac_terraform.id]

  private_dns_enabled = true

  tags = {
    Name = "end_ecr_api_${var.env}_${var.name}_terraform"
  }
}

#VPCエンドポイントを作成（ECR_DKR）
resource "aws_vpc_endpoint" "end_ecr_dkr_iac_terraform" {
  vpc_id            = aws_vpc.vpc_iac_terraform.id
  service_name      = "com.amazonaws.ap-northeast-1.ecr.dkr"
  vpc_endpoint_type = "Interface"
  subnet_ids        = aws_subnet.pri_subnet_iac_terraform[*].id
  security_group_ids = [aws_security_group.end_sg_iac_terraform.id]

  private_dns_enabled = true

  tags = {
    Name = "end_ecr_dkr_${var.env}_${var.name}_terraform"
  }
}

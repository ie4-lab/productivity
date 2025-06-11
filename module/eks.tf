#EKSクラスター作成
resource "aws_eks_cluster" "eks_iac_terraform" {
  name     = "eks_${var.env}_${var.name}_terraform"
  role_arn = aws_iam_role.eks_cluster_role_iac_terraform.arn
  version  = "1.31" #Kubernetesバージョン指定

  # ネットワーキング設定
  vpc_config {
    subnet_ids = aws_subnet.pri_subnet_iac_terraform[*].id
    endpoint_public_access = true
    endpoint_private_access = true
  }

  # コントロールのログ記録
  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  depends_on = [aws_iam_role_policy_attachment.eks_policy]
}

#アドオン設定
#resource "aws_eks_addon" "addon_coredns_iac" {
#  cluster_name = aws_eks_cluster.eks_iac_terraform.name
#  addon_name   = "coredns"
#  addon_version = "v1.11.4-eksbuild.2"
#}

#resource "aws_eks_addon" "addon_kube-proxy_iac" {
#  cluster_name = aws_eks_cluster.eks_iac_terraform.name
#  addon_name   = "kube-proxy"
#  addon_version = "v1.31.3-eksbuild.2"
#}

#resource "aws_eks_addon" "addon_vpc-cni_iac" {
#  cluster_name = aws_eks_cluster.eks_iac_terraform.name
#  addon_name   = "vpc-cni"
#  addon_version = "v1.19.2-eksbuild.1"
#}

#resource "aws_eks_addon" "addon_amazon-cloudwatch-observability_iac" {
#  cluster_name = aws_eks_cluster.eks_iac_terraform.name
#  addon_name   = "amazon-cloudwatch-observability"
#  addon_version = "v3.0.0-eksbuild.1"
#}

#resource "aws_eks_addon" "addon_eks-pod-identity-agent_iac" {
#  cluster_name = aws_eks_cluster.eks_iac_terraform.name
#  addon_name   = "eks-pod-identity-agent"
#  addon_version = "v1.3.4-eksbuild.1"
#}

#resource "aws_eks_addon" "addon_adot_iac" {
#  cluster_name = aws_eks_cluster.eks_iac_terraform.name
#  addon_name   = "adot"
#  addon_version = "v0.109.0-eksbuild.2"
#  depends_on = [ 
#    helm_release.cert_manager
#  ]
#}

#EKSノードグループ作成
resource "aws_eks_node_group" "eks_nodes" {
  cluster_name    = aws_eks_cluster.eks_iac_terraform.name
  node_group_name = "node_group_${var.env}_${var.name}_Terraform"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_subnet.pri_subnet_iac_terraform[*].id

  #スケーリング設定
  scaling_config {
    desired_size = "${var.desired_size}"
    max_size     = "${var.max_size}"
    min_size     = "${var.min_size}"
  }

  ami_type     = "${var.eks_ami_type}"  # Amazon Linux 2を使用
  instance_types = ["${var.eks_instance_types}"]

  tags = {
    Name = "eks_nodes_${var.env}_${var.name}_Terraform"
  }
}

# EKSクラスターの作成（既存のコード）
#data "aws_eks_cluster" "eks" {
#  name = aws_eks_cluster.eks_iac_terraform.name
#}

#data "aws_eks_cluster_auth" "eks" {
#  name = aws_eks_cluster.eks_iac_terraform.name
#}

#provider "kubernetes" {
#  host                   = data.aws_eks_cluster.eks.endpoint
#  token                  = data.aws_eks_cluster_auth.eks.token
#  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority.0.data)
#}

#provider "helm" {
#  kubernetes {
#    host                   = data.aws_eks_cluster.eks.endpoint
#    token                  = data.aws_eks_cluster_auth.eks.token
#    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority.0.data)
#  }
#}

#resource "helm_release" "cert_manager" {
#  name       = "cert-manager"
#  repository = "https://charts.jetstack.io"
#  chart      = "cert-manager"
#  namespace  = "cert-manager"
#
#  create_namespace = true
#
#  set {
#    name  = "installCRDs"
#    value = "true"
#  }
#
#  depends_on = [aws_eks_cluster.eks_iac_terraform]
#}

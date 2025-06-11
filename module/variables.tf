#共通の環境変数
variable "env" {
  description = "環境名"
  type        = string
}

variable "name" {
  description = "ユーザー名"
  type        = string
}

#VPC用
variable "vpc_cidr" {
  description = "VPC用CIDR"
  type        = string
}

variable "pri_subnet_count" {
  description = "プライベートサブネット数"
  type        = string
}

#EKS用
variable "desired_size" {
  description = "EKS用希望ノード数"
  type        = string
}

variable "max_size" {
  description = "EKS用最大ノード数"
  type        = string
}

variable "min_size" {
  description = "EKS用最小ノード数"
  type        = string
}

variable "eks_ami_type" {
  description = "EKS用ami"
  type        = string
}

variable "eks_instance_types" {
  description = "EKS用インスタンスタイプ"
  type        = string
}


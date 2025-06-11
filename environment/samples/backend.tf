terraform {
  backend "s3" {
    bucket = "2024-s3-iac-terraform"
    key    = "backend/name/terraform.tfstate"
    region = "ap-northeast-1"
  }
}

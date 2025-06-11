terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.80.0"         ## プロバイダーのバージョン
    }
  }
  required_version = "1.10.3"       ## Terraformのバージョン
}

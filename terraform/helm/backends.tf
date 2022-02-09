terraform {
  backend "s3" {
    bucket         = "jennings-demo-terraform-state"
    key            = "k8sargocd/testing-helm/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "jennings-terraform-state-locking"
    profile        = "ccidu"
  }
}
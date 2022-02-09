data "terraform_remote_state" "k8s_cluster" {
  backend = "s3"

  config = {
    bucket  = "jennings-demo-terraform-state"
    key     = "k8sargocd/testing-eks/terraform.tfstate"
    region  = "ap-northeast-2"
    profile = "ccidu"
  }
}
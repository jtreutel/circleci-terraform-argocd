provider "helm" {
  kubernetes {
    config_path = "${path.module}/../eks/kubeconfig"
  }
}

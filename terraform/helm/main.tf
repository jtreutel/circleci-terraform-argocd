#AWS LB controller setup based on:
#https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.3/deploy/installation/
#https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html

resource "aws_iam_openid_connect_provider" "eks" {
  url = "https://accounts.google.com"

  client_id_list = [
    "266362248691-342342xasdasdasda-apps.googleusercontent.com",
  ]

  thumbprint_list = []
}




resource "helm_release" "argocd" {
  name = "argocd"

  create_namespace = true
  namespace = "argocd"

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"

  values = [
    "${file("${path.module}/argo-cd/values.yaml")}"
  ]

  set {
    name  = "service.type"
    value = "NodePort"
  }
  set {
    name  = "service.nodePort"
    value = 31000
  }
}
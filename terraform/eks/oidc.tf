# Policy which will allow us to create application load balancer from inside of cluster
resource "aws_iam_policy" "ALBIngressControllerIAMPolicy" {
  name        = "ALBIngressControllerIAMPolicy"
  description = "Policy which will be used by role for service - for creating alb from within cluster by issuing declarative kube commands"

  policy = file("${path.module}/templates/eks_alb.json")
}

# Create IAM role
resource "aws_iam_role" "alb-ingress-controller-role" {
  name = "${var.resource_prefix}-alb-ingress-controller"

  assume_role_policy = templatefile(
    "${path.module}/templates/eks_alb_assume.json.tpl",
    {
      eks_cluster_oidc_url = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}",
      eks_cluster_oidc_arn = module.eks.oidc_provider_arn
    }
  )

  depends_on = [module.eks]

  tags = {
    "ServiceAccountName"      = "alb-ingress-controller"
    "ServiceAccountNameSpace" = "kube-system"
  }
}

# Attach policies to IAM role
resource "aws_iam_role_policy_attachment" "alb-ingress-controller-role-ALBIngressControllerIAMPolicy" {
  policy_arn = aws_iam_policy.ALBIngressControllerIAMPolicy.arn
  role       = aws_iam_role.alb-ingress-controller-role.name
  depends_on = [aws_iam_role.alb-ingress-controller-role]
}

resource "aws_iam_role_policy_attachment" "alb-ingress-controller-role-AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.alb-ingress-controller-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  depends_on = [aws_iam_role.alb-ingress-controller-role]
}
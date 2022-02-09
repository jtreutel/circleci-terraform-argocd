{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Federated": "${eks_cluster_oidc_arn}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${eks_cluster_oidc_url}:sub": "system:serviceaccount:kube-system:alb-ingress-controller",
          "${eks_cluster_oidc_url}:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
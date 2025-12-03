variable "apps_root_domain" {}
variable "root_domain" {}
variable "cluster_name" {}
variable "external_dns_service_account" { default = "external-dns" }

resource "helm_release" "aws-load-balancer-controller" {
  name = "aws-load-balancer-controller"

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = data.aws_eks_cluster.cluster.name
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "cluster.dnsDomain"
    value = var.apps_root_domain
  }


  set {
    name  = "image.tag"
    value = "v2.7.1"
  }

}

resource "kubernetes_service_account" "service-account" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
      "app.kubernetes.io/component" = "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn"               = module.lb_role.iam_role_arn
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }
}

module "lb_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"

  role_name                              = "${terraform.workspace}_eks_lb"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = data.aws_iam_openid_connect_provider.oidc_provider.arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

data "aws_iam_openid_connect_provider" "oidc_provider" {
  url = data.aws_eks_cluster.cluster.identity[0].oidc.0.issuer
}

data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

resource "aws_iam_role" "route53_modification" {
  assume_role_policy = data.aws_iam_policy_document.web_identity_assume.json # (not shown)

  name = "route53_modification_role"
}

resource "aws_iam_role_policy" "policies" {
  name = "route53_modification_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["route53:ChangeResourceRecordSets"]
        Resource = ["arn:aws:route53:::hostedzone/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["route53:ListHostedZones", "route53:ListResourceRecordSets", "route53:ListTagsForResource"]
        Resource = "*"
      }
    ]
  })

  role = aws_iam_role.route53_modification.name
}

resource "kubernetes_service_account" "external_dns_service_account" {
  metadata {
    name      = var.external_dns_service_account
    namespace = "external-dns"
    labels = {
      "app.kubernetes.io/name" = var.external_dns_service_account
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.route53_modification.arn
    }
  }
}

resource "helm_release" "external_dns" {
  name             = "external-dns-route53"
  repository       = "oci://registry-1.docker.io/bitnamicharts"
  namespace        = "external-dns"
  chart            = "external-dns"
  create_namespace = true

  set {
    name  = "policy"
    value = "sync"
  }

  set {
    name  = "serviceAccount.name"
    value = var.external_dns_service_account
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "podSecurityContext.fsGroup"
    value = "65534"
  }

  set {
    name  = "podSecurityContext.runAsUser"
    value = "0"
  }

  set {
    name  = "provider"
    value = "aws"
  }

  set {
    name  = "aws.zoneType"
    value = "public"
  }

  set {
    name  = "txtOwnerId"
    value = aws_route53_zone.public_app_root_domain.zone_id
  }

  set {
    name  = "domainFilters[0]"
    value = var.apps_root_domain
  }

  depends_on = [kubernetes_service_account.external_dns_service_account]
}

resource "aws_route53_zone" "public_app_root_domain" {
  name = var.apps_root_domain

  tags = {
    Environment = "all"
  }

}

resource "aws_route53_record" "example" {
  allow_overwrite = true
  name            = var.apps_root_domain
  ttl             = 300
  type            = "NS"
  zone_id         = data.aws_route53_zone.root_domain.zone_id

  records = [
    aws_route53_zone.public_app_root_domain.name_servers[0],
    aws_route53_zone.public_app_root_domain.name_servers[1],
    aws_route53_zone.public_app_root_domain.name_servers[2],
    aws_route53_zone.public_app_root_domain.name_servers[3],
  ]
}

resource "aws_route53_record" "record" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
    # Skips the domain if it doesn't contain a wildcard
    #    if length(regexall("\\*\\..+", dvo.domain_name)) > 0
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.public_app_root_domain.zone_id
}

resource "aws_acm_certificate" "cert" {
  domain_name       = "*.${var.apps_root_domain}"
  validation_method = "DNS"

  tags = {
    Environment = "all"
  }


  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "validation" {
  certificate_arn = aws_acm_certificate.cert.arn
  validation_record_fqdns = concat(
    [
      for record in aws_route53_record.record : record.fqdn
    ],
    [
      for record in aws_route53_record.record : record.fqdn
    ]
  )
}

data "aws_route53_zone" "root_domain" {
  name = var.root_domain
}

data "aws_iam_policy_document" "web_identity_assume" {
  version = "2012-10-17"

  statement {

    effect = "Allow"
    #    resources = ["*"]

    principals {
      type = "Federated"
      identifiers = [
        data.aws_iam_openid_connect_provider.oidc_provider.arn
      ]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = replace("${data.aws_eks_cluster.cluster.identity[0].oidc.0.issuer}:sub", "https://", "")
      values   = ["system:serviceaccount:external-dns:${var.external_dns_service_account}"]
    }
  }

  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "helm_release" "ingress-nginx" {
  repository = "https://kubernetes.github.io/ingress-nginx"
  name       = "ingress-nginx"
  chart      = "ingress-nginx"

  version          = "4.10.1"
  namespace        = "ingress-nginx"
  create_namespace = true

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-cert"
    value = aws_acm_certificate.cert.arn
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-backend-protocol"
    value = "http"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-ports"
    value = "https"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-connection-idle-timeout"
    value = "3600"
  }

  set {
    name  = "controller.config.use-forwarded-headers"
    value = "true"
    type  = "string"
  }


  set {
    name  = "controller.config.ssl-redirect"
    value = "true"
    type  = "string"
  }

  # set {
  #   name  = "controller.config.X-Forwarded-Proto"
  #   value = "https"
  #   type  = "string"
  # }

  set {
    name  = "controller.service.targetPorts.https"
    value = "http"
  }

  set {
    name  = "controller.allowSnippetAnnotations"
    value = "true"
  }

}

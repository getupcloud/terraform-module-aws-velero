locals {
  name_prefix = substr("${var.customer_name}-${var.cluster_name}-velero", 0, 32)
  use_oidc    = var.cluster_oidc_issuer_url != ""
  use_iam     = var.cluster_oidc_issuer_url == ""

}

data "aws_iam_policy_document" "aws_velero" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeVolumes",
      "ec2:DescribeSnapshots",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:CreateSnapshot",
      "ec2:DeleteSnapshot"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts"
    ]

    resources = [
      "arn:aws:s3:::${local.name_prefix}/*"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::${local.name_prefix}",
    ]
  }
}

### AUTH BY IRSA

module "irsa_aws_velero" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 4.2"

  count                         = local.use_oidc ? 1 : 0
  create_role                   = true
  role_name_prefix              = local.name_prefix
  provider_url                  = var.cluster_oidc_issuer_url
  role_policy_arns              = [aws_iam_policy.aws_velero[0].arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${var.service_account_namespace}:${var.service_account_name}"]
  tags                          = var.tags
}

resource "aws_iam_policy" "aws_velero" {
  count       = local.use_oidc ? 1 : 0
  name_prefix = local.name_prefix
  description = "Velero bucket policy for AWS cluster ${var.cluster_name}"
  policy      = data.aws_iam_policy_document.aws_velero.json
}

### AUTH BY SECRET

resource "aws_iam_user" "aws_velero" {
  count = local.use_iam ? 1 : 0
  name  = local.name_prefix
}

resource "aws_iam_access_key" "aws_velero" {
  count = local.use_iam ? 1 : 0
  user  = aws_iam_user.aws_velero[0].name
}

resource "aws_iam_user_policy" "aws_velero" {
  count       = local.use_iam ? 1 : 0
  name_prefix = local.name_prefix
  user        = aws_iam_user.aws_velero[0].name

  policy = data.aws_iam_policy_document.aws_velero.json
}

### BUCKET

resource "aws_s3_bucket" "aws_velero" {
  bucket        = var.bucket_name != "" ? var.bucket_name : local.name_prefix
  force_destroy = true

  tags = merge({
    Name = "${var.cluster_name}"
    }, var.tags
  )
}

resource "aws_s3_bucket_acl" "aws_velero_acl" {
  bucket = aws_s3_bucket.aws_velero.id
  acl    = "private"
}

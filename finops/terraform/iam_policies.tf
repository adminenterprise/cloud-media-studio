# ==============================================================================
# IAM POLICIES: CHÍNH SÁCH ĐẶC QUYỀN TỐI THIỂU CHO TỪNG PHÂN MẢNG DỰ ÁN
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. CHÍNH SÁCH DÙNG CHUNG (COMMON BASE POLICY) CHO CẢ 4 THÀNH VIÊN
# Cho phép tự đổi password, bật MFA, tự xem thông tin và xem Budgets/Billing
# ------------------------------------------------------------------------------
resource "aws_iam_policy" "common_base" {
  name        = "${var.project_name}-common-base-policy"
  description = "Chính sách nền tảng cho 4 thành viên: Tự quản lý bảo mật cá nhân (Password, MFA) và xem FinOps"
  path        = "/team/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSelfPasswordManagement"
        Effect = "Allow"
        Action = [
          "iam:ChangePassword",
          "iam:GetAccountPasswordPolicy",
          "iam:GetUser"
        ]
        Resource = "arn:aws:iam::*:user/$${aws:username}"
      },
      {
        Sid    = "AllowSelfMFAManagement"
        Effect = "Allow"
        Action = [
          "iam:CreateVirtualMFADevice",
          "iam:DeleteVirtualMFADevice",
          "iam:EnableMFADevice",
          "iam:ResyncMFADevice",
          "iam:ListMFADevices",
          "iam:ListVirtualMFADevices"
        ]
        Resource = [
          "arn:aws:iam::*:mfa/$${aws:username}",
          "arn:aws:iam::*:user/$${aws:username}"
        ]
      },
      {
        Sid    = "AllowCostAndBudgetVisibility"
        Effect = "Allow"
        Action = [
          "budgets:ViewBudget",
          "ce:GetCostAndUsage",
          "ce:GetCostForecast",
          "cloudwatch:GetMetricData",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# 2. CHÍNH SÁCH MEMBER 1: MẠNG & IaC (VPC, Subnet, Route, IGW, NAT, ALB, Route53, CloudFront)
# ------------------------------------------------------------------------------
resource "aws_iam_policy" "member1_network" {
  name        = "${var.project_name}-member1-network-iac-policy"
  description = "Quyền quản trị hạ tầng Mạng & IaC cho Member 1"
  path        = "/team/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowVpcAndNetworkingManagement"
        Effect = "Allow"
        Action = [
          "ec2:*Vpc*",
          "ec2:*Subnet*",
          "ec2:*RouteTable*",
          "ec2:*Route*",
          "ec2:*InternetGateway*",
          "ec2:*NatGateway*",
          "ec2:*Address*",
          "ec2:*SecurityGroup*",
          "ec2:*NetworkAcl*",
          "ec2:*VpcPeeringConnection*",
          "ec2:*TransitGateway*",
          "ec2:*VpcEndpoint*",
          "ec2:Describe*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowLoadBalancerManagement"
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowDnsAndCdnManagement"
        Effect = "Allow"
        Action = [
          "route53:*",
          "route53domains:*",
          "cloudfront:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowWafAssociationOnly"
        Effect = "Allow"
        Action = [
          "wafv2:Get*",
          "wafv2:List*",
          "wafv2:AssociateWebACL",
          "wafv2:DisassociateWebACL"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowTerraformStateAccess"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = [
          "arn:aws:s3:::*terraform-state*",
          "arn:aws:s3:::*terraform-state*/*",
          "arn:aws:dynamodb:*:*:table/*terraform-locks*"
        ]
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# 3. CHÍNH SÁCH MEMBER 2: TÍNH TOÁN & CONTAINER (EC2, ASG, ECS, ECR, EFS, Lambda, Lightsail)
# ------------------------------------------------------------------------------
resource "aws_iam_policy" "member2_compute" {
  name        = "${var.project_name}-member2-compute-container-policy"
  description = "Quyền quản trị máy chủ tính toán & container cho Member 2"
  path        = "/team/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEc2AndAutoScalingManagement"
        Effect = "Allow"
        Action = [
          "ec2:RunInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:RestartInstances",
          "ec2:TerminateInstances",
          "ec2:Describe*",
          "ec2:CreateLaunchTemplate*",
          "ec2:ModifyLaunchTemplate*",
          "ec2:DeleteLaunchTemplate*",
          "ec2:CreateKeyPair",
          "ec2:DeleteKeyPair",
          "ec2:DescribeKeyPairs",
          "autoscaling:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowContainerServicesManagement"
        Effect = "Allow"
        Action = [
          "ecs:*",
          "ecr:*",
          "elasticfilesystem:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowServerlessAndAppPlatforms"
        Effect = "Allow"
        Action = [
          "lambda:*",
          "elasticbeanstalk:*",
          "lightsail:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowPassRoleForCompute"
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = "arn:aws:iam::*:role/*ecsTaskExecutionRole*"
        Condition = {
          StringLike = {
            "iam:PassedToService" = [
              "ecs-tasks.amazonaws.com",
              "ec2.amazonaws.com",
              "lambda.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# 4. CHÍNH SÁCH MEMBER 3: DỮ LIỆU & FINOPS (RDS, DynamoDB, S3, Glacier, Redshift, CloudWatch, Budgets)
# ------------------------------------------------------------------------------
resource "aws_iam_policy" "member3_data" {
  name        = "${var.project_name}-member3-data-finops-policy"
  description = "Quyền quản trị Dữ liệu, Lưu trữ, Giám sát và FinOps cho Member 3"
  path        = "/team/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowRelationalAndNoSqlDatabaseManagement"
        Effect = "Allow"
        Action = [
          "rds:*",
          "rds-data:*",
          "rds-db:*",
          "dynamodb:*",
          "dax:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowObjectStorageAndArchivingManagement"
        Effect = "Allow"
        Action = [
          "s3:*",
          "glacier:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowDataAnalyticsManagement"
        Effect = "Allow"
        Action = [
          "redshift-serverless:*",
          "redshift:*",
          "redshift-data:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowObservabilityAndAuditManagement"
        Effect = "Allow"
        Action = [
          "cloudwatch:*",
          "logs:*",
          "cloudtrail:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowFinOpsAndCostManagement"
        Effect = "Allow"
        Action = [
          "budgets:*",
          "ce:*",
          "cur:*",
          "pricing:*",
          "aws-portal:ViewBilling",
          "aws-portal:ViewUsage"
        ]
        Resource = "*"
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# 5. CHÍNH SÁCH MEMBER 4: BẢO MẬT & DEVSECOPS (WAF, Secrets Manager, KMS, Cognito, SQS, SNS)
# ------------------------------------------------------------------------------
resource "aws_iam_policy" "member4_security" {
  name        = "${var.project_name}-member4-security-devsecops-policy"
  description = "Quyền quản trị An ninh, Quản lý khóa và DevSecOps cho Member 4"
  path        = "/team/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowWafManagement"
        Effect = "Allow"
        Action = [
          "wafv2:*",
          "waf:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowSecretsAndKeyManagement"
        Effect = "Allow"
        Action = [
          "secretsmanager:*",
          "kms:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowCognitoAuthenticationManagement"
        Effect = "Allow"
        Action = [
          "cognito-idp:*",
          "cognito-identity:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowEventMessagingManagement"
        Effect = "Allow"
        Action = [
          "sqs:*",
          "sns:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowCiCdRoleAndPolicyManagement"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:CreateRole",
          "iam:PutRolePolicy",
          "iam:AttachRolePolicy",
          "iam:PassRole"
        ]
        Resource = [
          "arn:aws:iam::*:role/*github-actions*",
          "arn:aws:iam::*:role/*cicd*",
          "arn:aws:iam::*:role/*trivy*"
        ]
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# 6. GẮN CÁC POLICY VÀO CÁC NHÓM IAM TƯƠNG ỨNG
# ------------------------------------------------------------------------------
# Gắn Base Policy cho cả 4 nhóm
resource "aws_iam_group_policy_attachment" "base_network" {
  group      = aws_iam_group.network_iac.name
  policy_arn = aws_iam_policy.common_base.arn
}

resource "aws_iam_group_policy_attachment" "base_compute" {
  group      = aws_iam_group.compute_container.name
  policy_arn = aws_iam_policy.common_base.arn
}

resource "aws_iam_group_policy_attachment" "base_data" {
  group      = aws_iam_group.data_finops.name
  policy_arn = aws_iam_policy.common_base.arn
}

resource "aws_iam_group_policy_attachment" "base_security" {
  group      = aws_iam_group.security_devsecops.name
  policy_arn = aws_iam_policy.common_base.arn
}

# Gắn Special Policy theo từng mảng
resource "aws_iam_group_policy_attachment" "member1_attachment" {
  group      = aws_iam_group.network_iac.name
  policy_arn = aws_iam_policy.member1_network.arn
}

resource "aws_iam_group_policy_attachment" "member2_attachment" {
  group      = aws_iam_group.compute_container.name
  policy_arn = aws_iam_policy.member2_compute.arn
}

resource "aws_iam_group_policy_attachment" "member3_attachment" {
  group      = aws_iam_group.data_finops.name
  policy_arn = aws_iam_policy.member3_data.arn
}

resource "aws_iam_group_policy_attachment" "member4_attachment" {
  group      = aws_iam_group.security_devsecops.name
  policy_arn = aws_iam_policy.member4_security.arn
}

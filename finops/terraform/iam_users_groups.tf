# ==============================================================================
# IAM USERS, GROUPS & PASSWORD POLICY: NGUYÊN TẮC ĐẶC QUYỀN TỐI THIỂU (LEAST PRIVILEGE)
# ==============================================================================

# 1. BẢO VỆ TÀI KHOẢN: CHÍNH SÁCH MẬT KHẨU DOANH NGHIỆP
resource "aws_iam_account_password_policy" "strict_policy" {
  minimum_password_length        = 12
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = true
  allow_users_to_change_password = true
  hard_expiry                    = false
  max_password_age               = 90
  password_reuse_prevention      = 3
}

# 2. KHỞI TẠO 4 IAM GROUPS THEO 4 TRACK CHUYÊN MÔN
resource "aws_iam_group" "network_iac" {
  name = "Network-IaC-Group"
  path = "/team/"
}

resource "aws_iam_group" "compute_container" {
  name = "Compute-Container-Group"
  path = "/team/"
}

resource "aws_iam_group" "data_finops" {
  name = "Data-FinOps-Group"
  path = "/team/"
}

resource "aws_iam_group" "security_devsecops" {
  name = "Security-DevSecOps-Group"
  path = "/team/"
}

# 3. KHỞI TẠO 4 IAM USERS CHO 4 THÀNH VIÊN
resource "aws_iam_user" "member1" {
  name = var.member_users["member1"].username
  path = "/team/"

  tags = {
    Role        = var.member_users["member1"].role
    Track       = "Network-IaC"
    TeamMember  = "Member 1 - Team Leader"
  }
}

resource "aws_iam_user" "member2" {
  name = var.member_users["member2"].username
  path = "/team/"

  tags = {
    Role        = var.member_users["member2"].role
    Track       = "Compute-Container"
    TeamMember  = "Member 2"
  }
}

resource "aws_iam_user" "member3" {
  name = var.member_users["member3"].username
  path = "/team/"

  tags = {
    Role        = var.member_users["member3"].role
    Track       = "Data-FinOps"
    TeamMember  = "Member 3 - Pham The Hung"
  }
}

resource "aws_iam_user" "member4" {
  name = var.member_users["member4"].username
  path = "/team/"

  tags = {
    Role        = var.member_users["member4"].role
    Track       = "Security-DevSecOps"
    TeamMember  = "Member 4"
  }
}

# 4. GÁN THÀNH VIÊN VÀO NHÓM CHUYÊN TRÁCH TƯƠNG ỨNG
resource "aws_iam_group_membership" "network_iac_membership" {
  name  = "network-iac-membership"
  users = [aws_iam_user.member1.name]
  group = aws_iam_group.network_iac.name
}

resource "aws_iam_group_membership" "compute_container_membership" {
  name  = "compute-container-membership"
  users = [aws_iam_user.member2.name]
  group = aws_iam_group.compute_container.name
}

resource "aws_iam_group_membership" "data_finops_membership" {
  name  = "data-finops-membership"
  users = [aws_iam_user.member3.name]
  group = aws_iam_group.data_finops.name
}

resource "aws_iam_group_membership" "security_devsecops_membership" {
  name  = "security-devsecops-membership"
  users = [aws_iam_user.member4.name]
  group = aws_iam_group.security_devsecops.name
}

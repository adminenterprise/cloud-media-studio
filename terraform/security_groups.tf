# ==============================================================================
# SECURITY GROUPS — TƯỜNG LỬA ẢO KIỂM SOÁT INBOUND/OUTBOUND GIỮA CÁC TẦNG
# Nguyên tắc: Principle of Least Privilege + SG-to-SG Reference (không dùng CIDR nội bộ)
# ==============================================================================

# ==============================================================================
# 1. ALB SECURITY GROUP (Edge Tier — Nhận traffic từ Internet)
# Phục vụ: Member 2 gắn vào Application Load Balancer
# ==============================================================================
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security Group for Application Load Balancer - Allow HTTP/HTTPS from Internet"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-alb-sg"
    Tier = "Public"
    Role = "Edge-LoadBalancer"
  }
}

# --- ALB Ingress: HTTP từ Internet ---
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP traffic from Internet (redirect to HTTPS)"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"

  tags = { Name = "alb-allow-http-internet" }
}

# --- ALB Ingress: HTTPS từ Internet ---
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS traffic from Internet"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"

  tags = { Name = "alb-allow-https-internet" }
}

# --- ALB Egress: Chuyển tiếp traffic đến App Server ---
resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Forward traffic to App Server on application port"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"

  tags = { Name = "alb-to-app-server" }
}

# ==============================================================================
# 2. APP SERVER SECURITY GROUP (Compute Tier — EC2 ASG / ECS Fargate)
# Phục vụ: Member 2 triển khai EC2 Auto Scaling Group, ECS Fargate Tasks
# ==============================================================================
resource "aws_security_group" "app" {
  name        = "${var.project_name}-app-sg"
  description = "Security Group for App Servers (EC2/ECS) - Only accept traffic from ALB and Bastion"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-app-sg"
    Tier = "Private-App"
    Role = "Compute-EC2-ECS"
  }
}

# --- App Ingress: Nhận traffic từ ALB trên app port ---
resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  description                  = "Accept application traffic from ALB only"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"

  tags = { Name = "app-from-alb" }
}

# --- App Ingress: SSH từ Bastion Host (debug/admin) ---
resource "aws_vpc_security_group_ingress_rule" "app_ssh_from_bastion" {
  security_group_id            = aws_security_group.app.id
  description                  = "Allow SSH from Bastion Host for debugging and administration"
  referenced_security_group_id = aws_security_group.bastion.id
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"

  tags = { Name = "app-ssh-from-bastion" }
}

# --- App Egress: Kết nối Database trên MySQL port ---
resource "aws_vpc_security_group_egress_rule" "app_to_db" {
  security_group_id            = aws_security_group.app.id
  description                  = "Connect to RDS MySQL/Aurora database"
  referenced_security_group_id = aws_security_group.db.id
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"

  tags = { Name = "app-to-database" }
}

# --- App Egress: Mount EFS qua NFS ---
resource "aws_vpc_security_group_egress_rule" "app_to_efs" {
  security_group_id            = aws_security_group.app.id
  description                  = "Mount Amazon EFS shared storage via NFS"
  referenced_security_group_id = aws_security_group.efs.id
  from_port                    = 2049
  to_port                      = 2049
  ip_protocol                  = "tcp"

  tags = { Name = "app-to-efs-nfs" }
}

# --- App Egress: HTTPS ra Internet (pull packages, Docker images, API calls) ---
resource "aws_vpc_security_group_egress_rule" "app_https_outbound" {
  security_group_id = aws_security_group.app.id
  description       = "Allow HTTPS outbound for pulling packages, Docker images, and external API calls"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"

  tags = { Name = "app-https-outbound" }
}

# --- App Egress: DNS resolution ---
resource "aws_vpc_security_group_egress_rule" "app_dns_udp" {
  security_group_id = aws_security_group.app.id
  description       = "Allow DNS resolution (UDP)"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 53
  to_port           = 53
  ip_protocol       = "udp"

  tags = { Name = "app-dns-udp" }
}

resource "aws_vpc_security_group_egress_rule" "app_dns_tcp" {
  security_group_id = aws_security_group.app.id
  description       = "Allow DNS resolution (TCP)"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 53
  to_port           = 53
  ip_protocol       = "tcp"

  tags = { Name = "app-dns-tcp" }
}

# ==============================================================================
# 3. DATABASE SECURITY GROUP (Data Tier — RDS MySQL / Aurora Serverless)
# Phục vụ: Member 3 triển khai RDS trong Private-DB Subnet (Isolated)
# ==============================================================================
resource "aws_security_group" "db" {
  name        = "${var.project_name}-db-sg"
  description = "Security Group for RDS MySQL/Aurora - Only accept connections from App Servers (Fully Isolated)"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-db-sg"
    Tier = "Private-DB"
    Role = "Database-Isolated"
  }
}

# --- DB Ingress: Chỉ nhận kết nối MySQL từ App Server SG ---
resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id            = aws_security_group.db.id
  description                  = "Accept MySQL connections from App Servers only (Least Privilege)"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"

  tags = { Name = "db-from-app-mysql" }
}

# --- DB: KHÔNG CÓ EGRESS RULE → Cách ly hoàn toàn (Fully Isolated) ---
# Database tier không cần gọi ra Internet, tuân thủ nghiêm ngặt Enterprise DevSecOps

# ==============================================================================
# 4. EFS SECURITY GROUP (Shared Storage — Amazon Elastic File System)
# Phục vụ: Member 2 mount ổ đĩa chia sẻ EFS cho EC2/ECS tasks
# ==============================================================================
resource "aws_security_group" "efs" {
  name        = "${var.project_name}-efs-sg"
  description = "Security Group for Amazon EFS - Only accept NFS mount from App Servers"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-efs-sg"
    Tier = "Private-App"
    Role = "SharedStorage-EFS"
  }
}

# --- EFS Ingress: Chỉ nhận NFS mount từ App Server SG ---
resource "aws_vpc_security_group_ingress_rule" "efs_from_app" {
  security_group_id            = aws_security_group.efs.id
  description                  = "Accept NFS mount from App Servers only"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 2049
  to_port                      = 2049
  ip_protocol                  = "tcp"

  tags = { Name = "efs-nfs-from-app" }
}

# --- EFS: KHÔNG CÓ EGRESS RULE → Chỉ phục vụ storage, không gọi ra ngoài ---

# ==============================================================================
# 5. BASTION HOST SECURITY GROUP (Admin Access — Jump Box)
# Dùng cho quản trị viên SSH vào Private Subnet để debug
# ==============================================================================
resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-bastion-sg"
  description = "Security Group for Bastion Host - SSH access restricted to Admin IP only"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-bastion-sg"
    Tier = "Public"
    Role = "Admin-BastionHost"
  }
}

# --- Bastion Ingress: SSH chỉ từ IP Admin (giới hạn chặt) ---
resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
  security_group_id = aws_security_group.bastion.id
  description       = "Allow SSH from Admin IP only (Restrict brute-force attack surface)"
  cidr_ipv4         = var.admin_ip
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"

  tags = { Name = "bastion-ssh-admin-only" }
}

# --- Bastion Egress: SSH đến App Server (jump vào Private Subnet) ---
resource "aws_vpc_security_group_egress_rule" "bastion_to_app_ssh" {
  security_group_id            = aws_security_group.bastion.id
  description                  = "SSH to App Servers in Private Subnet for debugging"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"

  tags = { Name = "bastion-ssh-to-app" }
}

# --- Bastion Egress: HTTPS ra Internet (cập nhật hệ thống, tải công cụ) ---
resource "aws_vpc_security_group_egress_rule" "bastion_https_outbound" {
  security_group_id = aws_security_group.bastion.id
  description       = "Allow HTTPS outbound for system updates and tool downloads"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"

  tags = { Name = "bastion-https-outbound" }
}

# ==============================================================================
# AMAZON RDS MYSQL — TUẦN 2: CƠ SỞ DỮ LIỆU GIAO DỊCH CHÍNH
# ==============================================================================
# Triển khai RDS MySQL db.t3.micro trong Private DB Subnet (Multi-AZ)
# Sử dụng DB Subnet Group đã bàn giao từ Member 1 (terraform/outputs.tf)
# Chi phí: ~$0.018/giờ | Nhớ STOP khi không dùng để tiết kiệm credit $200!

# ------------------------------------------------------------------------------
# 1. SECURITY GROUP CHO RDS (Least Privilege — Chỉ port 3306 từ App Subnets)
# ------------------------------------------------------------------------------
resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-rds-sg-"
  description = "Security Group cho RDS MySQL - Chi cho phep ket noi tu Private App Subnets (Port 3306)"
  vpc_id      = var.vpc_id

  # Inbound: Chỉ cho phép MySQL port 3306 từ Private App Subnets
  ingress {
    description = "MySQL/Aurora tu Private App Subnets (Member 2: EC2/ECS)"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = var.private_app_subnet_cidrs
  }

  # Outbound: Cho phép tất cả (RDS cần gọi AWS API cho monitoring)
  egress {
    description = "Cho phep tat ca outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-mysql-sg"
    Tier = "Private-DB"
    Week = "Week-2"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ------------------------------------------------------------------------------
# 2. DB PARAMETER GROUP (Tối ưu cho ứng dụng Việt Nam — UTF8MB4)
# ------------------------------------------------------------------------------
resource "aws_db_parameter_group" "mysql_params" {
  name_prefix = "${var.project_name}-mysql-params-"
  family      = "mysql8.0"
  description = "Custom parameter group cho RDS MySQL - Ho tro UTF8MB4 tieng Viet"

  # Hỗ trợ đầy đủ ký tự tiếng Việt (emoji, dấu)
  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  # db.t3.micro giới hạn kết nối hợp lý
  parameter {
    name  = "max_connections"
    value = "100"
  }

  # Bật log truy vấn chậm — chuẩn bị cho CloudWatch Tuần 4
  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  # Truy vấn chạy > 2 giây sẽ bị ghi log
  parameter {
    name  = "long_query_time"
    value = "2"
  }

  tags = {
    Name = "${var.project_name}-mysql-params"
    Week = "Week-2"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ------------------------------------------------------------------------------
# 3. IAM ROLE CHO RDS ENHANCED MONITORING
# ------------------------------------------------------------------------------
resource "aws_iam_role" "rds_monitoring" {
  name_prefix = "${var.project_name}-rds-mon-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "monitoring.rds.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "${var.project_name}-rds-monitoring-role"
    Week = "Week-2"
  }
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# ------------------------------------------------------------------------------
# 4. RDS MYSQL INSTANCE (db.t3.micro — FinOps Optimized)
# ------------------------------------------------------------------------------
resource "aws_db_instance" "mysql_primary" {
  identifier     = "${var.project_name}-mysql-primary"
  engine         = "mysql"
  engine_version = var.rds_engine_version
  instance_class = var.rds_instance_class # db.t3.micro (~$0.018/hr)

  # Lưu trữ
  allocated_storage     = var.rds_allocated_storage     # 20 GB khởi tạo
  max_allocated_storage = var.rds_max_allocated_storage # Auto-scale tối đa 50GB
  storage_type          = "gp2"
  storage_encrypted     = true # Mã hóa dữ liệu at-rest bằng AWS managed key

  # Database
  db_name  = var.rds_db_name
  username = var.rds_master_username
  password = var.rds_master_password # Tạm thời — Tuần 4 Member 4 chuyển sang Secrets Manager

  # Mạng (Bàn giao từ Member 1)
  db_subnet_group_name   = var.rds_db_subnet_group_name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # High Availability
  multi_az            = var.rds_multi_az # false khi dev, true khi demo bảo vệ
  publicly_accessible = false            # TUYỆT ĐỐI KHÔNG expose ra Internet

  # Lifecycle — Tối ưu cho môi trường đồ án
  deletion_protection       = false # Cho phép xóa khi dọn dẹp credit
  skip_final_snapshot       = true  # Bỏ qua snapshot cuối khi destroy (tiết kiệm)
  final_snapshot_identifier = null

  # Backup
  backup_retention_period = 7                     # Giữ backup 7 ngày
  backup_window           = "03:00-04:00"         # UTC: 03:00 = VN: 10:00 sáng
  maintenance_window      = "Mon:04:00-Mon:05:00" # UTC: 04:00 = VN: 11:00 sáng thứ 2

  # Monitoring — Performance Insights miễn phí cho db.t3.micro
  performance_insights_enabled          = true
  performance_insights_retention_period = 7 # 7 ngày miễn phí

  # Enhanced Monitoring — Chuẩn bị cho CloudWatch Dashboard Tuần 4
  monitoring_interval = 60 # Giám sát mỗi 60 giây
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn

  # Parameter Group tùy chỉnh (UTF8MB4)
  parameter_group_name = aws_db_parameter_group.mysql_params.name

  tags = {
    Name         = "${var.project_name}-mysql-primary"
    Tier         = "Private-DB"
    Week         = "Week-2"
    CostCenter   = "Member3-Data-FinOps"
    StopWhenIdle = "true"
  }
}

# ==============================================================================
# AMAZON ECS FARGATE BACKEND SERVICE — TUẦN 2 & 4: CONTAINER DEPLOYMENT
# ==============================================================================
# Phân mảng: Thành viên 2 (Compute & Container)
# Phục vụ:
# - Chạy container backend microservice trên AWS Fargate (Serverless Container)
# - Lưu trữ image trong Amazon ECR với cơ chế quét lỗ hổng tự động (Scan on Push)
# - Kết nối với Application Load Balancer (ALB) Target Group trong Private Subnet
# - FinOps: Tắt mặc định (enable_fargate = false) để duy trì chi phí $0.00
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. AMAZON ECR REPOSITORY (Kho lưu trữ Docker Image)
# ------------------------------------------------------------------------------
resource "aws_ecr_repository" "backend" {
  name                 = "${var.project_name}-backend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.project_name}-backend-ecr"
    Tier        = "Container-Registry"
    Role        = "ECR-Backend"
    Environment = var.environment
  }
}

# ------------------------------------------------------------------------------
# 2. AMAZON ECS CLUSTER
# ------------------------------------------------------------------------------
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled" # FinOps: Tắt Container Insights để không phát sinh phụ phí CloudWatch
  }

  tags = {
    Name        = "${var.project_name}-ecs-cluster"
    Tier        = "Compute-Fargate"
    Environment = var.environment
  }
}

# ------------------------------------------------------------------------------
# 3. IAM ROLES CHO ECS FARGATE
# ------------------------------------------------------------------------------
# 3.1 Execution Role: Cho phép ECS Agent kéo image từ ECR và ghi log vào CloudWatch
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.project_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "${var.project_name}-ecs-execution-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_attach" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 3.2 Task Role: Cho phép code bên trong container gọi các API của AWS (S3, CloudWatch...)
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "${var.project_name}-ecs-task-role"
    Environment = var.environment
  }
}

resource "aws_iam_policy" "ecs_s3_access" {
  name        = "${var.project_name}-ecs-s3-access"
  description = "Quyen truy cap S3 bucket cho Backend Fargate"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ]
      Resource = [
        "arn:aws:s3:::${var.s3_static_assets_bucket_name}",
        "arn:aws:s3:::${var.s3_static_assets_bucket_name}/*"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_s3_attach" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_s3_access.arn
}

# ------------------------------------------------------------------------------
# 4. CLOUDWATCH LOG GROUP CHO CONTAINER LOGS
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "ecs_backend" {
  name              = "/ecs/${var.project_name}-backend"
  retention_in_days = 7 # FinOps: Chỉ giữ log 7 ngày để tiết kiệm dung lượng

  tags = {
    Name        = "${var.project_name}-ecs-backend-logs"
    Environment = var.environment
  }
}

# ------------------------------------------------------------------------------
# 5. ECS TASK DEFINITION (FARGATE 0.25 vCPU & 512MB RAM)
# ------------------------------------------------------------------------------
resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.project_name}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256" # 0.25 vCPU
  memory                   = "512" # 512 MB
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "${var.project_name}-backend"
    image     = "${aws_ecr_repository.backend.repository_url}:latest"
    essential = true

    portMappings = [{
      containerPort = var.app_port
      hostPort      = var.app_port
      protocol      = "tcp"
    }]

    environment = [
      { name = "PORT", value = tostring(var.app_port) },
      { name = "NODE_ENV", value = "production" },
      { name = "AWS_REGION", value = var.aws_region },
      { name = "S3_BUCKET", value = var.s3_static_assets_bucket_name }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs_backend.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = {
    Name        = "${var.project_name}-task-def"
    Environment = var.environment
  }
}

# ------------------------------------------------------------------------------
# 6. ECS SERVICE (Chạy trong Private Subnets, Multi-AZ)
# ------------------------------------------------------------------------------
resource "aws_ecs_service" "backend" {
  count           = var.enable_fargate ? 1 : 0
  name            = "${var.project_name}-backend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private_app[*].id
    security_groups  = [aws_security_group.app.id]
    assign_public_ip = false # Bảo mật: Chạy hoàn toàn trong Private Subnet
  }

  dynamic "load_balancer" {
    for_each = local.enable_alb_effective ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.app[0].arn
      container_name   = "${var.project_name}-backend"
      container_port   = var.app_port
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution_role_attach
  ]

  tags = {
    Name        = "${var.project_name}-ecs-service"
    Environment = var.environment
  }
}

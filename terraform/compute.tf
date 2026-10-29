# ==============================================================================
# MEMBER 2 - WEEK 2 EC2 LAUNCH TEMPLATE
# Instances are launched by an Auto Scaling Group in private_app subnets.
# ==============================================================================

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Lets EC2 use Systems Manager Session Manager without opening inbound SSH.
resource "aws_iam_role" "week2_ec2_ssm" {
  name = "${var.project_name}-week2-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name  = "${var.project_name}-week2-ec2-ssm-role"
    Owner = "Member2-Compute"
  }
}

resource "aws_iam_role_policy_attachment" "week2_ec2_ssm" {
  role       = aws_iam_role.week2_ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "week2_ec2_ssm" {
  name = "${var.project_name}-week2-ec2-ssm-profile"
  role = aws_iam_role.week2_ec2_ssm.name

  tags = {
    Name  = "${var.project_name}-week2-ec2-ssm-profile"
    Owner = "Member2-Compute"
  }
}

resource "aws_launch_template" "week2_app" {
  name                   = "${var.project_name}-week2-app"
  description            = "Amazon Linux 2023 application instance with EFS mount for Week 2"
  image_id               = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.app.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.week2_ec2_ssm.name
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  user_data = base64encode(<<-USERDATA
    #!/bin/bash
    set -euxo pipefail

    dnf install -y amazon-efs-utils python3
    mkdir -p /mnt/efs

    # Mount EFS now and again automatically after an instance reboot.
    echo "${var.efs_file_system_id}:/ /mnt/efs efs _netdev,noresvport,tls 0 0" >> /etc/fstab
    mount /mnt/efs

    # Write a per-instance marker so the group can verify shared storage.
    echo "Created by $(hostname)" > "/mnt/efs/instance-$(hostname).txt"

    cat > /opt/week2_app.py <<'PYTHON'
    from http.server import BaseHTTPRequestHandler, HTTPServer
    import socket

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            if self.path == "/health":
                body = b"ok"
            else:
                body = ("Week 2 app running on " + socket.gethostname()).encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

    HTTPServer(("0.0.0.0", ${var.app_port}), Handler).serve_forever()
    PYTHON

    cat > /etc/systemd/system/week2-app.service <<'UNIT'
    [Unit]
    Description=Week 2 demo application
    After=network-online.target remote-fs.target
    Wants=network-online.target

    [Service]
    Type=simple
    ExecStart=/usr/bin/python3 /opt/week2_app.py
    Restart=always

    [Install]
    WantedBy=multi-user.target
    UNIT

    systemctl daemon-reload
    systemctl enable --now week2-app
  USERDATA
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name  = "${var.project_name}-week2-app"
      Owner = "Member2-Compute"
    }
  }

  tags = {
    Name  = "${var.project_name}-week2-app-launch-template"
    Owner = "Member2-Compute"
  }
}

# Launch Template alone does not launch instances. The Auto Scaling Group below
# creates the initial EC2 instance and registers it with the EC2 target group.
resource "aws_autoscaling_group" "week2_app" {
  count = local.enable_alb_effective ? 1 : 0

  name                      = "${var.project_name}-week2-asg"
  min_size                  = 1
  desired_capacity          = 1
  max_size                  = 2
  vpc_zone_identifier       = aws_subnet.private_app[*].id
  target_group_arns         = [aws_lb_target_group.app_ec2[0].arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.week2_app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-week2-app"
    propagate_at_launch = true
  }

  tag {
    key                 = "Owner"
    value               = "Member2-Compute"
    propagate_at_launch = true
  }
}

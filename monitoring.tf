# Monitoring Instance with Prometheus and Grafana

# 1. Create monitoring security group
resource "aws_security_group" "monitoring" {
  name        = "monitoring-sg"
  description = "Security group for monitoring stack"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Prometheus"
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Grafana"
  }

  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    security_groups = [var.security_group_id]
    description = "Node Exporter from app instances"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "monitoring-sg"
  }
}

# 2. Node Exporter rule for app security group
resource "aws_security_group_rule" "app_to_node_exporter" {
  type              = "ingress"
  from_port         = 9100
  to_port           = 9100
  protocol          = "tcp"
  security_group_id = var.security_group_id
  source_security_group_id = aws_security_group.monitoring.id
  description       = "Node Exporter metrics from monitoring instance"
}

# 3. Prometheus scrape app instances
resource "aws_security_group_rule" "monitoring_scrape_apps" {
  type              = "egress"
  from_port         = 9100
  to_port           = 9100
  protocol          = "tcp"
  security_group_id = aws_security_group.monitoring.id
  source_security_group_id = var.security_group_id
  description       = "Scrape Node Exporter metrics from app instances"
}

# 4. Monitoring EC2 Instance
resource "aws_instance" "monitoring" {
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  iam_instance_profile   = var.instance_profile_name
  subnet_id              = var.subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.monitoring.id]

  user_data = base64encode(templatefile("${path.module}/monitoring-setup.sh", {
    app_instance_1_ip = aws_instance.app_server[0].private_ip
    app_instance_2_ip = aws_instance.app_server[1].private_ip
    alb_dns           = aws_lb.alb.dns_name
  }))

  tags = {
    Name = "monitoring-instance"
  }

  depends_on = [aws_instance.app_server, aws_lb.alb]
}
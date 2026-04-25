# 1. Target Group
resource "aws_lb_target_group" "tg" {
  name     = "exam-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

# 2. ALB
resource "aws_lb" "alb" {
  name               = "exam-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.subnet_ids
}

# 3. Listener
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# 4. Two EC2 Instances
resource "aws_instance" "app_server" {
  count                = 2
  ami                  = var.ami_id
  instance_type        = "t3.micro"
  iam_instance_profile = var.instance_profile_name
  subnet_id            = count.index == 0 ? var.subnet_ids[0] : var.subnet_ids[1]
  vpc_security_group_ids = [var.security_group_id]

  user_data = <<-EOF
              #!/bin/bash
              yum install -y httpd
              systemctl start httpd
              echo "Hello from Instance ${count.index + 1}" > /var/www/html/index.html
              EOF
}

# 5. Attach EC2s to Target Group
resource "aws_lb_target_group_attachment" "attach" {
  count            = 2
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.app_server[count.index].id
  port             = 80
}

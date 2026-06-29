resource "aws_lb" "main" {
  name               = "capstone-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
  tags               = { Name = "capstone-alb" }
}

resource "aws_lb_target_group" "app" {
  name        = "capstone-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 15
    timeout             = 5
    matcher             = "200"
  }
  tags = { Name = "capstone-tg" }
}

# Green target group - CodeDeploy shifts traffic here during blue/green deploys
resource "aws_lb_target_group" "app_green" {
  name        = "capstone-tg-green"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 15
    timeout             = 5
    matcher             = "200"
  }
  tags = { Name = "capstone-tg-green" }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  # Defaults to blue; CodeDeploy rewrites this to green on each deploy,
  # so Terraform must not fight it back.
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  lifecycle {
    ignore_changes = [default_action]
  }
}

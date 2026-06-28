# ALB security group - open to the internet on port 80
resource "aws_security_group" "alb" {
  name        = "capstone-alb-sg"
  description = "Allow HTTP from internet to ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "capstone-alb-sg" }
}

# ECS security group - only the ALB can reach the tasks
resource "aws_security_group" "ecs" {
  name        = "capstone-ecs-sg"
  description = "Allow traffic from ALB to ECS tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "From ALB only"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "capstone-ecs-sg" }
}

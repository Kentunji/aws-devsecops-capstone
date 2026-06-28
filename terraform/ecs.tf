# --- IAM role: lets ECS pull the image + write logs ---
resource "aws_iam_role" "ecs_execution" {
  name = "capstone-ecs-execution"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_secrets" {
  name = "capstone-ecs-secrets"
  role = aws_iam_role.ecs_execution.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "secretsmanager:GetSecretValue"
      Resource = aws_secretsmanager_secret.db.arn
    }]
  })
}

# --- Log group for container logs ---
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/capstone-url-shortener"
  retention_in_days = 1
}

# --- ECS cluster ---
resource "aws_ecs_cluster" "main" {
  name = "capstone-cluster"
}

# --- Task definition ---
resource "aws_ecs_task_definition" "app" {
  family                   = "capstone-url-shortener"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([{
    name      = "app"
    image     = "${aws_ecr_repository.app.repository_url}:latest"
    essential = true
    portMappings = [{ containerPort = 8080, protocol = "tcp" }]

    environment = [
      { name = "DB_HOST", value = aws_db_instance.main.address },
      { name = "DB_NAME", value = "urlshortener" },
      { name = "DB_USER", value = "appuser" }
    ]

    secrets = [
      { name = "DB_PASSWORD", valueFrom = aws_secretsmanager_secret.db.arn }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.app.name
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

# --- ECS service (runs the tasks in PRIVATE subnets, behind the ALB) ---
resource "aws_ecs_service" "app" {
  name            = "capstone-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.http]
}

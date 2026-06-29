# --- Blue/Green via AWS CodeDeploy ---

# IAM role CodeDeploy assumes to orchestrate ECS blue/green shifts
resource "aws_iam_role" "codedeploy" {
  name = "capstone-codedeploy-ecs"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "codedeploy.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy" {
  role       = aws_iam_role.codedeploy.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

# CodeDeploy application (ECS compute platform)
resource "aws_codedeploy_app" "app" {
  name             = "capstone-app"
  compute_platform = "ECS"
}

# Deployment group: ties CodeDeploy to the ECS service, ALB listener,
# and the blue/green target groups. Auto-rolls back on a failed deploy.
resource "aws_codedeploy_deployment_group" "app" {
  app_name               = aws_codedeploy_app.app.name
  deployment_group_name  = "capstone-dg"
  service_role_arn       = aws_iam_role.codedeploy.arn
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    # Shift traffic to the green task set immediately on a successful deploy
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    # Terminate the old (blue) task set 5 minutes after cutover
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.main.name
    service_name = aws_ecs_service.app.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.http.arn]
      }

      target_group {
        name = aws_lb_target_group.app.name
      }

      target_group {
        name = aws_lb_target_group.app_green.name
      }
    }
  }
}

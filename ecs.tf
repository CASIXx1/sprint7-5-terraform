resource "aws_ecs_cluster" "project" {
  name = local.project_name
}

resource "aws_cloudwatch_log_group" "ecs" {
  name = "/ecs/${local.project_name}"
}

resource "aws_ecs_task_definition" "app" {
  family                   = local.project_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = local.project_name
      image     = "${aws_ecr_repository.app.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "DB_HOST"
          value = aws_db_instance.mysql.address
        },
        {
          name  = "DB_PORT"
          value = tostring(aws_db_instance.mysql.port)
        },
        {
          name  = "DB_NAME"
          value = local.db_name
        },
        {
          name  = "DB_USER"
          value = local.db_username
        },
        {
          name  = "DB_PASSWORD"
          value = local.db_password
        },
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = "ap-northeast-1"
          awslogs-stream-prefix = local.project_name
        }
      }
    }
  ])
}

resource "aws_ecs_service" "app" {
  name            = local.project_name
  cluster         = aws_ecs_cluster.project.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private_a.id, aws_subnet.private_c.id]
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = local.project_name
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener.http,
  ]
}

resource "aws_appautoscaling_target" "ecs_service" {
  min_capacity       = 2
  max_capacity       = 4
  resource_id        = "service/${aws_ecs_cluster.project.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_cpu" {
  name               = "${local.project_name}-cpu-70"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_service.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_service.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 70

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

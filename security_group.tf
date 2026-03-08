resource "aws_security_group" "ecs_instances" {
  name   = "${local.project_name}-ecs-instances"
  vpc_id = aws_vpc.project.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.project_name}-ecs-instances"
  }
}

resource "aws_security_group" "ecs_tasks" {
  name   = "${local.project_name}-ecs-tasks"
  vpc_id = aws_vpc.project.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.project_name}-ecs-tasks"
  }
}

resource "aws_security_group" "rds" {
  name   = "${local.project_name}-rds"
  vpc_id = aws_vpc.project.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  tags = {
    Name = "${local.project_name}-rds"
  }
}

resource "aws_security_group" "alb" {
  name   = "${local.project_name}-alb"
  vpc_id = aws_vpc.project.id

  ingress {
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

  tags = {
    Name = "${local.project_name}-alb"
  }
}

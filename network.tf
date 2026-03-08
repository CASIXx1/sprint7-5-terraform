resource "aws_vpc" "project" {
  cidr_block           = "10.0.0.0/16"

  tags = {
    Name = local.project_name
  }
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.project.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "${local.project_name}-public-a"
  }
}

resource "aws_subnet" "public_c" {
  vpc_id            = aws_vpc.project.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "${local.project_name}-public-c"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.project.id
  cidr_block        = "10.0.17.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "${local.project_name}-private-a"
  }
}

resource "aws_subnet" "private_c" {
  vpc_id            = aws_vpc.project.id
  cidr_block        = "10.0.18.0/24"
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "${local.project_name}-private-c"
  }
}

resource "aws_internet_gateway" "project" {
  vpc_id = aws_vpc.project.id

  tags = {
    Name = local.project_name
  }
}

resource "aws_eip" "nat_gateway" {
  domain = "vpc"

  tags = {
    Name = "${local.project_name}-nat-gateway"
  }
}

resource "aws_nat_gateway" "public_a" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "${local.project_name}-public-a"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.project.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.project.id
  }

  tags = {
    Name = "${local.project_name}-public"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.project.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.public_a.id
  }

  tags = {
    Name = "${local.project_name}-private"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_c" {
  subnet_id      = aws_subnet.public_c.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_c" {
  subnet_id      = aws_subnet.private_c.id
  route_table_id = aws_route_table.private.id
}

resource "aws_lb" "public" {
  name               = local.project_name
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_c.id]

  tags = {
    Name = local.project_name
  }
}

resource "aws_lb_target_group" "app" {
  name        = local.project_name
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.project.id

  health_check {
    path = "/health"
  }

  tags = {
    Name = local.project_name
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.public.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

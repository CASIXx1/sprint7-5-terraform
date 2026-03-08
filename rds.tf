resource "aws_db_subnet_group" "private" {
  name = local.project_name

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_c.id,
  ]

  tags = {
    Name = local.project_name
  }
}

resource "aws_db_instance" "mysql" {
  identifier = local.project_name

  engine         = "mysql"
  instance_class = "db.t3.micro"

  allocated_storage     = 20
  db_name               = local.db_name
  db_subnet_group_name  = aws_db_subnet_group.private.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  username = local.db_username
  password = local.db_password

  multi_az            = false
  skip_final_snapshot = true

  tags = {
    Name = local.project_name
  }
}

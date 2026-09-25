# RDS Database Subnet Group
resource "aws_db_subnet_group" "main" {
  name = "${var.project_name}-db-subnet-group"

  subnet_ids = [
    aws_subnet.database_a.id,
    aws_subnet.database_b.id
  ]

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}


# PostgreSQL RDS Database
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-database"

  engine         = "postgres"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = "innovatech"
  username = var.db_username
  password = var.db_password
  port     = 5432

  db_subnet_group_name = aws_db_subnet_group.main.name

  vpc_security_group_ids = [
    aws_security_group.database.id
  ]

  publicly_accessible = false
  multi_az            = false

  backup_retention_period = 1

  skip_final_snapshot = true

  tags = {
    Name = "${var.project_name}-database"
  }
}
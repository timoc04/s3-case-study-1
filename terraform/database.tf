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
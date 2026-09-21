# VPC
output "vpc_id" {
  description = "ID of the Innovatech VPC"
  value       = aws_vpc.main.id
}


# Public Subnets
output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]
}


# Private Web Subnets
output "web_subnet_ids" {
  description = "IDs of the private web subnets"
  value = [
    aws_subnet.web_a.id,
    aws_subnet.web_b.id
  ]
}


# Private Database Subnets
output "database_subnet_ids" {
  description = "IDs of the private database subnets"
  value = [
    aws_subnet.database_a.id,
    aws_subnet.database_b.id
  ]
}


# Internet Gateway
output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}


# NAT Gateway
output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = aws_nat_gateway.main.id
}

output "nat_gateway_public_ip" {
  description = "Public IP address used by the NAT Gateway"
  value       = aws_eip.nat.public_ip
}


# Route Tables
output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "web_private_route_table_id" {
  description = "ID of the private web route table"
  value       = aws_route_table.web_private.id
}

output "database_private_route_table_id" {
  description = "ID of the private database route table"
  value       = aws_route_table.database_private.id
}


# Security Groups
output "alb_security_group_id" {
  description = "ID of the Application Load Balancer Security Group"
  value       = aws_security_group.alb.id
}

output "web_security_group_id" {
  description = "ID of the Web Server Security Group"
  value       = aws_security_group.web.id
}

output "database_security_group_id" {
  description = "ID of the Database Security Group"
  value       = aws_security_group.database.id
}
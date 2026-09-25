variable "aws_region" {
  description = "AWS region used for the infrastructure"
  default     = "eu-central-1"
}

variable "vpc_cidr" {
  description = "CIDR range of the Innovatech VPC"
  default     = "10.0.0.0/16"
}

variable "project_name" {
  description = "Name used for AWS resources"
  default     = "innovatech-cs1"
}


variable "db_username" {
  description = "Administrator username for the PostgreSQL database"
  type        = string
  default     = "dbadmin"
}

variable "db_password" {
  description = "Administrator password for the PostgreSQL database"
  type        = string
  sensitive   = true
}
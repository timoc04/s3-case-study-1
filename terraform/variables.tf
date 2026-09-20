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
resource "aws_subnet" "monitoring" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.60.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-monitoring-subnet"
  }
}

resource "aws_route_table_association" "monitoring" {
  subnet_id      = aws_subnet.monitoring.id
  route_table_id = aws_route_table.web_private.id
}

resource "aws_security_group" "monitoring" {
  name        = "${var.project_name}-monitoring-sg"
  description = "Security group for the private monitoring platform"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "Allow outbound connectivity"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-monitoring-sg"
  }
}

resource "aws_iam_role" "monitoring_ssm" {
  name = "${var.project_name}-monitoring-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "ec2.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "monitoring_ssm" {
  role       = aws_iam_role.monitoring_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "monitoring" {
  name = "${var.project_name}-monitoring-instance-profile"
  role = aws_iam_role.monitoring_ssm.name
}

resource "aws_instance" "monitoring" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.medium"
  subnet_id                   = aws_subnet.monitoring.id
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.monitoring.name

  vpc_security_group_ids = [
    aws_security_group.monitoring.id
  ]

  root_block_device {
    volume_size = 40
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  depends_on = [
    aws_iam_role_policy_attachment.monitoring_ssm,
    aws_route_table_association.monitoring
  ]

  tags = {
    Name = "${var.project_name}-monitoring"
    Role = "monitoring"
  }
}
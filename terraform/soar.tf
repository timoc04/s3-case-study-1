# Dedicated private subnet for the SOAR platform
resource "aws_subnet" "soar" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.50.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-soar-subnet"
  }
}

# Reuse the existing private route table and NAT Gateway
resource "aws_route_table_association" "soar" {
  subnet_id      = aws_subnet.soar.id
  route_table_id = aws_route_table.web_private.id
}

# No inbound access during initial platform preparation
resource "aws_security_group" "soar" {
  name        = "${var.project_name}-soar-sg"
  description = "Security group for the private SOAR platform"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "Allow outbound connectivity"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-soar-sg"
  }
}

# Dedicated IAM role for Systems Manager
resource "aws_iam_role" "soar_ssm" {
  name = "${var.project_name}-soar-ssm-role"

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

resource "aws_iam_role_policy_attachment" "soar_ssm" {
  role       = aws_iam_role.soar_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "soar" {
  name = "${var.project_name}-soar-instance-profile"
  role = aws_iam_role.soar_ssm.name
}

# Dedicated SOAR host
resource "aws_instance" "soar" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.small"
  subnet_id                   = aws_subnet.soar.id
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.soar.name

  vpc_security_group_ids = [
    aws_security_group.soar.id
  ]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  depends_on = [
    aws_iam_role_policy_attachment.soar_ssm,
    aws_route_table_association.soar
  ]

  tags = {
    Name = "${var.project_name}-soar"
    Role = "soar"
  }
}
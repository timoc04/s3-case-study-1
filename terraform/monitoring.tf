# CloudWatch Agent permissions for the web servers
resource "aws_iam_role" "web_cloudwatch_role" {
  name = "innovatech-cs1-web-cloudwatch-role"

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

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.web_cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "web_cloudwatch_profile" {
  name = "innovatech-cs1-web-cloudwatch-profile"
  role = aws_iam_role.web_cloudwatch_role.name
}
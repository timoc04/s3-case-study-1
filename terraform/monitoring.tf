# CloudWatch Agent permissions for the web servers
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.web_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}
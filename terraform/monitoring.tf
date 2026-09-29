# CloudWatch Agent permissions for the web servers
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.web_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}


# High CPU utilisation alarm for the Auto Scaling Group
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-high-cpu"
  alarm_description   = "Triggers when average CPU utilisation of the web tier exceeds 80 percent"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 80
  period              = 60
  statistic           = "Average"

  namespace   = "AWS/EC2"
  metric_name = "CPUUtilization"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }

  treat_missing_data = "notBreaching"
}


# Unhealthy target alarm for the Application Load Balancer
resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  alarm_name          = "${var.project_name}-unhealthy-targets"
  alarm_description   = "Triggers when one or more web server targets become unhealthy"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 0
  period              = 60
  statistic           = "Maximum"

  namespace   = "AWS/ApplicationELB"
  metric_name = "UnHealthyHostCount"

  dimensions = {
    LoadBalancer = aws_lb.web.arn_suffix
    TargetGroup  = aws_lb_target_group.web.arn_suffix
  }

  treat_missing_data = "notBreaching"
}
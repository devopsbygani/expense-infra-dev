resource "aws_ssm_parameter" "app_lb_listener_arn" {
  name  = "/${var.project_name}/${var.environment}/app_lb_listener_arn"
  type  = "String"
  value = aws_lb_listener.http.arn
}
locals {
    resource_name = "${var.project_name}-${var.environment}-frontend"
    frontend_sg_id = data.aws_ssm_parameter.frontend_sg_id.value
    vpc_id = data.aws_ssm_parameter.vpc_id.value
}

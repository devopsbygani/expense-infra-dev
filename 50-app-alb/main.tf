module "alb" {
  source = "terraform-aws-modules/alb/aws"
  internal = true  #load balancer is only dedicated to ineternal connection between resources.

  name    = "${local.resource_name}-app-alb" #expense-dev-app-alb
  vpc_id  = local.vpc_id
  subnets = [local.private_subnet_id]
  security_groups = [local.security_group_id]
  create_security_group = false
  enable_deletion_protection = false

  tags = merge(
    var.common_tags,
    var.app_alb_tags
    )
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = module.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "<h1>Hello, I am from Application ALB</h1>"
      status_code  = "200"
    }
  }
}

module "records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"

  zone_name = var.zone_name

  records = [
    {
      name    = "*.app-${var.environment}"
      type    = "A"
      ttl     = 1
      alias   = {
        name    = module.alb.dns_name
        zone_id = module.alb.zone_id
      }
      allow_overwrite = true
    },
  ]
}
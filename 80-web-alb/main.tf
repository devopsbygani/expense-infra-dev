module "alb" {
  source = "terraform-aws-modules/alb/aws"
  internal = false  

  name    = "${local.resource_name}-web-alb" #expense-dev-web-alb
  vpc_id  = local.vpc_id
  subnets = local.public_subnet_ids
  security_groups = [local.security_group_id]
  create_security_group = false
  enable_deletion_protection = false

  tags = merge(
    var.common_tags,
    var.web_alb_tags
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
      message_body = "<h1>Hello, I am from web Application ALB</h1>"
      status_code  = "200"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = module.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = local.https_certificate_arn
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "<h1>Hello, I am from web Application ALB HTTPS</h1>"
      status_code  = "200"
    }
  }
}

module "records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"

  zone_name = var.zone_name

  records = [
    {
      name    = "expense-${var.environment}" #expense-dev.devgani.online
      type    = "A"
      alias   = {
        name    = module.alb.dns_name
        zone_id = module.alb.zone_id   # This belongs ALB internal hosted zone, not ours
      }
      allow_overwrite = true
    },
  ]
}

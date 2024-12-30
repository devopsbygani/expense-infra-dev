module "mysql_sg" {
    # source = "git::https://example.com/vpc.git?ref=main" # to call module from git
    source = "../../terraform-aws-security-group"
    project_name = var.project_name
    environment = var.environment
    vpc_id = local.vpc_id
    sg_name = "mysql"   
}

module "backend_sg" {
    source = "../../terraform-aws-security-group"
    project_name = var.project_name
    environment = var.environment
    vpc_id = local.vpc_id
    sg_name = "backend"   
}

module "frontend_sg" {
    source = "../../terraform-aws-security-group"
    project_name = var.project_name
    environment = var.environment
    vpc_id = local.vpc_id
    sg_name = "frontend"   
}

module "bastion_sg" {
    source = "../../terraform-aws-security-group"
    project_name = var.project_name
    environment = var.environment
    vpc_id = local.vpc_id
    sg_name = "bastion"   
}

module "ansible_sg" {
    source = "../../terraform-aws-security-group"
    project_name = var.project_name
    environment = var.environment
    vpc_id = local.vpc_id
    sg_name = "ansible"   
}

module "app_alb_sg" {
    source = "../../terraform-aws-security-group"
    project_name = var.project_name
    environment = var.environment
    vpc_id = local.vpc_id
    sg_name = "app-alb"   
}

module "vpn_sg" {
    source = "../../terraform-aws-security-group"
    project_name = var.project_name
    environment = var.environment
    vpc_id = local.vpc_id
    sg_name = "vpn"   
}

#  to allow connection between mysql to backend.
#  the port 3306 to be enabled . port 8080 for backend. and port 80 for frontend. 
#  to accept connections.
#  these are to added in inbound rules.

resource "aws_security_group_rule" "mysql_backend" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  source_security_group_id = module.backend_sg.id
  security_group_id = module.mysql_sg.id
#   source_security_group_id = [data.aws_ssm_parameter.backend_sg_id.value]
#   security_group_id = data.aws_ssm_parameter.mysql_sg_id.value
}

# resource "aws_security_group_rule" "backend_frontend" {
#   type              = "ingress"
#   from_port         = 8080
#   to_port           = 8080
#   protocol          = "tcp"
#   source_security_group_id = module.frontend_sg.id
#   security_group_id = module.backend_sg.id
# }

# resource "aws_security_group_rule" "frontend_public" {
#   type              = "ingress"
#   from_port         = 80
#   to_port           = 80
#   protocol          = "tcp"
#   cidr_blocks       = ["0.0.0.0/0"]
#   security_group_id = module.frontend_sg.id
# }


resource "aws_security_group_rule" "mysql_bastion" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  source_security_group_id = module.bastion_sg.id
  security_group_id = module.mysql_sg.id
}

resource "aws_security_group_rule" "backend_bastion" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  source_security_group_id = module.bastion_sg.id
  security_group_id = module.backend_sg.id
}


resource "aws_security_group_rule" "frontend_bastion" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  source_security_group_id = module.bastion_sg.id
  security_group_id = module.frontend_sg.id
}

resource "aws_security_group_rule" "bastion_public" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.bastion_sg.id
}

# ansible 

# resource "aws_security_group_rule" "mysql_ansible" {
#   type              = "ingress"
#   from_port         = 22
#   to_port           = 22
#   protocol          = "tcp"
#   source_security_group_id = module.ansible_sg.id
#   security_group_id = module.mysql_sg.id
# }

resource "aws_security_group_rule" "backend_ansible" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  source_security_group_id = module.ansible_sg.id
  security_group_id = module.backend_sg.id
}

resource "aws_security_group_rule" "frontend_ansible" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  source_security_group_id = module.ansible_sg.id
  security_group_id = module.frontend_sg.id
}

resource "aws_security_group_rule" "ansible_public" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.ansible_sg.id
}

#backend security group servers accept connecction from app_load balancer on port 8080
resource "aws_security_group_rule" "backend_app_alb" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  source_security_group_id = module.app_alb_sg.id
  security_group_id = module.backend_sg.id
}

resource "aws_security_group_rule" "app_alb_bastion" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  source_security_group_id = module.bastion_sg.id
  security_group_id = module.app_alb_sg.id
}
# vpn sg accepts connection from public on port 22,443,943,1194.
resource "aws_security_group_rule" "vpn_public" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.vpn_sg.id
}

resource "aws_security_group_rule" "vpn_public_443" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.vpn_sg.id
}

resource "aws_security_group_rule" "vpn_public_943" {
  type              = "ingress"
  from_port         = 943
  to_port           = 943
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.vpn_sg.id
}

resource "aws_security_group_rule" "vpn_public_1194" {
  type              = "ingress"
  from_port         = 1194
  to_port           = 1194
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.vpn_sg.id
}

resource "aws_security_group_rule" "app_alb_vpn" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  source_security_group_id = module.vpn_sg.id
  security_group_id = module.app_alb_sg.id
}

resource "aws_security_group_rule" "backend_vpn" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  source_security_group_id = module.vpn_sg.id
  security_group_id = module.backend_sg.id
}

resource "aws_security_group_rule" "backend_vpn_8080" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  source_security_group_id = module.vpn_sg.id
  security_group_id = module.backend_sg.id
}


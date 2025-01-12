# 1. create an instance.
# 2. configure frontend.
# 3. stop the instance.
# 4. create ami image.
# 5. delete the instance.
# 6. create target group. and launch template. #done till here on 8 jan
# 7. create auto scaling group.
# 8. create auto scaling policy.
# 9. create a load balancer rule.
# creating instance
module "frontend" {
  source  = "terraform-aws-modules/ec2-instance/aws"  #open source module for instance creation.

  name = local.resource_name
  ami = data.aws_ami.joindevops.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [local.frontend_sg_id]
  subnet_id              = local.public_subnet_id
  tags = merge(var.common_tags,var.frontend_tags,
  {
    Name = local.resource_name
  }
  )
}
#configuring the frontend instance 

resource "null_resource" "frontend" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    instance_id = module.frontend.id
  }

  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    host = module.frontend.private_ip
    type = "ssh"
    user = "ec2-user"
    password = "DevOps321"
  }

  provisioner "file" {
    content     = "${var.frontend_tags.component}.sh"
    destination = "/tmp/frontend.sh"
  }

  provisioner "remote-exec" {
    # Bootstrap script called with private_ip of each node in the cluster
    inline = [
      "chmod +x /tmp/frontend.sh",
      "sudo sh /tmp/frontend.sh ${var.frontend_tags.component} ${var.environment}",
    ]
  }
}

resource "aws_ec2_instance_state" "frontend" {
  instance_id = module.frontend.id
  state       = "stopped"
  depends_on = [null_resource.frontend]
}

resource "aws_ami_from_instance" "frontend" {
  name               = local.resource_name
  source_instance_id = module.frontend.id
  depends_on = [aws_ec2_instance_state.frontend]
}

resource "null_resource" "frontend_delete" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    instance_id = module.frontend.id
  }
  provisioner "local-exec" {
    # Bootstrap script called with private_ip of each node in the cluster
    command = "aws ec2 terminate-instances --instance-ids ${module.frontend.id}"
    
  }
  depends_on = [aws_ami_from_instance.frontend]
}

resource "aws_lb_target_group" "frontend" {
  name     = local.resource_name
  port     = 80
  protocol = "HTTP"
  vpc_id   = local.vpc_id

  health_check {
    healthy_threshold = 2             # to check the nodes for 2 consecutive times.
    unhealthy_threshold = 2           # if it is not responded for 2 times then consider as unhealthy
    interval = 5                      # at every 5 sec interval healthcheck will process.
    matcher = "200-299"               #  the http success code.
    path = "/"                        
    port = 80                         
    protocol = "HTTP"
    timeout = 4                       # if server not resposnded within 4 sec consider as failure
  }
}

resource "aws_launch_template" "frontend" {
  name = local.resource_name
  image_id = aws_ami_from_instance.frontend.id
  instance_initiated_shutdown_behavior = "terminate"
  instance_type = "t2.micro"
  update_default_version = true
  vpc_security_group_ids = [local.frontend_sg_id]
  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = local.resource_name
    }
  }
}

resource "aws_autoscaling_group" "frontend" {
  name                      = local.resource_name
  max_size                  = 10
  min_size                  = 2
  health_check_grace_period = 100
  health_check_type         = "ELB"
  desired_capacity          = 2
  vpc_zone_identifier       = [local.public_subnet_id]
  target_group_arns = [aws_lb_target_group.frontend.arn]

  launch_template {
    id      = aws_launch_template.frontend.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
    triggers = ["launch_template"]
  }

  
  tag {
    key                 = "name"
    value               = "frontend"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }

  tag {
    key                 = "project"
    value               = "expense"
    propagate_at_launch = false
    }
}

resource "aws_autoscaling_policy" "frontend" {
  autoscaling_group_name = aws_autoscaling_group.frontend.name
  name                   = local.resource_name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 70.0
  }
}

resource "aws_lb_listener_rule" "frontend" {
  listener_arn = local.web_lb_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

  condition {
    host_header {
      values = ["${var.project_name}-${var.environment}.${var.zone_name}"] #expense-dev.devgani.online
    }
  }
}


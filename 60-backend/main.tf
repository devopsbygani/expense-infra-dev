# 1. create an ec2-instance, 2.install backend setup, 3.stop the instance, 4.take AMI of the server. 5. delete the instance.
#create instance through module.

module "backend" {
  source  = "terraform-aws-modules/ec2-instance/aws"  #open source module for instance creation.

  name = local.resource_name
#   key_name = aws_key_pair.openvpn.key_name (we are using local setup.)
  ami = data.aws_ami.joindevops.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [local.backend_sg_id]
  subnet_id              = local.private_subnet_id
  tags = merge(var.common_tags,var.backend_tags,
  {
    Name = local.resource_name
  }
  )
}

resource "null_resource" "backend" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    instance_ids = module.backend.id  # this will trigger when instance id changes.
  }

  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    host = module.backend.private_ip
    type = "ssh"
    user = "ec2-user"
    password = "DevOps321"
  }

   provisioner "file" {
        source      = "${var.backend_tags.component}.sh"
        destination = "/tmp/backend.sh"
    }
  provisioner "remote-exec" {
    # Bootstrap script called with private_ip of each node in the cluster
    inline = [
      "chmod +x /tmp/backend.sh ",
      "sudo sh /tmp/backend.sh ${var.backend_tags.component} ${var.environment}",
    ]
  }
}

resource "aws_ec2_instance_state" "backend" {
  instance_id = module.backend.id
  state       = "stopped"
  depends_on = [null_resource.backend]
}

resource "aws_ami_from_instance" "backend" {
  name               = local.resource_name
  source_instance_id = module.backend.id
  depends_on = [aws_ec2_instance_state.backend]
}

resource "null_resource" "backend_delete" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    instance_ids = module.backend.id  # this will trigger when instance id changes.
  }
  
  provisioner "local-exec" {
    # Bootstrap script called with private_ip of each node in the cluster
    command = "aws ec2 terminate-instances --instance-ids ${module.backend.id}"
    
  }
 depends_on = [aws_ami_from_instance.backend] 
}

# creating target group.
resource "aws_lb_target_group" "backend" {
  name     = local.resource_name
  port     = 8080
  protocol = "HTTP"
  vpc_id   = local.vpc_id

  health_check {
    healthy_threshold = 2        # check the target nodes 2 conxecutive times.
    unhealthy_threshold = 2      # if failed continously 2 time consider as unhealtthy node.
    interval = 5                 # every 5 sec it will do health check.
    matcher = "200-299"        # sucess codes 
    path = "/health"         # health check path
    port = 8080             # tagert group instance port for tarffic 
    protocol = "HTTP"      
    timeout  = 4            # if server not resposnded within 4 sec consider as failure.

  }
}

resource "aws_launch_template" "backend" {
  name = local.resource_name
  image_id = aws_ami_from_instance.backend.id
  instance_initiated_shutdown_behavior = "terminate"
  instance_type = "t2.micro"
  vpc_security_group_ids = [local.backend_sg_id]
  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = local.resource_name
    }
  }
}

resource "aws_autoscaling_group" "backend" {
  name                      = local.resource_name
  max_size                  = 10
  min_size                  = 2
  health_check_grace_period = 100
  health_check_type         = "ELB"
  desired_capacity          = 2
  target_group_arns = [aws_lb_target_group.backend.arn]
  launch_template {
    id      = aws_launch_template.backend.id
    version = "$Latest"
  }
  
  vpc_zone_identifier       = [local.private_subnet_id]

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
    triggers = ["launch_template"]
  }


  tag {
    key                 = "name"
    value               = "backend"
    propagate_at_launch = true
  }
# to delete the instanace if the instance is not healthy for more than 15 m
  timeouts {
    delete = "15m"
  }

  tag {
    key                 = "project"
    value               = "expense"
    propagate_at_launch = false
  }
}

resource "aws_autoscaling_policy" "backend" {
  # ... other configuration ...
  autoscaling_group_name = aws_autoscaling_group.backend.name
  name                   = local.resource_name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 70.0
  }
}

resource "aws_lb_listener_rule" "backend" {
  listener_arn = local.app_alb_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    host_header {
      values = ["${var.backend_tags.component}.app-${var.environment}.${var.zone_name}"]  # backend.app-dev.devgani.online
    }
  }
}


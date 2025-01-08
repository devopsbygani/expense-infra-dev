# 1. create an instance.
# 2. configure frontend.
# 3. stop the instance.
# 4. create ami image.
# 5. delete the instance.
# 6. create target group.
# 7. create auto scling group.
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
      "sudo sh /tmp/backend.sh ${var.frontend_tags.component} ${var.environment}",
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

resource "null_resource" "frontend" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    instance_id = module.frontend.id
  }
  provisioner "local-exec" {
    # Bootstrap script called with private_ip of each node in the cluster
    command = "aws ec2 terminate-instances --instance-ids ${module.frontend.id}",
    
  }
  depends_on = [aws_ami_from_instance.frontend]
}

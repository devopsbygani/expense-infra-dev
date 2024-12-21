# 1. create an ec2-instance, 2.install backend setup, 3.stop the instance, 4.take AMI of the server. 5. delete the instance.
#create instance through module.

module "backend" {
  source  = "terraform-aws-modules/ec2-instance/aws"  #open source module for instance creation.

  name = local.resource_name
#   key_name = aws_key_pair.openvpn.key_name (we are using local setup.)
  ami = data.aws_ami.joindevops.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [local.vpn_sg_id]
  subnet_id              = local.private_subnet_id
  tags = merge(var.common_tags,var.backend_tags,
  {
    Name = local.resource_name
  }
  )
}

resource "null_resource" "cluster" {
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
        source      = "${var.backend_tags.Component}.sh"
        destination = "/tmp/backend.sh"
    }
  provisioner "remote-exec" {
    # Bootstrap script called with private_ip of each node in the cluster
    command = [
      "chmod +x /tmp/backend.sh ",
      "sudo sh /tmp/backend.sh ${var.backend_tags.Component} ${var.environment}",
    ]
  }
}


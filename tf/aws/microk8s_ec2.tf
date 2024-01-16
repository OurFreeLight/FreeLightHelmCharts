# tf/aws/microk8s_ec2.tf

data "template_file" "microk8s_startup_script" {
  count    = var.backend_deployment_type == "vm" ? (var.k8s_type == "microk8s" ? 1 : 0) : 0

  template = join ("\n", [
      file("../scripts/ubuntu-22.04/setup-vm.sh"),
      file("../scripts/ubuntu-22.04/install-microk8s.tpl"),
      file("../scripts/ubuntu-22.04/install-helm.sh"),
      file("../scripts/ubuntu-22.04/install-kubectl.sh"),
      file("../scripts/ubuntu-22.04/finish-vm.sh")
    ])

  vars = {
    k8s_version = var.k8s_version
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_security_group" "freelight_security_group" {
  name        = "${var.domain}_freelight_security_group"
  count       = var.backend_deployment_type == "vm" ? (var.k8s_type == "microk8s" ? 1 : 0) : 0
  description = "Allow ports 80, 443, and 16443"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 16443
    to_port     = 16443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "freelight_instance" {
  count                   = var.backend_deployment_type == "vm" ? (var.k8s_type == "microk8s" ? 1 : 0) : 0
  ami                     = data.aws_ami.ubuntu.id
  instance_type           = var.aws_vm_instance_type
  security_groups         = [aws_security_group.freelight_security_group[0].name]
  disable_api_termination = var.delete_protection

  user_data               = data.template_file.microk8s_startup_script[0].rendered

  key_name                = var.aws_key_pair_name

  root_block_device {
    volume_size           = var.aws_storage_size
  }

  tags = {
    Name                  = "Freelight"
  }
}

data "aws_eip" "freelight_eip" {
  filter {
    name   = "tag:Name"
    values = [var.api_static_ip_name]
  }
  count = var.api_static_ip_name != "" ? 1 : 0
}

resource "aws_eip_association" "freelight_eip_association" {
  count         = var.backend_deployment_type == "vm" ? (var.api_static_ip_name != "" ? 1 : 0) : 0
  instance_id   = aws_instance.freelight_instance[0].id
  allocation_id = data.aws_eip.freelight_eip[0].id
}

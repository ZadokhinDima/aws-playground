variable "dockerhub_username" {
  description = "DockerHub username"
}

variable "dockerhub_password" {
  description = "DockerHub password"
  sensitive   = true
}

variable "image_repo" {
  description = "Repo url in dockerhub"
}

variable "image_tag" {
  description = "Image tag to deploy"
}

provider "aws" {
  region = "eu-north-1"
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow inbound SSH"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "app" {
  count         = 2
  ami           = "ami-0c0e147c706360bd7" # Amazon Linux 2023 AMI 2023.4.20240611.0 x86_64 HVM kernel-6.1
  instance_type = "t3.micro"

  tags = {
    Name = "AppInstance-${count.index + 1}"
  }

  key_name = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
}

resource "aws_elb" "app_lb" {
  name               = "app-lb"
  availability_zones = ["eu-north-1a", "eu-north-1b"]
  
  listener {
    instance_port     = 5000
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }

  health_check {
    target              = "HTTP:5000/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  instances = aws_instance.app.*.id

  tags = {
    Name = "AppLoadBalancer"
  }
}

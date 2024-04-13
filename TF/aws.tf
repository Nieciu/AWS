resource "aws_vpc" "project" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.project.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.availability_zone
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.project.id
}

resource "aws_route_table" "routes" {
  vpc_id = aws_vpc.project.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }
}

resource "aws_route_table_association" "name" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.routes.id
}

resource "aws_security_group" "sg" {
  name        = "allow_traffic"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.project.id
}

resource "aws_vpc_security_group_ingress_rule" "ingress_SSH" {
  security_group_id = aws_security_group.sg.id
  description       = "SSH to VPC"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "jenkins-server" {
    security_group_id = aws_security_group.sg.id
    description       = "Jenkins server"
    from_port         = 8080
    to_port           = 8080
    ip_protocol       = "tcp"
    cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "egress_all" {
  security_group_id = aws_security_group.sg.id
  description       = "Allow all traffic"
  from_port         = 0
  to_port           = 0
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_network_interface" "nic" {
  subnet_id       = aws_subnet.public_subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.sg.id]
}

resource "aws_eip" "eip-1" {
  network_interface         = aws_network_interface.nic.id
  associate_with_private_ip = "10.0.1.50"

  depends_on = [aws_internet_gateway.gateway]
}

resource "aws_key_pair" "jenkins-key" {
  key_name   = "jenkins-key"
  public_key = file("~/.ssh/my-key.pub")
}

resource "aws_instance" "ubuntu" {
  ami               = "ami-0b9932f4918a00c4f"
  instance_type     = "t2.micro"
  availability_zone = var.availability_zone
  key_name          = aws_key_pair.jenkins-key.key_name

  network_interface {
    network_interface_id = aws_network_interface.nic.id
    device_index         = 0
  }

  user_data = <<-EOF
                #!/bin/bash
                wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key |sudo gpg --dearmor -o /usr/share/keyrings/jenkins.gpg
                sudo sh -c 'echo deb [signed-by=/usr/share/keyrings/jenkins.gpg] http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
                sudo apt update
                sudo apt install default-jre -y
                sudo apt install jenkins -y
                sudo systemctl start jenkins.service
                EOF
}

output "public_ip" {
  value = aws_instance.ubuntu.public_ip
}
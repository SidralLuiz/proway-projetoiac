data "aws_ami" "imagem_ec2" {
    most_recent = true
    owners = [ "amazon" ]
    filter {
      name = "name"
      values = [ "al2023-ami-2023.*-x86_64" ]
    }
}


resource "aws_security_group" "sidral_nginx_sg" {
    vpc_id = var.vpc_id
    name = "sidral_nginx_sg"
    tags = {
      Name = "sidral-nginx_sg"
    }
}

resource "aws_vpc_security_group_egress_rule" "sidral_egress_sg_rule" {
  security_group_id = aws_security_group.sidral_nginx_sg.id
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
} 

resource "aws_vpc_security_group_ingress_rule" "sidral_ingress_80_sg_rule" {
  security_group_id = aws_security_group.sidral_nginx_sg.id
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80
}
resource "aws_vpc_security_group_ingress_rule" "sidral_ingress_22_sg_rule" {
  security_group_id = aws_security_group.sidral_nginx_sg.id
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port   = 22
  to_port     = 22
}

resource "aws_network_interface" "sidral_nginx_ei" {
  subnet_id = var.sn_pub01
  tags = {
    Name = "sidral_nginx_ei"
  }
}

resource "aws_instance" "sidral_nginx_ec2" {
  instance_type = "t3.micro"
  ami = data.aws_ami.imagem_ec2.id
  subnet_id = var.sn_pub01
  vpc_security_group_ids = [ aws_security_group.sidral_nginx_sg.id ]
  key_name = aws_key_pair.lb_ssh_key_pair.key_name
  associate_public_ip_address = true
  tags = {
    Name = "sidral-nginx_ec2"
  }
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    amazon-linux-extras install nginx1 -y
    systemctl start nginx
    systemctl enable nginx
    echo "<h1>Olá, Mundo!</h1>" > /usr/share/nginx/html/index.html
  EOF
}

# Criacao da chave SSH que sera usada para conexao na instancia
resource "tls_private_key" "lb_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
resource "aws_key_pair" "lb_ssh_key_pair" {
  key_name   = "sidral_key_pair"
  public_key = tls_private_key.lb_ssh_key.public_key_openssh
}

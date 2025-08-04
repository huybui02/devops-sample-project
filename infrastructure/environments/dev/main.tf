module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.env}-${var.vpc_name}"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  public_subnets  = var.public_subnets
  private_subnets = []

  enable_nat_gateway = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, { Environment = var.env })
}

resource "aws_security_group" "ec2_sg" {
  name        = "${var.env}-ec2-ssh-app" 
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["123.123.123.123/0"] # assume that it's my public IP
  }

  ingress {
    description = "App port 5000"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["123.123.123.123/0"] # assume that it's my public IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Environment = var.env })


}


# Generate key pair (private/public)
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content              = tls_private_key.ec2_key.private_key_pem
  filename             = "${path.module}/keys/id_rsa"
  file_permission      = "0600"
  directory_permission = "0700"
}

resource "aws_key_pair" "default" {
  key_name   = "${var.env}-ec2-keypair"
  public_key = tls_private_key.ec2_key.public_key_openssh
}

module "ec2_instances" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.0"

  for_each = toset(["one", "two"])

  name = "${var.env}-instance-${each.key}"
  ami           = var.ami_id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.default.key_name

  subnet_id = element(module.vpc.public_subnets, 0)
  vpc_security_group_ids = [module.vpc.default_security_group_id]

  associate_public_ip_address = true
  
  tags = merge(var.tags, { Environment = var.env })
}
variable "aws_region" {
  default = "ap-southeast-1"
}

variable "vpc_name" {
  default = "my-vpc"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "availability_zones" {
  type    = list(string)
  default = ["ap-southeast-1a", "ap-southeast-1b"]
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "ami_id" {
  description = "AMI ID for EC2 (e.g., Ubuntu)"
  type        = string
}

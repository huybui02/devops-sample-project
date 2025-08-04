output "ec2_public_ips" {
  value = {
    for k, v in module.ec2_instances : k => v.public_ip
  }
}

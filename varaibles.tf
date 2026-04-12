variable "ssh_password" {
    description = "SSH password for ec2-user to run destroy-time provisioner"
    type        = string
    sensitive   = true
}
data "aws_ami" "main" {
  owners      = ["973714476881"]
  most_recent = true

  filter {
    name   = "name"
    values = ["Redhat-9-DevOps-Practice"]
  }

}

data "aws_iam_role" "eks" {
  name = "ec2-admin-role"
}
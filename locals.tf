locals {
  ami_id = "ami-0220d79f3f480ecf5"
  vpc_id = "vpc-09a41345760c9fd3e"
  sg_id  = "sg-02a915d53f8e3507f"
  iam_role = data.aws_iam_role.eks.name
}
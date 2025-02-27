# Get the latest RHEL 9.4 ami for the region 
data "aws_ami" "rhel9-ami-latest" {
  owners      = ["309956199498"]
  most_recent = true

  filter {
    name   = "name"
    values = ["RHEL-9.4.*_HVM*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_vpc" "my-default" {}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone
data "aws_route53_zone" "my_aws_dns_zone" {
  name = var.hosted_zone_name
}


data "aws_iam_policy" "SecurityComputeAccess" {
  name = "SecurityComputeAccess"
}

data "http" "my_public_ip" {
  url = "https://api.ipify.org?format=text"
}

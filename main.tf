
## random pet name to make the TFE fqdn change in every deployment 
resource "random_pet" "hostname_suffix" {
  length = 1
}


##### EC2 instance #####
# create ec2 instance
resource "aws_instance" "tfe_instance" {
  ami             = data.aws_ami.rhel9-ami-latest.id
  instance_type   = var.tfe_instance_class
  security_groups = [aws_security_group.tfe_sg.name]

  iam_instance_profile = aws_iam_instance_profile.ec2_s3_access.name

  user_data = templatefile("./templates/user_data_cloud_init.tftpl", {
    tfe_host_path_to_certificates  = var.tfe_host_path_to_certificates
    tfe_host_path_to_scripts       = var.tfe_host_path_to_scripts
    tfe_license                    = var.tfe_license
    tfe_version_image              = var.tfe_version_image
    tfe_hostname                   = "${var.tfe_dns_record}-${random_pet.hostname_suffix.id}.${var.hosted_zone_name}"
    tfe_http_port                  = var.tfe_http_port
    tfe_https_port                 = var.tfe_https_port
    tfe_encryption_password        = var.tfe_encryption_password
    cert                           = var.lets_encrypt_cert
    bundle                         = var.lets_encrypt_cert
    key                            = var.lets_encrypt_key
    tfe_database_user              = var.tfe_database_user
    tfe_database_name              = var.tfe_database_name
    tfe_database_password          = var.tfe_database_password
    tfe_database_host              = aws_db_instance.tfe_postgres.endpoint
    aws_region                     = var.aws_region
    tfe_object_storage_bucket_name = aws_s3_bucket.tfe_bucket.id
    org_name                       = var.org_name
    workspace_name                 = var.workspace_name
    admin_email                    = var.admin_email
    admin_username                 = var.admin_username
    admin_password                 = var.admin_password
  })

  ebs_optimized = true
  root_block_device {
    volume_size = 120
    volume_type = "gp3"

  }

  tags = {
    Name = "stam-${random_pet.hostname_suffix.id}"
  }
}

resource "aws_eip" "tfe_eip" {
  instance = aws_instance.tfe_instance.id

  tags = {
    Name = "stam-${random_pet.hostname_suffix.id}"
  }
}

#### EC2 security group ######
resource "aws_security_group" "tfe_sg" {
  name        = "tfe_sg"
  description = "Allow inbound traffic and outbound traffic for TFE"

  tags = {
    Name = "tfe-${random_pet.hostname_suffix.id}"
  }
}

resource "aws_vpc_security_group_ingress_rule" "port_443_https" {
  security_group_id = aws_security_group.tfe_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "port_80_http" {
  security_group_id = aws_security_group.tfe_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}


resource "aws_vpc_security_group_ingress_rule" "port_5432_postgres" {
  security_group_id = aws_security_group.tfe_sg.id
  cidr_ipv4         = data.aws_vpc.my-default.cidr_block
  from_port         = 5432
  ip_protocol       = "tcp"
  to_port           = 5432
}

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound_traffic_ipv4" {
  security_group_id = aws_security_group.tfe_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# DNS 
resource "aws_route53_record" "tfe-a-record" {
  zone_id = data.aws_route53_zone.my_aws_dns_zone.id
  name    = "${var.tfe_dns_record}-${random_pet.hostname_suffix.id}.${var.hosted_zone_name}"
  type    = "A"
  ttl     = 120
  records = [aws_eip.tfe_eip.public_ip]
}

# RDS instance 
resource "aws_db_instance" "tfe_postgres" {
  identifier             = "tfe-postgres"
  engine                 = "postgres"
  engine_version         = "14.16"
  instance_class         = var.db_instance_class
  allocated_storage      = 50
  storage_type           = "gp3"
  username               = var.tfe_database_user
  db_name                = var.tfe_database_name
  password               = var.tfe_database_password
  vpc_security_group_ids = [aws_security_group.tfe_sg.id]
  skip_final_snapshot    = true
  deletion_protection    = false

  tags = {
    Name = "stam-${random_pet.hostname_suffix.id}"
  }
}


# S3 Bucket
resource "aws_s3_bucket" "tfe_bucket" {
  bucket        = "tfe-data-bucket-${random_pet.hostname_suffix.id}"
  force_destroy = true

  tags = {
    Name = "stam-${random_pet.hostname_suffix.id}"
  }
}

resource "aws_s3_bucket_public_access_block" "tfe_bucket_access" {
  bucket = aws_s3_bucket.tfe_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

}

resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.tfe_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# IAM Role for EC2 to access S3 
resource "aws_iam_role" "ec2_s3_access" {
  name = "ec2_s3_access_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = {
    Name = "stam-${random_pet.hostname_suffix.id}"
  }
}

# policy to allow ec2 to access only the tfe s3 bucket 
resource "aws_iam_policy" "s3_access_policy" {
  name        = "s3_access_policy"
  description = "Policy to allow EC2 access to S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = ["s3:*"]
      Effect = "Allow",
      Resource = [
        "${aws_s3_bucket.tfe_bucket.arn}",
        "${aws_s3_bucket.tfe_bucket.arn}/*"
      ]
    }]
  })

  tags = {
    Name = "stam-${random_pet.hostname_suffix.id}"
  }
}

resource "aws_iam_role_policy_attachment" "s3_attach" {
  policy_arn = aws_iam_policy.s3_access_policy.arn
  role       = aws_iam_role.ec2_s3_access.name

}

resource "aws_iam_instance_profile" "ec2_s3_access" {
  name = "ec2_s3_access_profile"
  role = aws_iam_role.ec2_s3_access.name
}

# add the SecurityComputeAccess policy to IAM role connected to your EC2 instance
resource "aws_iam_role_policy_attachment" "SSM" {
  role       = aws_iam_role.ec2_s3_access.name
  policy_arn = data.aws_iam_policy.SecurityComputeAccess.arn
}
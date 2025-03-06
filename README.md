# Install TFE FDO podman with external services

## What is this guide about?

This guide is to have Terraform Enterprise running with Podman on external mode.
Following the steps you will create a virtual machine on AWS (EC2 instance) where the TFE application will be deployed. Also an S3 bucket is created to be used as external file storage, an RDS instance to be used as external database, and all the necessary security groups, IAM roles, DNS entries etc, to make Terraform Enterprise FDO podman to work with external services.
The scope of this guide is to be used as an example, it should not be used as is for production purposes.

## Prerequisites 

- Account on AWS Cloud

- AWS IAM user with permissions to use AWS EC2, RDS, S3, IAM and Route53 services

- IAM Role/Policy that allows to start an AWS SSM session

- [AWS cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) and [AWS SSM plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) installed and configured on your computer 

- A DNS zone hosted on AWS Route53

- Terraform Enterprise FDO license

- Git installed on your computer

- Terraform installed on your computer

## Create the AWS resources and start TFE

Export your AWS access key and secret access key as environment variables:

```sh
export AWS_ACCESS_KEY_ID=<your_access_key_id>
```

```sh
export AWS_SECRET_ACCESS_KEY=<your_secret_key>
```

Clone the repository to your computer.

Open your cli and run:

```sh
git clone git@github.com:StamatisChr/tfe-fdo-podman-external-services.git
```

When the repository cloning is finished, change directory to the repo’s terraform directory:

```sh
cd tfe-fdo-podman-external-services
```

Here you need to create a `variables.auto.tfvars` file with your specifications. Use the example tfvars file.

Rename the example file:

```sh
cp variables.auto.tfvars.example variables.auto.tfvars

```sh
Edit the file:

```sh
vim variables.auto.tfvars
```

```sh
# example tfvars file
# do not change the variable names on the left column
# replace only the values in the "< >" placeholders

aws_region                    = "<aws_region>"             # Set here your desired AWS region, example: eu-west-1
tfe_instance_class            = "<aws_ec2_instance_class>" # Set here the EC2 instance class only architecture x86_64 is supported, example: m5.xlarge
db_instance_class             = "<aws_rds_instance_class>" # Set here the RDS instance class, example:  "db.t3.large"
hosted_zone_name              = "<dns_zone_name>"          # your AWS route53 DNS zone name
tfe_dns_record                = "<tfe_host_record>"        # the host record for your TFE instance on your dns zone, example: my-tfe
tfe_license                   = "<tfe_license_string>"     # TFE license string
tfe_encryption_password       = "<type_a_password>"        # TFE encryption password
tfe_version_image             = "<tfe_version>"            # desired TFE version, example: v202410-1
tfe_database_user             = "<type_a_username>"        # TFE database user for the external database
tfe_database_name             = "<type_a_database_name>"   # The database name that TFE will use
tfe_database_password         = "<type_a_password>"        # The password for the external TFE database
admin_password                = "<type_a_password>"        # The password of the TFE Admin user
```

Populate the file according to the file comments and save.

Initialize terraform, run:

```sh
terraform init
```

Create the resources with terraform, run:

```sh
terraform apply
```

review the terraform plan.

Type yes when prompted with:

```sh
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: 
```

Wait until you see the apply completed message and the output values. 

Example:

```sh
Apply complete! Resources: 18 added, 0 changed, 0 destroyed.

Outputs:

aws_region = "eu-west-1"
rhel9_ami_id = "ami-058bcada8ce88888"
rhel9_ami_name = "RHEL-9.4.0_HVM-20241210-x86_64-0-Hourly2-GP3"
start_ssm_session = "aws ssm start-session --target instance-id i-09254c251eb439362 --region eu-west-1"
tfe-podman-fqdn = "tfe-ext-eel.stamatios-chrysinas.sbx.hashidemos.io"
```

Wait about 7-8 minutes for Terraform Enterprise to initialize.

Visit the tfe-podman-fqdn from the output.
To log in, use `admin` as username and the password you set for `admin_password` as password

## Clean up

To delete all the resources, run:

```sh
terraform destroy
```

type yes when prompted.

Wait for the resource deletion.

```sh
Destroy complete! Resources: 18 destroyed.
```

Done.
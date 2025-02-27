# Install TFE FDO podman with external services

## What is this guide about?

This guide is to have Terraform Enterprise running with Podman on external mode.
Following the steps you will create a virtual machine on AWS (EC2 instance) where the TFE application will be deployed. Also an S3 bucket is created to be used as external file storage, an RDS instance to be used as external database, and all the necessary security groups, IAM roles, DNS entries etc, to make Terraform Enterprise FDO podman to work with external services. 

## Prerequisites 

- Account on AWS Cloud

- AWS IAM user with permissions to use AWS EC2, RDS, S3, IAM and Route53 services

- IAM Role/Policy that allows to start an AWS SSM session 

- [AWS cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) and [AWS SSM plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) installed and configured on your computer 

- A DNS zone hosted on AWS Route53

- Terraform Enterprise FDO license

- Git installed and configured on your computer

- Terraform installed on your computer

## Create the AWS resources and start TFE

Export your AWS access key and secret access key as environment variables:
```
export AWS_ACCESS_KEY_ID=<your_access_key_id>
```

```
export AWS_SECRET_ACCESS_KEY=<your_secret_key>
```


Clone the repository to your computer.

Open your cli and run:
```
git clone git@github.com:StamatisChr/tfe-fdo-podman-external-services.git
```


When the repository cloning is finished, change directory to the repo’s terraform directory:
```
cd tfe-fdo-podman-external-services
```

Here you need to create a `variables.auto.tfvars` file with your specifications. Use the example tfvars file.

Rename the example file:
```
cp variables.auto.tfvars.example variables.auto.tfvars
```
Edit the file:
```
vim variables.auto.tfvars
```

```
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
admin_password                = "<type_a_passwor>          # The password of the TFE Admin user
```


Populate the file according to the file comments and save.

Initialize terraform, run:
```
terraform init
```

Create the resources with terraform, run:
```
terraform apply
```
review the terraform plan.

Type yes when prompted with:
```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: 
```
Wait until you see the apply completed message and the output values. 

Example:
```
Apply complete! Resources: 18 added, 0 changed, 0 destroyed.

Outputs:

aws_region = "eu-west-1"
rhel9_ami_id = "ami-058bcada8ce88888"
rhel9_ami_name = "RHEL-9.4.0_HVM-20241210-x86_64-0-Hourly2-GP3"
start_ssm_session = "aws ssm start-session --target instance-id i-09254c251eb439362 --region eu-west-1"
tfe-podman-fqdn = "tfe-ext-eel.stamatios-chrysinas.sbx.hashidemos.io"
```

go to the new post-deployment directory
```
cd post-deployment
```

run the script that will create your first user, organization and workspace:
```
bash setup_tfe.sh
```

example output:
```
Waiting TFE to start...
Waiting TFE to start...
Waiting TFE to start...
Waiting TFE to start...
Waiting TFE to start...
Waiting TFE to start...
Waiting TFE to start...
Waiting TFE to start...
TFE is ready to accept connections
Retrieving initial admin user token
Initial admin user token retrieved
7f8d88f8ee9211d62f8fc9e165d05cdxxxxxxxxxxx
Creating admin user..
Admin user created
Received admin user api token: 
z9WKiNUJs7C69A.atlasv1.7UAYywlOvrrzwzgGysDblQ0Z9n1pgxxxxxxxxxx
Creating resources...
visit tfe ui:
https://tfe-ext-dinosaur.stamatios-chrysinas.sbx.hashidemos.io
User credentials can be found in payload.json file
```

Visit TFE fqdn (mentioned in the script output).

Login credentials can be found in the payload.json:
```
cat payload.json
```


## Clean up

Go one direectory back from post-deployment:
```
cd ..
```

To delete all the resources, run:
```
terraform destroy
```
type yes when prompted.

Wait for the resource deletion.
```
Destroy complete! Resources: 21 destroyed.
```

Remove the post-deployment directory:
```
rm -r post-deployment
```

Done.
resource "local_file" "post_deployment" {
  filename = "./post-deployment/setup_tfe.sh"
  content  = <<-EOT
    #!/bin/bash
    TFE_HOSTNAME=https://${var.tfe_dns_record}-${random_pet.hostname_suffix.id}.${var.hosted_zone_name}

    while [ "$(curl -s $TFE_HOSTNAME/_health_check)" != "OK" ]; do 
        echo "Waiting TFE to start..."
        sleep 20 
    done
    echo "TFE is ready to accept connections"
    
    echo "Retrieving initial admin user token"
    IACT_TOKEN=$(curl -s "$TFE_HOSTNAME/admin/retrieve-iact")
    echo "Initial admin user token retrieved"
    echo $IACT_TOKEN
    
    echo "Creating admin user.."
    CREATE_ADMIN=$(curl -s --header "Content-Type: application/json" --request POST --data @payload.json "$TFE_HOSTNAME/admin/initial-admin-user?token=$IACT_TOKEN")
    echo "Admin user created"
    
    ADMIN_API_TOKEN=$(echo "$CREATE_ADMIN" | jq -r '.token')
    echo "Received admin user api token: "
    echo $ADMIN_API_TOKEN
  
    if [ $ADMIN_API_TOKEN == "null" ]; then
        echo "admin api token is null, you can run this script only once and only for 60 minutes since TFE creation"
        exit 1    
    else    
        echo  "admin_api_token = \"$ADMIN_API_TOKEN\"" > variables.auto.tfvars
    fi

    echo "Creating resources..."
    terraform init > /dev/null 2>&1
    terraform apply -auto-approve > /dev/null 2>&1


    echo "visit tfe ui:"
    echo "$TFE_HOSTNAME"
    echo "User credentials can be found in payload.json file"
  EOT
}

resource "local_file" "tfe_tf" {
  filename = "./post-deployment/tfe.tf"
  content  = <<-EOT
    terraform {
    required_providers {
    tfe = {
      source = "hashicorp/tfe"
      version = "0.64.0"
        }
      }
    }

    provider "tfe" {
    hostname = "${var.tfe_dns_record}-${random_pet.hostname_suffix.id}.${var.hosted_zone_name}" 
    token    = var.admin_api_token
    }
    
    resource "tfe_organization" "my_org" {
    name  = "${var.org_name}" 
    email = "${var.admin_email}" 
    }


    resource "tfe_workspace" "test" {
    name         = "${var.workspace_name}"
    organization = tfe_organization.my_org.name
    }

    variable "admin_api_token" {}
  EOT
}

resource "local_file" "create_admin_json" {
  filename = "./post-deployment/payload.json"
  content  = <<-EOT
    {
    "username": "${var.admin_username}",
    "email": "${var.admin_email}",
    "password": "${var.admin_password}"
    }
  EOT
}

resource "local_file" "create_tfvars" {
  filename = "./post-deployment/variables.auto.tfvars"
  content  = ""
}  
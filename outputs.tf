output "rhel9_ami_id" {
  value = data.aws_ami.rhel9-ami-latest.id

}

output "rhel9_ami_name" {
  value = data.aws_ami.rhel9-ami-latest.name

}

output "tfe-podman-fqdn" {
  description = "tfe-fqdn"
  value       = "${var.tfe_dns_record}-${random_pet.hostname_suffix.id}.${var.hosted_zone_name}"

}

output "aws_region" {
  value = var.aws_region

}

output "start_aws_ssm_session" {
  value = "aws ssm start-session --target ${aws_instance.tfe_instance.id} --region ${var.aws_region}"
}


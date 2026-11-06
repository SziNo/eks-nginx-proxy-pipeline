output "state_bucket" {
  description = "A fő Terraform state bucketje (terraform init -backend-config=\"bucket=...\")"
  value       = aws_s3_bucket.state.bucket
}

output "state_key" {
  description = "A fő Terraform state kulcsa a bucketben (a terraform/versions.tf backend blokkjával egyezik)"
  value       = local.state_key
}

output "terraform_plan_role_arn" {
  description = "A PR-os terraform plan role ARN-je (TF_PLAN_ROLE_ARN)"
  value       = aws_iam_role.github["terraform-plan"].arn
}

output "terraform_apply_role_arn" {
  description = "A terraform apply és destroy role ARN-je (TF_APPLY_ROLE_ARN)"
  value       = aws_iam_role.github["terraform-apply"].arn
}

output "app_role_arn" {
  description = "A build és deploy role ARN-je (APP_ROLE_ARN)"
  value       = aws_iam_role.github["app"].arn
}

output "local_tfvars" {
  description = "A terraform/terraform.tfvars tartalma a helyi használathoz (ugyanazok az értékek, mint a CI-ban)"
  value       = <<-EOT
    region                       = "${var.region}"
    cluster_name                 = "${var.cluster_name}"
    cluster_admin_principal_arns = ${local.github_variables["TF_VAR_cluster_admin_principal_arns"]}
    cluster_plan_principal_arns  = ${local.github_variables["TF_VAR_cluster_plan_principal_arns"]}
  EOT
}

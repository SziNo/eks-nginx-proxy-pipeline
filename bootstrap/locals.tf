# Számított és közös értékek.
locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition

  # Kiszámítható, globálisan egyedi bucket név (az S3 nevek az egész AWS-ben egyediek, ezért
  # kell bele az account ID és a régió). A repó nevéből kisbetűs, mert az S3 csak ezt engedi.
  state_bucket_name = lower("tfstate-${local.account_id}-${var.region}-${var.github_repository}")

  # A fő Terraform state kulcsa: ugyanez van a terraform/versions.tf backend blokkjában.
  state_key = "production/terraform.tfstate"

  # A GitHub OIDC token sub claimjének eleje: repo:<owner>/<repo>
  github_repo_sub = "repo:${var.github_owner}/${var.github_repository}"

  # A GitHub Actions role-ok névelőtagja. SZÁNDÉKOSAN nem a cluster nevével kezdődik:
  # az apply role IAM jogai a "<cluster_name>-*" nevekre szólnak, így nem tudja átírni
  # sem a saját, sem a másik két GitHub Actions role jogait (privilege escalation ellen).
  role_prefix = "gha-${var.github_repository}"

  # Az EKS cluster ARN-je (az app role eks:DescribeCluster joga ehhez szól).
  cluster_arn = "arn:${local.partition}:eks:${var.region}:${local.account_id}:cluster/${var.cluster_name}"

  # A két alkalmazás ECR repója (a fő Terraform hozza létre, <cluster_name>/<szolgáltatás> névvel).
  services = ["service-a", "service-b"]
  ecr_repository_arns = [
    for svc in local.services : "arn:${local.partition}:ecr:${var.region}:${local.account_id}:repository/${var.cluster_name}/${svc}"
  ]

  # A main ág kötelező status checkjei: a két workflow gyűjtő jobjának neve.
  required_status_checks = ["plan-status", "build-status"]
}

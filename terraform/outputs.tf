# A scripts/ és a README ezekre a nevekre hivatkozik.

output "region" {
  description = "AWS régió (a scriptek ebből tudják, hol dolgozzanak)"
  value       = var.region
}

output "cluster_name" {
  description = "Az EKS cluster neve"
  value       = module.eks.cluster_name
}

output "ecr_repository_urls" {
  description = "Szolgáltatás neve => ECR repó címe"
  value       = module.ecr.repository_urls
}

output "nlb_security_group_id" {
  description = "Az NLB security groupja (a deploy és a render.sh név alapján kérdezi le, és patch-csel a Service annotációjába írja)"
  value       = module.eks.nlb_security_group_id
}

output "kubeconfig_command" {
  description = "Ezzel a paranccsal állítható be a kubectl a clusterhez"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}
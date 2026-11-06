# A modulok meghívása. A sorrend az olvashatóságot szolgálja; azt, hogy mi mikor jön létre,
# a Terraform a hivatkozásokból (függőségekből) dönti el.

# ECR repók a két alkalmazás image-ének (for_each a szolgáltatás nevével).
# A repók neve <cluster_name>/<szolgáltatás>, pl. szino-nginx-proxy-demo/service-a.
# Független a többitől, ezért a Terraform a VPC-vel párhuzamosan hozza létre.
module "ecr" {
  source = "./modules/ecr"

  name_prefix          = var.cluster_name
  repository_names     = local.services
  image_tag_mutability = var.ecr_image_tag_mutability
  force_delete         = var.ecr_force_delete
}

# Hálózat: VPC, publikus és privát subnetek AZ-nként (a tfvars subnets térképéből),
# internet és NAT gateway, route táblák.
module "vpc" {
  source = "./modules/vpc"

  name     = var.cluster_name
  vpc_cidr = var.vpc_cidr
  subnets  = var.subnets
}

# EKS cluster: IAM szerepek, security groupok (az NLB-é is), cluster, addonok,
# managed node group, OIDC provider és access entryk (admin és a plan role olvasási joga).
module "eks" {
  source = "./modules/eks"

  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids # a control plane ENI-k és a node-ok is a privát subnetekben

  node_instance_types = var.node_instance_types
  node_ami_type       = var.node_ami_type
  node_desired_size   = var.node_desired_size
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size

  endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  nlb_ingress_cidrs            = var.nlb_ingress_cidrs

  # Cluster admin: a saját IAM user, a terraform-apply és az app role (a bootstrap adja meg
  # a GitHub Variables-ben, helyben a terraform.tfvars-ban)
  cluster_admin_principal_arns = var.cluster_admin_principal_arns

  # A terraform-plan role csak a Helm release namespace-ében olvashat (a plan alatti refreshhez)
  cluster_plan_principal_arns = var.cluster_plan_principal_arns
  cluster_plan_namespace      = local.lb_controller_namespace
}

# AWS Load Balancer Controller: IRSA szerep + Helm release. Ez hozza létre az NLB-t
# a k8s/base/nginx-service.yaml LoadBalancer Service-e alapján.
module "lb_controller" {
  source = "./modules/lb-controller"

  cluster_name      = module.eks.cluster_name
  region            = var.region
  vpc_id            = module.vpc.vpc_id
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  chart_version     = var.lb_controller_chart_version
  namespace         = local.lb_controller_namespace

  # A Helm release csak akkor induljon, ha az EKS modul MINDEN eleme kész: a node group
  # (különben a controller podjai nem tudnak elindulni) és az admin access entry
  # (különben a Helm provider nem jogosult telepíteni).
  depends_on = [module.eks]
}

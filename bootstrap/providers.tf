# AWS provider: a helyi AWS hitelesítéssel fut (a saját IAM userrel), a régiót változóból kapja.
# A default_tags minden AWS erőforrásra rákerül.
provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = var.github_repository
      ManagedBy = "terraform-bootstrap"
    }
  }
}

# GitHub provider: az owner a repó gazdája; a token a GITHUB_TOKEN környezeti változóból jön,
# ezért a kódban és a tfvars-ban nincs titok.
provider "github" {
  owner = var.github_owner
}

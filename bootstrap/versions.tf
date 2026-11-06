# A bootstrap a CI/CD előfeltételeit hozza létre: S3 state bucket, a GitHub Actions IAM
# role-jai és a GitHub repó beállításai. Egyszer fut, HELYBEN, helyi state-tel: a remote
# state bucket itt jön létre, ezért ennek a rootnak a state-je még nem lehet benne.
terraform {
  # Pontosan ugyanaz a verzió, mint a terraform/ rootban és a CI-ban (setup-terraform).
  required_version = "1.16.4"

  required_providers {
    # AWS provider: S3 bucket, IAM role-ok és policyk.
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    # GitHub provider: repository variables, environment, branch protection.
    # A tokent a GITHUB_TOKEN környezeti változóból olvassa (export GITHUB_TOKEN=$(gh auth token)).
    github = {
      source  = "integrations/github"
      version = "~> 6.13"
    }
  }
}

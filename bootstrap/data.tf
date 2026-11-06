# Lekérdezések: már létező dolgok, ezeket a bootstrap nem hozza létre és nem törli.

# Az account ID a bucket nevéhez és az ARN-ekhez (így nem kell a kódba írni).
data "aws_caller_identity" "current" {}

# Az ARN partíció (aws) a kézzel összerakott ARN-ekhez.
data "aws_partition" "current" {}

# A GitHub OIDC provider MÁR LÉTEZIK az accountban (megosztott account, mások is használják):
# csak hivatkozunk rá, SOHA nem hozzuk létre és nem töröljük.
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# A GitHub repó adatai (a branch protectionhöz a node ID kell).
data "github_repository" "this" {
  name = var.github_repository
}

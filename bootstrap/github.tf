locals {
  # Repository Variables (nem secretek: egyik sem titok, csak account-specifikus, ezért nem
  # kerülnek a publikus repó kódjába). A workflow-k vars.<NÉV> formában olvassák őket.
  github_variables = {
    AWS_REGION        = var.region
    CLUSTER_NAME      = var.cluster_name
    TF_STATE_BUCKET   = aws_s3_bucket.state.bucket
    TF_PLAN_ROLE_ARN  = aws_iam_role.github["terraform-plan"].arn
    TF_APPLY_ROLE_ARN = aws_iam_role.github["terraform-apply"].arn
    APP_ROLE_ARN      = aws_iam_role.github["app"].arn

    # A fő Terraform változói JSON listaként (a Terraform a TF_VAR_* környezeti változóból
    # a set(string) típust is fel tudja dolgozni).
    # Cluster admin: a saját IAM userem, az apply role (Helm, destroy előtti kubectl delete)
    # és az app role (kubectl apply, a manifestek namespace-t is létrehoznak).
    TF_VAR_cluster_admin_principal_arns = jsonencode(sort([
      var.admin_user_arn,
      aws_iam_role.github["terraform-apply"].arn,
      aws_iam_role.github["app"].arn,
    ]))
    # Csak olvasás a kube-system namespace-ben: a plan alatt a Helm release állapotához.
    TF_VAR_cluster_plan_principal_arns = jsonencode([aws_iam_role.github["terraform-plan"].arn])
  }
}

# Repository Variables létrehozása (for_each a változó nevén).
resource "github_actions_variable" "this" {
  for_each = local.github_variables

  repository    = data.github_repository.this.name
  variable_name = each.key
  value         = each.value
}

# A production environment: jóváhagyás nélkül, de csak a main ágról lehet rá deployolni.
# Az apply és az app role trust policyja ennek a nevére (environment:production) szól.
resource "github_repository_environment" "production" {
  repository  = data.github_repository.this.name
  environment = "production"

  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }
}

# Az environment ág szabálya: csak a main.
resource "github_repository_environment_deployment_policy" "main" {
  repository     = data.github_repository.this.name
  environment    = github_repository_environment.production.environment
  branch_pattern = "main"
}

# Branch protection a main ágon: csak PR-ral lehet módosítani, a plan és a build gyűjtő
# jobjának sikeresnek kell lennie, jóváhagyás nem kötelező (egyedül dolgozom).
# enforce_admins: a repó gazdájára is vonatkozik, vagyis direkt push a main-re senkinek sincs.
resource "github_branch_protection" "main" {
  repository_id  = data.github_repository.this.node_id
  pattern        = "main"
  enforce_admins = true

  allows_force_pushes = false
  allows_deletions    = false

  required_status_checks {
    # strict: a PR ága legyen naprakész a main-nel, mielőtt mergelhető
    strict   = true
    contexts = local.required_status_checks
  }

  required_pull_request_reviews {
    required_approving_review_count = 0
  }
}

locals {
  # A három GitHub Actions role: név utótag => a GitHub OIDC token elfogadott sub claimjei.
  # - terraform-plan: pull_request eseményből (a plan job nem használ environmentet), és a
  #   main ágról kézzel indított (workflow_dispatch) planhez a main ág ref-je. Csak olvas.
  # - terraform-apply és app: csak a production environmentet használó jobokból. FONTOS:
  #   environment használatakor a sub "environment:production", NEM "ref:refs/heads/main".
  #   Hogy csak a main ág használhatja, azt az environment deployment branch policyja biztosítja.
  github_roles = {
    terraform-plan  = ["${local.github_repo_sub}:pull_request", "${local.github_repo_sub}:ref:refs/heads/main"]
    terraform-apply = ["${local.github_repo_sub}:environment:production"]
    app             = ["${local.github_repo_sub}:environment:production"]
  }

  # AWS managed policyk role-onként (kulcs: "<role>/<policy>", hogy a for_each kulcs stabil legyen).
  github_role_managed_policies = {
    # A plan mindent olvashat (a refresh minden erőforrást lekérdez), de semmit nem módosíthat.
    "terraform-plan/ReadOnlyAccess" = { role = "terraform-plan", arn = "arn:${local.partition}:iam::aws:policy/ReadOnlyAccess" }
    # Az apply minden nem-IAM szolgáltatást kezelhet; az IAM jogok a saját, szűkített policyból jönnek.
    "terraform-apply/PowerUserAccess" = { role = "terraform-apply", arn = "arn:${local.partition}:iam::aws:policy/PowerUserAccess" }
  }

  # IAM ARN minták a fő Terraform által kezelt nevekhez (cluster név előtag).
  cluster_role_arn_pattern   = "arn:${local.partition}:iam::${local.account_id}:role/${var.cluster_name}-*"
  cluster_policy_arn_pattern = "arn:${local.partition}:iam::${local.account_id}:policy/${var.cluster_name}-*"
}

# Trust policy role-onként: csak a GitHub OIDC provider tokenjével, csak ebből a repóból
# (sub), és csak ha a token az STS-nek szól (aud).
data "aws_iam_policy_document" "github_assume_role" {
  for_each = local.github_roles

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = each.value
    }
  }
}

# A három IAM role, amelyet a GitHub Actions jobok OIDC-vel (access key nélkül) vesznek fel.
resource "aws_iam_role" "github" {
  for_each = local.github_roles

  name                 = "${local.role_prefix}-${each.key}"
  description          = "GitHub Actions (${var.github_owner}/${var.github_repository}): ${each.key}"
  assume_role_policy   = data.aws_iam_policy_document.github_assume_role[each.key].json
  max_session_duration = 3600
}

# Az AWS managed policyk csatolása (plan: ReadOnlyAccess, apply: PowerUserAccess).
resource "aws_iam_role_policy_attachment" "github_managed" {
  for_each = local.github_role_managed_policies

  role       = aws_iam_role.github[each.value.role].name
  policy_arn = each.value.arn
}

# --- terraform-plan: a state lock fájl írása ---

# A use_lockfile a plan alatt is létrehoz, majd töröl egy <key>.tflock fájlt; a ReadOnlyAccess
# ezt nem engedi, ezért csak erre az egy objektumra kap írás és törlés jogot.
data "aws_iam_policy_document" "plan_state_lock" {
  statement {
    sid       = "StateLockFile"
    actions   = ["s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.state.arn}/${local.state_key}.tflock"]
  }
}

# Inline policy a plan role-on (a lock fájl joga csak ehhez a role-hoz tartozik).
resource "aws_iam_role_policy" "plan_state_lock" {
  name   = "terraform-state-lock"
  role   = aws_iam_role.github["terraform-plan"].id
  policy = data.aws_iam_policy_document.plan_state_lock.json
}

# --- terraform-apply: IAM jogok a cluster név előtagra szűkítve ---

# A PowerUserAccess az IAM-et (néhány kivétellel) nem engedi. A fő Terraform ezeket az IAM
# erőforrásokat kezeli: <cluster>-cluster, <cluster>-node, <cluster>-aws-lbc role, a
# <cluster>-AWSLoadBalancerControllerIAMPolicy policy, és a cluster saját IAM OIDC providere.
data "aws_iam_policy_document" "apply_iam" {
  # Olvasás mindenre: a plan/refresh és a destroy előtti lekérdezésekhez.
  statement {
    sid       = "IamRead"
    actions   = ["iam:Get*", "iam:List*"]
    resources = ["*"]
  }

  # Role-ok kezelése, csak a cluster név előtaggal.
  statement {
    sid = "ClusterRoles"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:UpdateRole",
      "iam:UpdateRoleDescription",
      "iam:UpdateAssumeRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
    ]
    resources = [local.cluster_role_arn_pattern]
  }

  # Policy csatolás a cluster role-okra, de csak az EKS-hez szükséges AWS managed policykat
  # és a saját, előtagos policykat (így pl. AdministratorAccess nem csatolható).
  statement {
    sid       = "ClusterRolePolicyAttachments"
    actions   = ["iam:AttachRolePolicy", "iam:DetachRolePolicy"]
    resources = [local.cluster_role_arn_pattern]

    condition {
      test     = "ArnLike"
      variable = "iam:PolicyARN"
      values = [
        "arn:${local.partition}:iam::aws:policy/AmazonEKSClusterPolicy",
        "arn:${local.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy",
        "arn:${local.partition}:iam::aws:policy/AmazonEKS_CNI_Policy",
        "arn:${local.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
        local.cluster_policy_arn_pattern,
      ]
    }
  }

  # Saját (customer managed) policyk kezelése, csak a cluster név előtaggal.
  statement {
    sid = "ClusterPolicies"
    actions = [
      "iam:CreatePolicy",
      "iam:DeletePolicy",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:SetDefaultPolicyVersion",
      "iam:TagPolicy",
      "iam:UntagPolicy",
    ]
    resources = [local.cluster_policy_arn_pattern]
  }

  # Instance profile-ok a cluster név előtaggal (a managed node group ma nem igényli,
  # de az EKS node-okhoz kapcsolódó IAM művelet, ezért a szűk minta engedi).
  statement {
    sid = "ClusterInstanceProfiles"
    actions = [
      "iam:CreateInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:TagInstanceProfile",
      "iam:UntagInstanceProfile",
    ]
    resources = ["arn:${local.partition}:iam::${local.account_id}:instance-profile/${var.cluster_name}-*"]
  }

  # PassRole: az EKS-nek át kell adni a cluster és a node role-t (CreateCluster, CreateNodegroup).
  statement {
    sid       = "PassClusterRoles"
    actions   = ["iam:PassRole"]
    resources = [local.cluster_role_arn_pattern]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["eks.amazonaws.com", "ec2.amazonaws.com"]
    }
  }

  # A cluster IAM OIDC providere (IRSA). Csak az oidc.eks.<régió> kibocsátókra, így a megosztott
  # GitHub OIDC providerhez (token.actions.githubusercontent.com) nem nyúlhat.
  statement {
    sid = "EksOidcProvider"
    actions = [
      "iam:CreateOpenIDConnectProvider",
      "iam:DeleteOpenIDConnectProvider",
      "iam:UpdateOpenIDConnectProviderThumbprint",
      "iam:AddClientIDToOpenIDConnectProvider",
      "iam:RemoveClientIDFromOpenIDConnectProvider",
      "iam:TagOpenIDConnectProvider",
      "iam:UntagOpenIDConnectProvider",
    ]
    resources = ["arn:${local.partition}:iam::${local.account_id}:oidc-provider/oidc.eks.${var.region}.amazonaws.com/id/*"]
  }

  # Service-linked role-ok (az első EKS cluster, node group, load balancer vagy Auto Scaling
  # group létrehozásakor az AWS hozza létre őket), csak ezekre a szolgáltatásokra.
  statement {
    sid       = "ServiceLinkedRoles"
    actions   = ["iam:CreateServiceLinkedRole"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values = [
        "eks.amazonaws.com",
        "eks-nodegroup.amazonaws.com",
        "elasticloadbalancing.amazonaws.com",
        "autoscaling.amazonaws.com",
      ]
    }
  }
}

# Saját (customer managed) policy az apply role IAM jogaihoz. A neve is a role előtagjával
# kezdődik, így az apply role (amely csak <cluster>-* policykat kezelhet) nem módosíthatja.
resource "aws_iam_policy" "apply_iam" {
  name        = "${local.role_prefix}-terraform-apply-iam"
  description = "IAM jogok a fő Terraformhoz, a(z) ${var.cluster_name} előtagra szűkítve"
  policy      = data.aws_iam_policy_document.apply_iam.json
}

# A saját IAM policy csatolása az apply role-hoz.
resource "aws_iam_role_policy_attachment" "apply_iam" {
  role       = aws_iam_role.github["terraform-apply"].name
  policy_arn = aws_iam_policy.apply_iam.arn
}

# --- app: ECR push és deploy ---

# Az app role a build és a deploy jogait kapja: push csak a két ECR repóba, a cluster adatai
# a kubeconfighoz, és az NLB security group ID lekérdezése. A Kubernetes jogot az EKS access
# entry adja (a fő Terraformban), nem IAM.
data "aws_iam_policy_document" "app" {
  # A registry login tokenje (nincs resource szintű jogosultsága, ezért "*").
  statement {
    sid       = "EcrLogin"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  # Push és tag-ellenőrzés (DescribeImages) csak a két alkalmazás repójába.
  statement {
    sid = "EcrPush"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = local.ecr_repository_arns
  }

  # aws eks update-kubeconfig: a cluster endpointja és CA-ja.
  statement {
    sid       = "EksDescribe"
    actions   = ["eks:DescribeCluster"]
    resources = [local.cluster_arn]
  }

  # Az NLB security group ID lekérdezése név alapján (a Describe* EC2 hívásoknak nincs
  # resource szintű jogosultsága, ezért "*").
  statement {
    sid       = "Ec2DescribeSecurityGroups"
    actions   = ["ec2:DescribeSecurityGroups"]
    resources = ["*"]
  }
}

# Inline policy az app role-on.
resource "aws_iam_role_policy" "app" {
  name   = "build-and-deploy"
  role   = aws_iam_role.github["app"].id
  policy = data.aws_iam_policy_document.app.json
}

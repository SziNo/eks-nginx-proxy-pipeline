# Access entry: felveszi az IAM principalokat a cluster hozzáférési listájára. Enélkül a kubectl
# és a Helm provider "Unauthorized" hibát kapna. Az adminok: a saját IAM user, a terraform-apply
# role (Helm, destroy előtti kubectl delete) és az app role (kubectl apply a deployban).
# A node group szerepéhez az EKS magától létrehozza a saját access entryt.
resource "aws_eks_access_entry" "admin" {
  for_each = var.cluster_admin_principal_arns

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value
  type          = "STANDARD"
}

# Jogosultság az admin access entrykhez: AmazonEKSClusterAdminPolicy (cluster-admin) az egész clusterre.
resource "aws_eks_access_policy_association" "admin" {
  for_each = var.cluster_admin_principal_arns

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = aws_eks_access_entry.admin[each.key].principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

# Access entry a terraform-plan role-nak: a PR-os plan alatt a Helm provider frissíti a
# helm_release állapotát, ehhez a clusterből olvas.
resource "aws_eks_access_entry" "plan" {
  for_each = var.cluster_plan_principal_arns

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value
  type          = "STANDARD"
}

# A plan role a lehető legszűkebb jogot kapja, ami a refresh-hez elég:
# - A Helm a release állapotát Secretekben tárolja (sh.helm.release.v1.<név>.v<N>) a release
#   namespace-ében, a refresh ezeket listázza és olvassa.
# - Az AmazonEKSViewPolicy (a Kubernetes "view" ClusterRole) a Secreteket szándékosan kihagyja,
#   ezért nem elég. Az AmazonEKSAdminViewPolicy csak olvas (get/list/watch), de a Secreteket is.
# - A namespace scope miatt ez csak a Helm release namespace-ére (kube-system) érvényes; a
#   discovery API-t (/api, /apis) a Kubernetes minden hitelesített usernek megengedi.
resource "aws_eks_access_policy_association" "plan" {
  for_each = var.cluster_plan_principal_arns

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = aws_eks_access_entry.plan[each.key].principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminViewPolicy"

  access_scope {
    type       = "namespace"
    namespaces = [var.cluster_plan_namespace]
  }
}

#!/usr/bin/env bash
# Mindent lebont a helyes sorrendben, HELYI használatra (a CI megfelelője: destroy.yml), és a
# végén ellenőrzi, hogy nem maradt-e fizetős erőforrás. A bootstrapet NEM bontja le.
# Használat (a projekt gyökeréből): ./scripts/teardown.sh
set -euo pipefail
# shellcheck source=scripts/common.sh
source "$(dirname "$0")/common.sh"

tf_init
# Ha nincs state (pl. már le van bontva), nincs mit tenni.
if ! load_tf_outputs; then
  echo "Nincs Terraform kimenet (üres a state?). Valószínűleg már minden le van bontva."
  exit 0
fi

echo "Régió: ${REGION}, cluster: ${CLUSTER}"

# ---------- 1. Kubernetes erőforrások: ELŐSZÖR, hogy a controller törölje az NLB-t ----------
# Az NLB-t nem a Terraform hozta létre, hanem az AWS Load Balancer Controller. Ha a cluster
# előbb tűnne el, az NLB gazdátlanul ott maradna, és a terraform destroy elakadna a VPC-n.
NLB_ARN=""
if aws eks describe-cluster --name "$CLUSTER" --region "$REGION" >/dev/null 2>&1; then
  aws eks update-kubeconfig --name "$CLUSTER" --region "$REGION" >/dev/null

  # Az NLB ARN-je a Service hostnevéből, amíg a Service még létezik
  HOST="$(kubectl -n "$NAMESPACE" get service nginx-proxy \
    -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' --ignore-not-found)"
  if [ -n "$HOST" ]; then
    NLB_ARN="$(aws elbv2 describe-load-balancers --region "$REGION" \
      --query "LoadBalancers[?DNSName=='${HOST}'].LoadBalancerArn" --output text)"
  fi

  # --wait: a Service-en lévő controller finalizer miatt ez csak akkor tér vissza,
  # amikor a controller már törölte az NLB-t és a target groupokat.
  kubectl delete -k k8s/base --ignore-not-found --wait=true --timeout=10m
else
  echo "A cluster már nem létezik, a Kubernetes lépés kimarad."
fi

# Biztonsági ellenőrzés az AWS oldalon: az NLB ténylegesen eltűnt-e.
if [ -n "$NLB_ARN" ]; then
  echo "Várakozás, amíg az NLB eltűnik..."
  aws elbv2 wait load-balancers-deleted --region "$REGION" --load-balancer-arns "$NLB_ARN"
fi

# ---------- 2. Terraform: minden más (EKS, VPC, NAT, ECR, IAM) ----------
# Helyben szándékosan nincs -auto-approve: a Terraform megmutatja, mit töröl, és rákérdez.
# A nem érzékeny értékek a production.tfvars-ból, a többi a terraform.tfvars-ból jön.
terraform -chdir="$TF_DIR" destroy -var-file=production.tfvars

# ---------- 3. Ellenőrzés: maradt-e fizetős erőforrás? ----------
echo
echo "Ellenőrzés (mindháromnál üres kimenet a jó):"
echo "- Load balancerek:"
aws elbv2 describe-load-balancers --region "$REGION" --query 'LoadBalancers[].LoadBalancerName' --output text
echo "- Futó NAT gatewayek:"
aws ec2 describe-nat-gateways --region "$REGION" --filter Name=state,Values=available \
  --query 'NatGateways[].NatGatewayId' --output text
echo "- EKS clusterek:"
aws eks list-clusters --region "$REGION" --query 'clusters' --output text
echo "Kész."

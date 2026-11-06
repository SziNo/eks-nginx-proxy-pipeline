#!/usr/bin/env bash
# A helyi overlay (k8s/overlays/local, gitignore-olt) előállítása, HELYI használatra.
# A commitolt production overlay másolatán ugyanazokat a kustomize edit parancsokat futtatja,
# mint a CI _deploy.yml-je, így a helyi és a CI-os telepítés nem tér el.
# Használat (a projekt gyökeréből): ./scripts/render.sh [tag]   (alapból: git rev-parse HEAD)
# Utána: kubectl apply -k k8s/overlays/local
set -euo pipefail
# shellcheck source=scripts/common.sh
source "$(dirname "$0")/common.sh"

TAG="${1:-$(git rev-parse HEAD)}"

tf_init
load_tf_outputs || { echo "HIBA: üres a Terraform state, előbb kell az infrastruktúra." >&2; exit 1; }
REGISTRY="$(ecr_registry)"
SG_ID="$(nlb_sg_id)"
if [[ "$SG_ID" != sg-* ]]; then
  echo "HIBA: nem található a ${CLUSTER}-nlb security group." >&2
  exit 1
fi

# Mindig friss másolat a production overlayről (a ../../base útvonal ugyanolyan mélységben érvényes),
# így a script akárhányszor futtatható, és a commitolt fájl érintetlen marad.
OVERLAY_DIR="k8s/overlays/local"
rm -rf "$OVERLAY_DIR"
cp -r "$PRODUCTION_OVERLAY" "$OVERLAY_DIR"

cd "$OVERLAY_DIR"
kustomize edit set image \
  "service-a=${REGISTRY}/${CLUSTER}/service-a:${TAG}" \
  "service-b=${REGISTRY}/${CLUSTER}/service-b:${TAG}"
kustomize edit add patch --kind Service --name nginx-proxy \
  --patch "[{\"op\":\"add\",\"path\":\"/metadata/annotations/service.beta.kubernetes.io~1aws-load-balancer-security-groups\",\"value\":\"${SG_ID}\"}]"

echo "Generálva: ${OVERLAY_DIR}/kustomization.yaml (tag: ${TAG}, SG: ${SG_ID})"
echo "Ellenőrzés: kubectl kustomize ${OVERLAY_DIR}"
echo "Telepítés:  kubectl apply -k ${OVERLAY_DIR}"

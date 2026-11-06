#!/usr/bin/env bash
# Mindkét image buildelése linux/amd64-re és feltöltése az ECR-be, HELYI használatra.
# Ugyanaz, mint a CI _build.yml push jobja: tag = commit SHA, a már létező tag kimarad
# (a repók IMMUTABLE-k). A repók neve <cluster_name>/<szolgáltatás>.
# Használat (a projekt gyökeréből): ./scripts/build-push.sh [tag]   (alapból: git rev-parse HEAD)
set -euo pipefail
# shellcheck source=scripts/common.sh
source "$(dirname "$0")/common.sh"

TAG="${1:-$(git rev-parse HEAD)}"

# A commit SHA tag csak akkor igaz, ha a src/ pontosan a commit tartalma
if [ -z "${1:-}" ] && [ -n "$(git status --porcelain -- src/)" ]; then
  echo "HIBA: a src/ alatt nem commitolt változás van, a ${TAG} tag nem ezt a tartalmat jelölné." >&2
  exit 1
fi

tf_init
load_tf_outputs || { echo "HIBA: üres a Terraform state, előbb kell az infrastruktúra." >&2; exit 1; }
REGISTRY="$(ecr_registry)"

# A login a registryre szól (fiókonként és régiónként egy), nem az egyes repókra
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$REGISTRY"

for svc in "${SERVICES[@]}"; do
  repo="${CLUSTER}/${svc}"
  if aws ecr describe-images --region "$REGION" --repository-name "$repo" \
      --image-ids imageTag="$TAG" >/dev/null 2>&1; then
    echo "${repo}:${TAG} már létezik, kimarad."
    continue
  fi
  # --platform: ha ARM (pl. Apple Silicon) gépen buildelsz, a node-ok viszont x86-osak
  docker buildx build --platform linux/amd64 -t "${REGISTRY}/${repo}:${TAG}" --push "src/${svc}"
done

echo "Kész: ${REGISTRY}/${CLUSTER}/{service-a,service-b}:${TAG}"

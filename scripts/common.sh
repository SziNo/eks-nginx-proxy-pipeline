# shellcheck shell=bash
# Közös beállítások és függvények a helyi scriptekhez (a többi script source-olja, önállóan nem fut).
# A logika ugyanaz, mint a CI-ban (.github/workflows/_build.yml, _deploy.yml, destroy.yml):
# ugyanaz a state (S3), ugyanaz a commit SHA tag, ugyanaz az SG lekérdezés és kustomize edit.
# Minden script a projekt gyökeréből fut: ./scripts/<név>.sh

# A változókat a source-oló scriptek használják, ezért itt "nem használtnak" látszanak.
# shellcheck disable=SC2034
TF_DIR="terraform"
BOOTSTRAP_DIR="bootstrap"
NAMESPACE="demo"
SERVICES=(service-a service-b)
PRODUCTION_OVERLAY="k8s/overlays/production"

# Partial backend init: a bucket nevét a bootstrap outputjából kapja (CI-ban a TF_STATE_BUCKET
# variable-ből). Többször is futtatható, a már inicializált könyvtárat csak ellenőrzi.
tf_init() {
  local bucket
  bucket="$(terraform -chdir="$BOOTSTRAP_DIR" output -raw state_bucket)"
  terraform -chdir="$TF_DIR" init -input=false -backend-config="bucket=${bucket}" >/dev/null
}

# A régió és a cluster neve a fő Terraform outputjából (REGION, CLUSTER változók).
# Hibával tér vissza, ha a state üres (nincs még apply, vagy már le van bontva).
load_tf_outputs() {
  REGION="$(terraform -chdir="$TF_DIR" output -raw region 2>/dev/null)" || return 1
  CLUSTER="$(terraform -chdir="$TF_DIR" output -raw cluster_name)"
}

# Az ECR registry címe (<account>.dkr.ecr.<régió>.amazonaws.com).
ecr_registry() {
  local account_id
  account_id="$(aws sts get-caller-identity --query Account --output text)"
  echo "${account_id}.dkr.ecr.${REGION}.amazonaws.com"
}

# Az NLB security group ID-ja név alapján, ugyanúgy, mint a _deploy.yml-ben.
nlb_sg_id() {
  aws ec2 describe-security-groups --region "$REGION" \
    --filters "Name=group-name,Values=${CLUSTER}-nlb" \
    --query 'SecurityGroups[0].GroupId' --output text
}

# A kustomize edit-hez önálló kustomize bináris kell (a kubectl beépített kustomize-a nem tud
# edit-et). Ha nincs telepítve, a hivatalos image-et futtatja dockerrel, az aktuális könyvtárra.
if ! command -v kustomize >/dev/null 2>&1; then
  kustomize() {
    docker run --rm -u "$(id -u):$(id -g)" -v "$PWD:/work" -w /work \
      registry.k8s.io/kustomize/kustomize:v5.8.1 "$@"
  }
fi

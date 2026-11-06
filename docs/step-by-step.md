# Lépésről lépésre

A teljes folyamat a template-ből létrehozott repótól a lebontásig, sorrendben, a parancsokkal és a várt kimenetekkel. Minden parancs a projekt gyökeréből fut, hacsak a lépés mást nem mond. A `<...>` helyére a saját értéked kerül.

> 🖐 **KÉZI LÉPÉS** jelöli azokat a lépéseket, amelyeket neked kell elvégezned. Ilyen a bootstrap helyi apply-ja, a GitHub token, az első init és az első PR. Minden más a GitHub Actionsben fut.

Az AWS-től függő kimenetek (ID-k, időtartamok) **példák**, a te futásodban az értékek mások lesznek, a szerkezetük ugyanez.

---

## 0. Előfeltételek

```bash
terraform version        # Terraform v1.16.4  (pontosan ez: a required_version ezt köti ki)
aws --version            # aws-cli/2.x
kubectl version --client # Client Version: v1.37.x
docker --version         # Docker version 2x.x
git --version
aws sts get-caller-identity
```

Az utolsó parancs várt kimenete (a saját IAM usered):

```json
{
    "UserId": "AIDA...",
    "Account": "<account ID>",
    "Arn": "arn:aws:iam::<account ID>:user/<user>"
}
```

**A GitHub OIDC provider létezése** (ha nincs, szólj az account gazdájának, a bootstrap NEM hozza létre):

```bash
aws iam list-open-id-connect-providers --query 'OpenIDConnectProviderList[].Arn' --output text
# ... arn:aws:iam::<account ID>:oidc-provider/token.actions.githubusercontent.com ...
```

---

## 1. A repó létrehozása a template-ből

1. GitHubon a `SziNo/EKS-nginx-proxy` repón: **Use this template → Create a new repository**, a neve `eks-nginx-proxy-pipeline`, **Public**.
2. Klónozás:
   ```bash
   git clone https://github.com/SziNo/eks-nginx-proxy-pipeline.git
   cd eks-nginx-proxy-pipeline
   git log --oneline        # 1 commit: Initial commit
   ```

## 2. Az `apps/` → `src/` átnevezés

```bash
git mv apps src
git status --short
```

Várt kimenet (8 átnevezés):

```
R  apps/service-a/.dockerignore -> src/service-a/.dockerignore
R  apps/service-a/Dockerfile -> src/service-a/Dockerfile
...
R  apps/service-b/requirements.txt -> src/service-b/requirements.txt
```

```bash
git commit -m "rename app to src"
```

**Ellenőrzés: maradt-e hivatkozás a régi útvonalra?**

```bash
grep -rn "apps/" --exclude-dir=.git --exclude-dir=.terraform .
```

A régi README-ben és a `scripts/build-push.sh`-ban még előfordul az `apps/`. Ezeket a 3. lépés cseréli le. A pipeline elkészülte után a várt kimenet csak ez:

```
k8s/base/service-b.yaml:1:apiVersion: apps/v1
k8s/base/nginx-daemonset.yaml:1:apiVersion: apps/v1
k8s/base/service-a.yaml:1:apiVersion: apps/v1
docs/step-by-step.md:...   (ennek a fájlnak a saját szövege, pl. ez a lépés)
```

Az `apiVersion: apps/v1` sorok **NEM érintettek**: ez a Kubernetes API csoportja (Deployment, DaemonSet), nem könyvtár, nem szabad átírni.

## 3. A pipeline fájljai

Ebben a lépésben készülnek (vagy módosulnak) a következők:

| Fájl | Mi ez |
| --- | --- |
| `bootstrap/*.tf`, `bootstrap/terraform.tfvars.example`, `bootstrap/.terraform.lock.hcl` | S3 state bucket, 3 IAM role, GitHub beállítások |
| `terraform/versions.tf` | `required_version = "1.16.4"`, `backend "s3"` (partial) |
| `terraform/variables.tf`, `main.tf`, `locals.tf`, `modules/eks/access.tf`, `modules/eks/variables.tf` | `cluster_admin_principal_arns`, `cluster_plan_principal_arns` |
| `terraform/data.tf` | törölve (az `aws_caller_identity` már nem kell) |
| `terraform/production.tfvars`, `terraform/terraform.tfvars.example` | CI és helyi változóértékek |
| `k8s/overlays/production/kustomization.yaml` | a production overlay |
| `.github/workflows/*.yml`, `.github/dependabot.yml` | a 6 workflow és a Dependabot |
| `scripts/common.sh`, `build-push.sh`, `render.sh`, `teardown.sh` | a helyi scriptek |
| `.gitignore` | `!terraform/production.tfvars`, csak a `k8s/overlays/local/` ignorált |
| `README.md`, `docs/notes.md`, `docs/step-by-step.md` | dokumentáció |

**Helyi ellenőrzések** (AWS nélkül):

```bash
# Formázás mindkét rootban (üres kimenet = rendben)
terraform -chdir=bootstrap fmt -check -recursive
terraform -chdir=terraform fmt -check -recursive

# Szintaxis és típusok (a backend kihagyásával, AWS nélkül)
terraform -chdir=bootstrap init -backend=false && terraform -chdir=bootstrap validate
terraform -chdir=terraform init -backend=false && terraform -chdir=terraform validate
# Success! The configuration is valid.   (mindkettőnél)

# Workflow-k (üres kimenet, exit 0 = rendben)
docker run --rm -v "$PWD:/repo" -w /repo rhysd/actionlint:1.7.12

# Scriptek
for f in scripts/*.sh; do bash -n "$f"; done
docker run --rm -v "$PWD:/mnt" -w /mnt koalaman/shellcheck:stable -x scripts/*.sh

# A production overlay egy ideiglenes másolaton, példa taggel és SG-vel
tmp=$(mktemp -d) && cp -r k8s "$tmp/" && cd "$tmp/k8s/overlays/production"
kustomize edit set image service-a=123456789012.dkr.ecr.eu-west-1.amazonaws.com/demo/service-a:abc123 \
                         service-b=123456789012.dkr.ecr.eu-west-1.amazonaws.com/demo/service-b:abc123
kustomize edit add patch --kind Service --name nginx-proxy \
  --patch '[{"op":"add","path":"/metadata/annotations/service.beta.kubernetes.io~1aws-load-balancer-security-groups","value":"sg-0123456789abcdef0"}]'
kubectl kustomize . | grep -E "image:|security-groups"
cd - && rm -rf "$tmp"
```

A kustomize várt kimenete:

```
    service.beta.kubernetes.io/aws-load-balancer-security-groups: sg-0123456789abcdef0
      - image: 123456789012.dkr.ecr.eu-west-1.amazonaws.com/demo/service-a:abc123
      - image: 123456789012.dkr.ecr.eu-west-1.amazonaws.com/demo/service-b:abc123
      - image: nginxinc/nginx-unprivileged:1.27-alpine
```

(Ha nincs önálló `kustomize` bináris: `alias kustomize='docker run --rm -u $(id -u):$(id -g) -v $PWD:/work -w /work registry.k8s.io/kustomize/kustomize:v5.8.1'`. A `scripts/common.sh` is ezt teszi automatikusan.)

> ⚠️ **Még ne pushold a main-re!** A bootstrap előtt a workflow-k nem kapnák meg a Variables-t és a role-okat, ezért elbuknának. A bootstrap után pedig a main védett, csak PR-ral módosítható.

---

## 4. 🖐 KÉZI LÉPÉS: GitHub token a bootstraphez

A `integrations/github` provider a `GITHUB_TOKEN` környezeti változóból olvassa a tokent. Repó admin jog kell: Variables, Environments és branch protection.

**A) `gh` CLI-vel** (ha telepítve van):

```bash
gh auth login                       # GitHub.com, HTTPS, böngészős bejelentkezés
gh auth status                      # Logged in to github.com account SziNo ... Token scopes: 'repo', ...
export GITHUB_TOKEN=$(gh auth token)
```

**B) Fine-grained personal access tokennel** (`gh` nélkül):

1. GitHub → **Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token**.
2. Token name: `eks-nginx-proxy-pipeline-bootstrap`, Expiration: 7 nap.
3. Repository access: **Only select repositories** → `SziNo/eks-nginx-proxy-pipeline`.
4. Repository permissions:
   - **Administration: Read and write** (branch protection)
   - **Environments: Read and write**
   - **Variables: Read and write**
   - Metadata: Read-only (automatikus)
5. **Generate token**, majd másold ki:
   ```bash
   export GITHUB_TOKEN=github_pat_...
   ```

A tokent ne írd fájlba. A bootstrap után törölheted (Settings → Fine-grained tokens → Delete).

## 5. 🖐 KÉZI LÉPÉS: a bootstrap helyi apply-ja

```bash
cd bootstrap
cp terraform.tfvars.example terraform.tfvars
aws sts get-caller-identity --query Arn --output text   # ezt írd az admin_user_arn-be
```

A `bootstrap/terraform.tfvars` kitöltve (gitignore-olt):

```hcl
region            = "eu-west-1"
cluster_name      = "szino-nginx-proxy-demo"
github_owner      = "SziNo"
github_repository = "eks-nginx-proxy-pipeline"
admin_user_arn    = "arn:aws:iam::<account ID>:user/<user>"
```

```bash
terraform init
# Terraform has been successfully initialized!

terraform plan
```

A plan várt összegzése:

```
Plan: 24 to add, 0 to change, 0 to destroy.
```

A 24 erőforrás:
- S3 (4): bucket, versioning, titkosítás, public access block
- IAM (9): 3 role, 2 managed policy csatolás, a plan lock inline policyja, az apply IAM policy és a csatolása, az app inline policyja
- GitHub (11): 8 Variable, environment, environment ág szabály, branch protection

**Ellenőrizd:** `aws_iam_openid_connect_provider` NINCS a listában (az csak `data` forrás).

```bash
terraform apply
# Apply complete! Resources: 24 added, 0 changed, 0 destroyed.

terraform output
```

A várt kimenet:

```
app_role_arn = "arn:aws:iam::<account ID>:role/gha-eks-nginx-proxy-pipeline-app"
local_tfvars = <<EOT
region                       = "eu-west-1"
...
EOT
state_bucket = "tfstate-<account ID>-eu-west-1-eks-nginx-proxy-pipeline"
state_key = "production/terraform.tfstate"
terraform_apply_role_arn = "arn:aws:iam::<account ID>:role/gha-eks-nginx-proxy-pipeline-terraform-apply"
terraform_plan_role_arn = "arn:aws:iam::<account ID>:role/gha-eks-nginx-proxy-pipeline-terraform-plan"
```

**Ellenőrzés a GitHubon:**
- Settings → Secrets and variables → Actions → **Variables**: 8 változó (`APP_ROLE_ARN`, `AWS_REGION`, `CLUSTER_NAME`, `TF_APPLY_ROLE_ARN`, `TF_PLAN_ROLE_ARN`, `TF_STATE_BUCKET`, `TF_VAR_cluster_admin_principal_arns`, `TF_VAR_cluster_plan_principal_arns`).
- Settings → **Environments** → `production`: Deployment branches and tags: *Selected branches*, `main`; nincs required reviewer.
- Settings → **Branches** → `main`: Require a pull request (0 approvals), Require status checks (`plan-status`, `build-status`, strict), Do not allow bypassing.

**Ellenőrzés az AWS-ben:**

```bash
aws s3api get-bucket-versioning --bucket "$(terraform output -raw state_bucket)"
# { "Status": "Enabled" }
aws iam get-role --role-name gha-eks-nginx-proxy-pipeline-app \
  --query 'Role.AssumeRolePolicyDocument.Statement[0].Condition' --output json
# "token.actions.githubusercontent.com:sub": "repo:SziNo/eks-nginx-proxy-pipeline:environment:production"
cd ..
```

A `bootstrap/terraform.tfstate` HELYBEN marad (gitignore-olt). Ne töröld, ezzel tudod később lebontani a bootstrapet.

## 6. 🖐 KÉZI LÉPÉS: az első init (helyben, opcionális)

A CI-nak nincs szüksége rá, csak a helyi scriptekhez (`build-push.sh`, `render.sh`, `teardown.sh`) és a helyi planhez kell.

```bash
terraform -chdir=bootstrap output -raw local_tfvars > terraform/terraform.tfvars
terraform -chdir=terraform init -reconfigure \
  -backend-config="bucket=$(terraform -chdir=bootstrap output -raw state_bucket)"
```

A várt kimenet:

```
Initializing the backend...
Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.
...
Terraform has been successfully initialized!
```

**State átköltöztetése:** ha a `terraform/` könyvtárban van egy korábbi helyi `terraform.tfstate` egy még élő infrastruktúrával, a `-reconfigure` helyett `-migrate-state` kell. Az init rákérdez, hogy átmásolja-e a state-et az S3-ba (`yes`). Új projektnél (nincs helyi state) nincs mit költöztetni.

```bash
terraform -chdir=terraform plan -var-file=production.tfvars
# Plan: 60 to add, 0 to change, 0 to destroy.
```

## 7. 🖐 KÉZI LÉPÉS: az első PR

```bash
git switch -c ci-pipeline
git add -A
git status --short           # nincs benne: bootstrap/terraform.tfvars, *.tfstate, terraform/terraform.tfvars
git commit -m "GitHub Actions CI/CD pipeline"
git push -u origin ci-pipeline
```

GitHubon: **Compare & pull request** → base: `main` ← compare: `ci-pipeline` → **Create pull request**.

**A PR checkjei:**

| Workflow | Job | Várt eredmény |
| --- | --- | --- |
| terraform-plan | `changes` | ✔ (`Terraform changed: true`) |
| terraform-plan | `plan` | ✔ |
| terraform-plan | `plan-status` | ✔ (kötelező) |
| build-and-push | `changes` | ✔ (`build: true`) |
| build-and-push | `build / check (service-a)`, `build / check (service-b)` | ✔ |
| build-and-push | `build-status` | ✔ (kötelező) |

**A PR kommentje** (a `github-actions` bot írja, minden új commitnál ugyanezt frissíti):

```
### Terraform plan
| fmt | init | validate | plan |
| success | success | success | success |
▶ Plan (commit abc1234)
   ...
   Plan: 60 to add, 0 to change, 0 to destroy.
```

**Nézd át a plan-t**, főleg ezeket:
- `aws_eks_access_entry.admin` ×3, `aws_eks_access_entry.plan` ×1;
- `aws_ecr_repository` `image_tag_mutability = "IMMUTABLE"`;
- törlés nincs.

## 8. 🖐 KÉZI LÉPÉS: merge

**Merge pull request** (vagy Squash and merge). A main-en két workflow indul:

**terraform-apply** (Actions → terraform-apply):

1. `apply` (kb. 15–20 perc): `Apply complete! Resources: 60 added, 0 changed, 0 destroyed.`
2. `build / push (service-a)`, `build / push (service-b)`: a summary-ban `<registry>/<cluster>/service-a:<SHA>: feltöltve`.
3. `deploy / deploy`:
   - `kubectl apply`:
     ```
     namespace/demo created
     configmap/nginx-proxy-conf created
     service/nginx-proxy created
     service/service-a created
     service/service-b created
     deployment.apps/service-a created
     deployment.apps/service-b created
     daemonset.apps/nginx-proxy created
     ```
   - `Wait for rollout`: `deployment "service-a" successfully rolled out`, majd ugyanez a `service-b`-re, végül `daemon set "nginx-proxy" successfully rolled out`
   - `Wait for NLB hostname`: `NLB: k8s-demo-nginxpro-xxxxxxxxxx.elb.eu-west-1.amazonaws.com`
   - `Smoke test` (az első NLB-nél pár perc újrapróbálkozással):
     ```
     /api/sa: Hello from Service A!
     /api/sb: Hello from Service B!
     ```
   - a job summary-ban az NLB címe; a Deployments oldalon a `production` environment linkje az NLB-re mutat.

**build-and-push** (párhuzamosan indul, mert a PR a `k8s/`-t és a workflow fájlokat is érintette):
- `changes`: `A pushban a terraform-apply.yml által figyelt fájlok is változtak: az buildel és deployol.` → `build: false`
- `build`, `deploy`: skipped; `build-status`: ✔

## 9. Ellenőrzés a kész rendszeren

```bash
aws eks update-kubeconfig --region eu-west-1 --name szino-nginx-proxy-demo
# Added new context arn:aws:eks:eu-west-1:<account ID>:cluster/szino-nginx-proxy-demo to ~/.kube/config

kubectl get nodes
# 3 node, STATUS Ready, VERSION v1.37.x

kubectl -n demo get pods -o wide
# nginx-proxy-xxxxx   1/1 Running  (3 db, mindhárom node-on)
# service-a-xxxxx     1/1 Running  (2 db)
# service-b-xxxxx     1/1 Running  (2 db)

kubectl -n demo get deploy service-a -o jsonpath='{.spec.template.spec.containers[0].image}'; echo
# <account ID>.dkr.ecr.eu-west-1.amazonaws.com/szino-nginx-proxy-demo/service-a:<a merge commit SHA-ja>
git rev-parse origin/main    # ugyanez a SHA

NLB=$(kubectl -n demo get svc nginx-proxy -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl http://$NLB/api/sa      # Hello from Service A!
curl http://$NLB/api/sb      # Hello from Service B!
curl http://$NLB/            # Not found. Try /api/sa or /api/sb

aws ecr describe-images --repository-name szino-nginx-proxy-demo/service-a \
  --query 'imageDetails[].imageTags[]' --output text
# <SHA>

aws s3 ls "s3://$(terraform -chdir=bootstrap output -raw state_bucket)/production/"
# ... terraform.tfstate
```

## 10. Egy alkalmazás változás végig a pipeline-on

```bash
git switch main && git pull
git switch -c sa-message
sed -i 's/Hello from Service A!/Hello from Service A! (v2)/' src/service-a/app.py
git commit -am "service-a: v2 message"
git push -u origin sa-message
```

A PR-on:
- `build-and-push`: `check (service-a)` és `check (service-b)` lefut ✔;
- `terraform-plan`: `changes` → `Terraform changed: false`, a `plan` skipped, a `plan-status` ✔.

Merge után csak a **build-and-push** indul: `changes` → `build: true`, majd build és push (új SHA tag), végül deploy.

```bash
curl http://$NLB/api/sa      # Hello from Service A! (v2)
```

## 11. Lebontás

**A) A destroy workflow:** Actions → **destroy** → Run workflow → Branch: `main`, a mezőbe: `destroy` → Run.

A várt lépések:
1. `Check cluster`: létezik.
2. `Find NLB`: `NLB: k8s-demo-... arn:aws:elasticloadbalancing:...`
3. `kubectl delete`: `namespace "demo" deleted`, `service "nginx-proxy" deleted`, …
4. `Wait for NLB deletion`: hiba nélkül tér vissza.
5. `Terraform destroy`: `Destroy complete! Resources: 60 destroyed.`

Bármi más beírt szónál a `destroy` job **skipped** lesz, és semmi sem törlődik.

**Ellenőrzés** (mindegyik üres kimenet):

```bash
aws elbv2 describe-load-balancers --query 'LoadBalancers[].LoadBalancerName' --output text
aws ec2 describe-nat-gateways --filter Name=state,Values=available --query 'NatGateways[].NatGatewayId' --output text
aws eks list-clusters --query 'clusters' --output text
```

**B) Helyben ugyanez:** `./scripts/teardown.sh`. Ehhez a 6. lépés helyi initje kell, és a destroy előtt rákérdez.

## 12. 🖐 KÉZI LÉPÉS: a bootstrap lebontása (csak a projekt végén)

> **A GitHub OIDC providert SOHA ne töröld.** Megosztott, mások is használják. A bootstrap csak hivatkozik rá, a destroy nem nyúl hozzá.

```bash
BUCKET=$(terraform -chdir=bootstrap output -raw state_bucket)

# A bucket kiürítése az összes verzióval együtt (a versioning miatt az "s3 rm" nem elég)
aws s3api delete-objects --bucket "$BUCKET" --delete "$(aws s3api list-object-versions --bucket "$BUCKET" \
  --query '{Objects: [Versions, DeleteMarkers][][].{Key: Key, VersionId: VersionId}}' --output json)"

# bootstrap/s3.tf: prevent_destroy = true → false
export GITHUB_TOKEN=$(gh auth token)      # vagy a PAT
terraform -chdir=bootstrap destroy
# Destroy complete! Resources: 24 destroyed.
```

A branch protection és az environment is törlődik, a repó újra szabadon pusholható.

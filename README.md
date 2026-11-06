# EKS nginx proxy – GitHub Actions CI/CD pipeline

Két Flask szolgáltatás (`/api/sa`, `/api/sb`) EKS-en, egy nginx reverse proxy DaemonSet mögött, amelyet egy internet-facing NLB tesz elérhetővé. Az infrastruktúra Terraformmal készül, az alkalmazás Kustomize-zal települ. **Mindent GitHub Actions automatizál**, OIDC-vel, access key nélkül. Kézi lépés csak a bootstrap egyszeri helyi apply-ja és a PR-ok áttekintése.

## Architektúra

```
                         GitHub (SziNo/eks-nginx-proxy-pipeline)
  ┌───────────────────────────────────────────────────────────────────────────────────┐
  │  PR ─▶ terraform-plan.yml  (fmt, validate, plan → PR komment)    plan-status  ✔  │
  │     └▶ build-and-push.yml  (docker build, push nélkül)           build-status ✔  │
  │                                                                                   │
  │  merge a main-re                                                                  │
  │   ├─ terraform/** ─▶ terraform-apply.yml: apply ─▶ _build.yml ─▶ _deploy.yml      │
  │   └─ src/**, k8s/** ─▶ build-and-push.yml:        _build.yml ─▶ _deploy.yml       │
  │      (ha a terraform/ is változott, ez kimarad: a terraform-apply.yml csinálja)   │
  └─────────────┬───────────────────────────────────────────────────────────────────┘
                │ OIDC token (sub: pull_request / environment:production)
                ▼
  AWS (eu-west-1)   IAM role-ok: terraform-plan, terraform-apply, app
  ┌───────────────────────────────────────────────────────────────────────────────────┐
  │  S3: Terraform state (+ .tflock)        ECR: <cluster>/service-a, service-b       │
  │                                                                                   │
  │  VPC ── publikus subnetek: NLB, NAT gateway                                       │
  │      └─ privát subnetek: EKS managed node group (3 × t3.medium, Bottlerocket)     │
  │                                                                                   │
  │  Internet ─▶ NLB :80 ─▶ NodePort ─▶ nginx (DaemonSet) ─┬▶ service-a (2 pod)       │
  │                                                         └▶ service-b (2 pod)       │
  │  AWS Load Balancer Controller (Helm, IRSA) hozza létre az NLB-t a Service-ből     │
  └───────────────────────────────────────────────────────────────────────────────────┘
```

| Workflow | Mi indítja | Mit csinál |
| --- | --- | --- |
| `terraform-plan.yml` | PR a main-re, `workflow_dispatch` | Ha a `terraform/` változott: `fmt -check`, `init`, `validate`, `plan`; a plan PR kommentként (frissül, nem halmozódik) és job summary-ként |
| `terraform-apply.yml` | push a main-re (`terraform/**` és a saját, valamint a hívott workflow fájlok), `workflow_dispatch` | `apply -auto-approve`, utána build + deploy a commit SHA-val |
| `build-and-push.yml` | push a main-re (`src/**`, `k8s/**`, a saját és a hívott workflow fájlok), PR, `workflow_dispatch` | PR: build push nélkül. main: build, push az ECR-be (tag = commit SHA), deploy |
| `_build.yml` | `workflow_call` | Mátrix a két szolgáltatásra; `check` job (push nélkül) vagy `push` job (production environment) |
| `_deploy.yml` | `workflow_call` | `kustomize edit`, `kubectl apply -k`, rollout, NLB, smoke teszt |
| `destroy.yml` | csak `workflow_dispatch`, `destroy` megerősítéssel | `kubectl delete`, megvárja az NLB törlését, `terraform destroy` |

## A repó szerkezete

```
bootstrap/                  külön Terraform root, HELYI state: S3 state bucket, 3 IAM role (OIDC),
                            GitHub Variables, production environment, branch protection
terraform/                  a fő Terraform (remote state S3-ban)
  production.tfvars         a nem érzékeny értékek (commitolt)
  modules/vpc, eks, ecr, lb-controller   saját modulok
src/service-a, service-b    Flask app + multi-stage Dockerfile
k8s/base/                   a közös manifestek (namespace, Deploymentek, nginx ConfigMap/DaemonSet, Service)
k8s/overlays/production/    a production overlay; a CI csak a workspace-ben egészíti ki (image, SG)
.github/workflows/          a fenti hat workflow
.github/dependabot.yml      heti frissítés az actionökre
scripts/                    helyi megfelelők: build-push.sh, render.sh, teardown.sh (+ common.sh)
docs/notes.md               1on1 felkészítő
docs/step-by-step.md        a teljes folyamat lépésről lépésre, a várt kimenetekkel
```

## Használat a nulláról

Előfeltételek: Terraform **1.16.4**, AWS CLI v2 (a saját IAM userrel bejelentkezve), kubectl 1.37, git, és egy GitHub token (`gh` CLI vagy fine-grained PAT). A részletes változat, a várt kimenetekkel: [docs/step-by-step.md](docs/step-by-step.md).

### 1. Bootstrap (egyszer, helyben)

```bash
cd bootstrap
cp terraform.tfvars.example terraform.tfvars        # régió, cluster név, GitHub owner/repó, a saját IAM user ARN-je
aws sts get-caller-identity --query Arn --output text   # ez az admin_user_arn

# GitHub token a github providernek (repó admin jog kell: Variables, Environments, branch protection)
export GITHUB_TOKEN=$(gh auth token)                # vagy egy fine-grained PAT, lásd step-by-step.md

terraform init
terraform plan        # Plan: 24 to add; ellenőrizd, hogy OIDC provider NINCS a létrehozandók között
terraform apply
terraform output
```

Létrejön: S3 state bucket (versioning, SSE, public access block, `prevent_destroy`), három IAM role, a GitHub Variables, a `production` environment (csak a main ágról) és a main branch protectionje (PR kötelező, `plan-status` és `build-status` check, `enforce_admins`).

### 2. A fő Terraform inicializálása helyben (opcionális, a helyi scriptekhez)

```bash
cd ../terraform
terraform -chdir=../bootstrap output -raw local_tfvars > terraform.tfvars   # gitignore-olt
terraform init -backend-config="bucket=$(terraform -chdir=../bootstrap output -raw state_bucket)"
terraform plan -var-file=production.tfvars
```

Ha korábban helyi state-tel már futott ez a projekt, és az infrastruktúra áll, az init rákérdez a state átköltöztetésére (`-migrate-state`). Új infrastruktúránál nincs mit költöztetni.

### 3. Az első PR és merge

```bash
git switch -c ci-pipeline
git add -A && git commit -m "GitHub Actions CI/CD pipeline"
git push -u origin ci-pipeline
```

PR a main-re a GitHubon. Lefut a `terraform-plan` (a plan kommentben: a teljes infrastruktúra létrehozása) és a `build-and-push` (push nélküli build). Ha a `plan-status` és a `build-status` zöld, mergeld. A main-en elindul a `terraform-apply.yml`: apply (kb. 15–20 perc), build, push, deploy. A `build-and-push.yml` ilyenkor nem deployol, mert a `terraform/` is változott. A deploy job summary-jában ott az NLB DNS neve.

### 4. A napi munka

- **Alkalmazás változás** (`src/`): PR (build ellenőrzés) → merge → `build-and-push.yml`: új image a commit SHA taggel, deploy.
- **Infrastruktúra változás** (`terraform/`): PR (a plan kommentben) → merge → `terraform-apply.yml`: apply, build (ha a tag még nincs meg), deploy.
- **Mindkettő egy pushban:** csak a `terraform-apply.yml` buildel és deployol, az apply után.

## Tesztelés a kész rendszeren

```bash
aws eks update-kubeconfig --region eu-west-1 --name <cluster_name>
kubectl get nodes -o wide                                  # 3 node, 3 AZ
kubectl -n demo get pods -o wide                           # nginx minden node-on, A és B 2-2 pod
kubectl -n demo get deploy -o wide                         # az image tag a commit SHA
NLB=$(kubectl -n demo get svc nginx-proxy -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl http://$NLB/api/sa                                    # Hello from Service A!
curl http://$NLB/api/sb                                    # Hello from Service B!
curl -i http://$NLB/                                       # 404 Not found. Try /api/sa or /api/sb

# AWS oldali ellenőrzések
aws ecr describe-images --repository-name <cluster_name>/service-a \
  --query 'imageDetails[].imageTags' --output text         # commit SHA tagek
aws s3 ls s3://<state bucket>/production/                  # terraform.tfstate
aws elbv2 describe-target-health --target-group-arn $(aws elbv2 describe-target-groups \
  --query "TargetGroups[?starts_with(TargetGroupName,'k8s-demo-')].TargetGroupArn" --output text)
aws iam list-roles --query "Roles[?starts_with(RoleName,'gha-')].RoleName"
```

## Lebontás

1. **Actions → destroy → Run workflow**, a mezőbe: `destroy`. Törli a Kubernetes erőforrásokat, megvárja az NLB eltűnését, majd `terraform destroy`. Helyben ugyanez: `./scripts/teardown.sh`.
2. **A bootstrap kézzel**, ha a projektnek vége:
   ```bash
   aws s3 rm s3://<state bucket> --recursive                         # a verziókat nem törli
   aws s3api delete-objects --bucket <state bucket> --delete "$(aws s3api list-object-versions \
     --bucket <state bucket> --query '{Objects: [Versions, DeleteMarkers][][].{Key: Key, VersionId: VersionId}}' --output json)"
   # bootstrap/s3.tf: prevent_destroy = true → false, majd:
   cd bootstrap && terraform destroy
   ```
3. **A GitHub OIDC providert SOHA ne töröld**: megosztott, mások is használják. A bootstrap csak data source-szal hivatkozik rá, ezért a destroy sem nyúl hozzá.

## Döntések röviden

- **OIDC role-onként szűk `sub` feltétellel.** A plan role-t a PR-ok (és a main ágról indított kézi plan) veheti fel, az apply és az app role-t csak a `production` environment jobjai. Environment használatakor a `sub` `environment:production`, nem `ref:refs/heads/main`. Azt, hogy csak a main ág telepíthet, az environment branch policyja biztosítja.
- **A plan role jogai: `ReadOnlyAccess` + a `.tflock` írása.** A Kubernetesben `AmazonEKSAdminViewPolicy` kapcsolódik hozzá, csak a `kube-system` namespace-re. A Helm a release-t Secretekben tárolja, és ezeket a `view` policy nem olvashatja.
- **Az apply role jogai: `PowerUserAccess` + egy saját IAM policy.** Az IAM jogok a cluster név előtagjára szűkülnek, a csatolható policyk listája zárt, és a GitHub OIDC providerhez nem fér hozzá. Nem `AdministratorAccess`. A GitHub Actions role-ok neve `gha-` előtagú, hogy az apply role ne írhassa át őket.
- **Az app role cluster admin**, mert a manifestek namespace-t is létrehoznak. *Továbbfejlesztés:* a namespace-t a Terraform hozza létre, az app role pedig csak a `demo` namespace-ben kap jogot (pl. `AmazonEKSEditPolicy` namespace scope-pal).
- **Partial backend:** a bucket neve account-specifikus, ezért az init kapja meg, nem a kód.
- **Account-specifikus értékek a GitHub Variables-ben**, a kódban nincs account ID vagy ARN. Secret nem kell (OIDC).
- **A tag a teljes commit SHA, az ECR `IMMUTABLE`.** Egy tag soha nem íródik felül, ha pedig már létezik, a build kimarad.
- **Sorrend:** `needs` a workflow-n belül, `workflow_call` a build és a deploy újrahasznosításához, `concurrency` (`terraform-production`, `deploy-production`, megszakítás nélkül). Ha egy pushban a `terraform/` és a `src/` is változik, a `build-and-push.yml` git diff alapján félreáll.
- **Required checkek path szűrővel:** a PR triggeren nincs `paths`, mert a kötelező check ki nem futó workflow mellett örökre függőben maradna. A `changes` job git diff-fel dönt, a stabil nevű gyűjtő job (`plan-status`, `build-status`) a kötelező check.
- **Az actionök commit SHA-ra rögzítve**, a Dependabot hetente frissíti őket.

> **Láthatóság:** a repó publikus, ezért a workflow logok, a job summary-k és a PR-ba írt plan komment is nyilvánosak. Ezekben az AWS account ID látszik (ARN-ekben, az ECR registry címében). Az AWS szerint az account ID nem titok, de ezért sem a kódba, sem a PR-okba ne kerüljön valódi titok.

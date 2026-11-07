# Lépésről lépésre

A teljes folyamat a template-ből létrehozott repótól a lebontásig, sorrendben, a parancsokkal és a várt kimenetekkel. Minden parancs a projekt gyökeréből fut, hacsak a lépés mást nem mond. A `<...>` helyére a saját értéked kerül.

> 🖐 **KÉZI LÉPÉS** jelöli azokat a lépéseket, amelyeket neked kell elvégezned. Ilyen a bootstrap helyi apply-ja, a GitHub token, az első init és az első PR. Minden más a GitHub Actionsben fut.

A 3. lépés várt kimenetei valódiak (lásd ott). Az AWS-től függő kimenetek (ID-k, időtartamok) **példák**, a te futásodban az értékek mások lesznek, a szerkezetük ugyanez.

---

## Tartalomjegyzék

- [0. Előfeltételek](#0-előfeltételek)
- [1. A repó létrehozása a template-ből](#1-a-repó-létrehozása-a-template-ből)
- [2. Az apps/ → src/ átnevezés](#2-az-apps--src-átnevezés)
- [3. A pipeline felépítése a régi projektből](#3-a-pipeline-felépítése-a-régi-projektből)
  - [3.1 Munkaág létrehozása](#31-munkaág-létrehozása)
  - [3.2 .gitignore](#32-gitignore)
  - [3.3 bootstrap/versions.tf](#33-bootstrapversionstf)
  - [3.4 bootstrap/providers.tf](#34-bootstrapproviderstf)
  - [3.5 bootstrap/variables.tf](#35-bootstrapvariablestf)
  - [3.6 bootstrap/data.tf](#36-bootstrapdatatf)
  - [3.7 bootstrap/locals.tf](#37-bootstraplocalstf)
  - [3.8 bootstrap/s3.tf](#38-bootstraps3tf)
  - [3.9 bootstrap/iam.tf](#39-bootstrapiamtf)
  - [3.10 bootstrap/github.tf](#310-bootstrapgithubtf)
  - [3.11 bootstrap/outputs.tf](#311-bootstrapoutputstf)
  - [3.12 bootstrap/terraform.tfvars.example](#312-bootstrapterraformtfvarsexample)
  - [3.13 bootstrap/.terraform.lock.hcl és az első validate](#313-bootstrapterraformlockhcl-és-az-első-validate)
  - [3.14 terraform/versions.tf: partial S3 backend és pontos Terraform verzió](#314-terraformversionstf-partial-s3-backend-és-pontos-terraform-verzió)
  - [3.15 terraform/variables.tf: a két ARN lista](#315-terraformvariablestf-a-két-arn-lista)
  - [3.16 terraform/locals.tf: a Helm release namespace-e](#316-terraformlocalstf-a-helm-release-namespace-e)
  - [3.17 terraform/modules/eks/variables.tf: az új modul bemenetek](#317-terraformmoduleseksvariablestf-az-új-modul-bemenetek)
  - [3.18 terraform/modules/eks/access.tf: a plan role olvasási joga](#318-terraformmoduleseksaccesstf-a-plan-role-olvasási-joga)
  - [3.19 terraform/main.tf: az új változók átadása](#319-terraformmaintf-az-új-változók-átadása)
  - [3.20 terraform/data.tf törlése](#320-terraformdatatf-törlése)
  - [3.21 terraform/outputs.tf: kommentek](#321-terraformoutputstf-kommentek)
  - [3.22 terraform/modules/ecr/main.tf: komment](#322-terraformmodulesecrmaintf-komment)
  - [3.23 terraform/modules/eks/outputs.tf: output leírás](#323-terraformmoduleseksoutputstf-output-leírás)
  - [3.24 terraform/modules/eks/security-groups.tf: komment](#324-terraformmodulesekssecurity-groupstf-komment)
  - [3.25 terraform/production.tfvars](#325-terraformproductiontfvars)
  - [3.26 terraform/terraform.tfvars.example](#326-terraformterraformtfvarsexample)
  - [3.27 k8s/base: az image kommentek](#327-k8sbase-az-image-kommentek)
  - [3.28 k8s/overlays/production/kustomization.yaml](#328-k8soverlaysproductionkustomizationyaml)
  - [3.29 scripts/common.sh](#329-scriptscommonsh)
  - [3.30 scripts/build-push.sh](#330-scriptsbuild-pushsh)
  - [3.31 scripts/render.sh](#331-scriptsrendersh)
  - [3.32 scripts/teardown.sh](#332-scriptsteardownsh)
  - [3.33 .github/workflows/_build.yml](#333-githubworkflows_buildyml)
  - [3.34 .github/workflows/_deploy.yml](#334-githubworkflows_deployyml)
  - [3.35 .github/workflows/terraform-plan.yml](#335-githubworkflowsterraform-planyml)
  - [3.36 .github/workflows/terraform-apply.yml](#336-githubworkflowsterraform-applyyml)
  - [3.37 .github/workflows/build-and-push.yml](#337-githubworkflowsbuild-and-pushyml)
  - [3.38 .github/workflows/destroy.yml](#338-githubworkflowsdestroyyml)
  - [3.39 .github/dependabot.yml](#339-githubdependabotyml)
  - [3.40 README.md](#340-readmemd)
  - [3.41 docs/notes.md](#341-docsnotesmd)
  - [3.42 docs/step-by-step.md](#342-docsstep-by-stepmd)
  - [3.43 Teljes ellenőrzés](#343-teljes-ellenőrzés)
- [4. 🖐 KÉZI LÉPÉS: GitHub token a bootstraphez](#4--kézi-lépés-github-token-a-bootstraphez)
- [5. 🖐 KÉZI LÉPÉS: a bootstrap helyi apply-ja](#5--kézi-lépés-a-bootstrap-helyi-apply-ja)
- [6. 🖐 KÉZI LÉPÉS: az első init (helyben, opcionális)](#6--kézi-lépés-az-első-init-helyben-opcionális)
- [7. 🖐 KÉZI LÉPÉS: commit, push és az első PR](#7--kézi-lépés-commit-push-és-az-első-pr)
- [8. 🖐 KÉZI LÉPÉS: merge](#8--kézi-lépés-merge)
- [9. Ellenőrzés a kész rendszeren](#9-ellenőrzés-a-kész-rendszeren)
- [10. Egy alkalmazás változás végig a pipeline-on](#10-egy-alkalmazás-változás-végig-a-pipeline-on)
- [11. Lebontás](#11-lebontás)
- [12. 🖐 KÉZI LÉPÉS: a bootstrap lebontása (csak a projekt végén)](#12--kézi-lépés-a-bootstrap-lebontása-csak-a-projekt-végén)

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

A 3. lépés ellenőrzései dockerből futtatják az actionlintet, a shellchecket és (ha nincs telepítve) a kustomize-t. Ha később internet nélkül dolgozol, ezeket előre töltsd le, a PyYAML pedig a dependabot.yml ellenőrzéséhez kell (a Terraform providerek letöltéséhez az init alatt mindenképp internet kell):

```bash
docker pull rhysd/actionlint:1.7.12
docker pull koalaman/shellcheck:stable
docker pull registry.k8s.io/kustomize/kustomize:v5.8.1
python3 -c 'import yaml'      # hiba nélkül fut le; ha nem: sudo apt install python3-yaml
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

Várt kimenet (ebben a pontban, a valódi futásból):

```text
./README.md:44:apps/service-a/                  Flask app + multi-stage Dockerfile + .dockerignore + requirements.txt
./README.md:45:apps/service-b/                  ugyanez a B szolgáltatásnak
./README.md:116:docker build -t service-a:local apps/service-a
./scripts/build-push.sh:18:  docker buildx build --platform linux/amd64 -t "${REGISTRY}/${CLUSTER}/${svc}:${TAG}" --push "apps/${svc}"
./k8s/base/service-b.yaml:1:apiVersion: apps/v1
./k8s/base/nginx-daemonset.yaml:1:apiVersion: apps/v1
./k8s/base/service-a.yaml:1:apiVersion: apps/v1
```

A régi README-ben és a `scripts/build-push.sh`-ban még előfordul az `apps/`: ezeket a 3. lépés cseréli le (3.30 és 3.40), a 3.43 teljes ellenőrzése után már csak a három `apiVersion: apps/v1` sor marad.

Az `apiVersion: apps/v1` sorok **NEM érintettek**: ez a Kubernetes API csoportja (Deployment, DaemonSet), nem könyvtár, nem szabad átírni.

## 3. A pipeline felépítése a régi projektből

Ez a lépés a 2. lépés utáni állapotból (`rename app to src` commit) pontosan a kész pipeline-t állítja elő, sok kis allépésben, abban a sorrendben, ahogy felépítenéd. Minden allépés leírja, mit és miért csinálunk, megadja a pontos tartalmat, és egy ellenőrzéssel zárul, amely abban a pontban már lefuttatható.

- **Új fájl:** hozd létre a megadott útvonalon, a kódblokk teljes tartalmával.
- **Módosított fájl, csere:** keresd meg a fájlban a „Keresd meg” blokkot (pontosan egyszer fordul elő), és cseréld le a „Cseréld erre” blokkra. Több cserénél sorban haladj. A sorszámok az eredeti (a csere előtti) fájlra vonatkoznak.
- **Módosított fájl, teljes tartalom:** a fájl teljes tartalmát cseréld le a kódblokkra.
- A kódblokkok négy backtickkel (````` ```` `````) kezdődnek, mert némelyik fájlban három backtickes blokk is van; a fájlba csak a blokk belseje kerül.
- Minden fájl sortöréssel végződik, **kivéve** ahol az allépés mást mond (`.gitignore`, `terraform/locals.tf`, `terraform/outputs.tf`, `terraform/modules/ecr/main.tf`, `terraform/modules/eks/variables.tf`): ezeknél a szerkesztő ne tegyen sortörést a fájl végére.
- A várt kimenetek valódiak: egy friss klónon, az útmutató blokkjainak sorban történő végrehajtásával készültek.

### 3.1 Munkaág létrehozása

Minden változás egy külön ágon készül, mert a main-re a bootstrap után már csak PR-ral lehet írni (branch protection), és a pipeline első futása is egy PR lesz. Az ág neve `feature/pipeline`. A workflow-k csak main-re érkező pushra, main-re nyitott PR-ra és kézi indításra futnak, ezért ezen az ágon a commit és a push bármikor biztonságos.

<!-- sbs:run -->
````bash
git switch -c feature/pipeline
````

**Ellenőrzés:**

<!-- sbs:check 3.1 -->
```bash
git branch --show-current
```

Várt kimenet:

```text
feature/pipeline
```

### 3.2 .gitignore

Két szabály változik. A `*.tfvars` továbbra is kizár minden változóértéket (account ID, ARN-ek kerülnének bele), de a `terraform/production.tfvars` kivétel: ez a nem érzékeny production konfiguráció, a CI ebből olvas, ezért commitolni kell. A `k8s/overlays/` helyett csak a `k8s/overlays/local/` ignorált, mert a production overlay mostantól commitolt fájl, a helyi (render.sh által generált) pedig továbbra sem kerülhet a gitbe. A fájl végén nincs sortörés, ezt a szerkesztő ne tegye hozzá.

Módosított fájl: `.gitignore`, 1 csere.

**Csere 1/1** (az eredeti fájl 13–22. sora). Keresd meg:

<!-- sbs:old .gitignore -->
````text
*_override.tf.json

# Terraform változóértékek: a valódi nem, a minta igen
*.tfvars
!*.tfvars.example

# Kubernetes: a render.sh által generált overlay
k8s/overlays/

# Python
````

Cseréld erre:

<!-- sbs:repl .gitignore -->
````text
*_override.tf.json

# Terraform változóértékek: a valódi (account-specifikus) nem, a minta és a production igen
*.tfvars
!*.tfvars.example
!terraform/production.tfvars

# Kubernetes: a render.sh által generált helyi overlay (a production overlay commitolt)
k8s/overlays/local/

# Python
````

**Ellenőrzés:**

<!-- sbs:check 3.2 -->
```bash
git check-ignore -v bootstrap/terraform.tfvars bootstrap/terraform.tfstate \
  terraform/terraform.tfvars k8s/overlays/local/kustomization.yaml
git check-ignore -q terraform/production.tfvars || echo "terraform/production.tfvars: nem ignorált"
git check-ignore -q k8s/overlays/production/kustomization.yaml || echo "k8s/overlays/production/kustomization.yaml: nem ignorált"
```

Várt kimenet:

```text
.gitignore:16:*.tfvars	bootstrap/terraform.tfvars
.gitignore:3:*.tfstate	bootstrap/terraform.tfstate
.gitignore:16:*.tfvars	terraform/terraform.tfvars
.gitignore:21:k8s/overlays/local/	k8s/overlays/local/kustomization.yaml
terraform/production.tfvars: nem ignorált
k8s/overlays/production/kustomization.yaml: nem ignorált
```

### 3.3 bootstrap/versions.tf

A `bootstrap/` egy külön Terraform root: a CI előfeltételeit hozza létre (state bucket, IAM role-ok, GitHub beállítások), ezért nem lehet a CI része, és a saját state-je sem lehet abban a bucketben, amelyet létrehoz: helyi state-tel, egyszer, kézzel fut. A `required_version` pontosan `1.16.4`, ugyanaz, mint a fő rootban és a CI-ban. Két provider kell: az `aws` és a GitHub beállításokhoz az `integrations/github`, amely a tokent a `GITHUB_TOKEN` környezeti változóból olvassa, így a kódban nincs titok.

<!-- sbs:run -->
````bash
mkdir -p bootstrap
````

Új fájl: `bootstrap/versions.tf`.

<!-- sbs:new bootstrap/versions.tf -->
````hcl
# A bootstrap a CI/CD előfeltételeit hozza létre: S3 state bucket, a GitHub Actions IAM
# role-jai és a GitHub repó beállításai. Egyszer fut, HELYBEN, helyi state-tel: a remote
# state bucket itt jön létre, ezért ennek a rootnak a state-je még nem lehet benne.
terraform {
  # Pontosan ugyanaz a verzió, mint a terraform/ rootban és a CI-ban (setup-terraform).
  required_version = "1.16.4"

  required_providers {
    # AWS provider: S3 bucket, IAM role-ok és policyk.
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    # GitHub provider: repository variables, environment, branch protection.
    # A tokent a GITHUB_TOKEN környezeti változóból olvassa (export GITHUB_TOKEN=$(gh auth token)).
    github = {
      source  = "integrations/github"
      version = "~> 6.13"
    }
  }
}
````

**Ellenőrzés:**

<!-- sbs:check 3.3 -->
```bash
terraform -chdir=bootstrap fmt -check -recursive && echo "fmt OK"
```

Várt kimenet:

```text
fmt OK
```

### 3.4 bootstrap/providers.tf

Provider blokkok: az AWS a változóból kapja a régiót, a `default_tags` minden erőforrásra ráteszi a projekt nevét és a `ManagedBy = terraform-bootstrap` taget, így a konzolban látszik, mi jött a bootstrapből. A GitHub providernek csak az owner kell, a token a környezetből jön.

Új fájl: `bootstrap/providers.tf`.

<!-- sbs:new bootstrap/providers.tf -->
````hcl
# AWS provider: a helyi AWS hitelesítéssel fut (a saját IAM userrel), a régiót változóból kapja.
# A default_tags minden AWS erőforrásra rákerül.
provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = var.github_repository
      ManagedBy = "terraform-bootstrap"
    }
  }
}

# GitHub provider: az owner a repó gazdája; a token a GITHUB_TOKEN környezeti változóból jön,
# ezért a kódban és a tfvars-ban nincs titok.
provider "github" {
  owner = var.github_owner
}
````

**Ellenőrzés:**

<!-- sbs:check 3.4 -->
```bash
terraform -chdir=bootstrap fmt -check -recursive && echo "fmt OK"
```

Várt kimenet:

```text
fmt OK
```

### 3.5 bootstrap/variables.tf

A bootstrap bemenetei: régió, cluster név, a GitHub owner és repó, és a saját IAM userem ARN-je (ő lesz cluster admin a helyi kubectl-hez). Mindegyik kap validációt, hogy egy elírás már a plan előtt kiderüljön; a cluster név hosszát az IAM role nevek 64 karakteres korlátja miatt kell korlátozni.

Új fájl: `bootstrap/variables.tf`.

<!-- sbs:new bootstrap/variables.tf -->
````hcl
variable "region" {
  description = "AWS régió: itt jön létre a state bucket, és ezt kapja a CI (AWS_REGION variable)"
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}(-[a-z]+)+-[0-9]$", var.region))
    error_message = "Érvényes AWS régió kell, pl. eu-west-1."
  }
}

variable "cluster_name" {
  description = "Az EKS cluster neve (CLUSTER_NAME variable); az apply role IAM jogai erre az előtagra szűkülnek"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,38}$", var.cluster_name))
    error_message = "Kisbetű, szám és kötőjel, legfeljebb 39 karakter (az IAM role nevek hossza miatt)."
  }
}

variable "github_owner" {
  description = "A GitHub repó gazdája (user vagy organization), pl. SziNo"
  type        = string
}

variable "github_repository" {
  description = "A GitHub repó neve owner nélkül, pl. eks-nginx-proxy-pipeline"
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9._-]+$", var.github_repository))
    error_message = "A repó neve csak betűt, számot és . _ - jeleket tartalmazhat."
  }
}

variable "admin_user_arn" {
  description = "A saját IAM userem ARN-je: cluster admin lesz, hogy helyben is használhassam a kubectl-t"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]{12}:user/.+$", var.admin_user_arn))
    error_message = "IAM user ARN kell, pl. arn:aws:iam::123456789012:user/nev."
  }
}
````

**Ellenőrzés:**

<!-- sbs:check 3.5 -->
```bash
terraform -chdir=bootstrap fmt -check -recursive && echo "fmt OK"
```

Várt kimenet:

```text
fmt OK
```

### 3.6 bootstrap/data.tf

A meglévő dolgok lekérdezése. Az account ID a bucket nevéhez és az ARN-ekhez kell, így nem kerül a kódba (a repó publikus). A GitHub OIDC provider MÁR LÉTEZIK a megosztott accountban, ezért `data` forrással hivatkozunk rá: ha `resource` lenne, a bootstrap destroy-a mások pipeline-jait is tönkretenné. A `github_repository` a branch protectionhöz szükséges node ID miatt kell.

Új fájl: `bootstrap/data.tf`.

<!-- sbs:new bootstrap/data.tf -->
````hcl
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
````

**Ellenőrzés:**

<!-- sbs:check 3.6 -->
```bash
terraform -chdir=bootstrap fmt -check -recursive && echo "fmt OK"
```

Várt kimenet:

```text
fmt OK
```

### 3.7 bootstrap/locals.tf

Számított értékek egy helyen. A bucket neve kiszámítható (`tfstate-<account>-<régió>-<repó>`), mert az S3 nevek globálisan egyediek. A role-ok előtagja `gha-<repó>`, SZÁNDÉKOSAN nem a cluster neve: az apply role IAM jogai a `<cluster_name>-*` nevekre szólnak, és ha a GitHub Actions role-ok is így kezdődnének, az apply role átírhatná a saját vagy az app role jogait (privilege escalation). Itt van a két kötelező status check neve is (`plan-status`, `build-status`).

Új fájl: `bootstrap/locals.tf`.

<!-- sbs:new bootstrap/locals.tf -->
````hcl
# Számított és közös értékek.
locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition

  # Kiszámítható, globálisan egyedi bucket név (az S3 nevek az egész AWS-ben egyediek, ezért
  # kell bele az account ID és a régió). A repó nevéből kisbetűs, mert az S3 csak ezt engedi.
  state_bucket_name = lower("tfstate-${local.account_id}-${var.region}-${var.github_repository}")

  # A fő Terraform state kulcsa: ugyanez van a terraform/versions.tf backend blokkjában.
  state_key = "production/terraform.tfstate"

  # A GitHub OIDC token sub claimjének eleje: repo:<owner>/<repo>
  github_repo_sub = "repo:${var.github_owner}/${var.github_repository}"

  # A GitHub Actions role-ok névelőtagja. SZÁNDÉKOSAN nem a cluster nevével kezdődik:
  # az apply role IAM jogai a "<cluster_name>-*" nevekre szólnak, így nem tudja átírni
  # sem a saját, sem a másik két GitHub Actions role jogait (privilege escalation ellen).
  role_prefix = "gha-${var.github_repository}"

  # Az EKS cluster ARN-je (az app role eks:DescribeCluster joga ehhez szól).
  cluster_arn = "arn:${local.partition}:eks:${var.region}:${local.account_id}:cluster/${var.cluster_name}"

  # A két alkalmazás ECR repója (a fő Terraform hozza létre, <cluster_name>/<szolgáltatás> névvel).
  services = ["service-a", "service-b"]
  ecr_repository_arns = [
    for svc in local.services : "arn:${local.partition}:ecr:${var.region}:${local.account_id}:repository/${var.cluster_name}/${svc}"
  ]

  # A main ág kötelező status checkjei: a két workflow gyűjtő jobjának neve.
  required_status_checks = ["plan-status", "build-status"]
}
````

**Ellenőrzés:**

<!-- sbs:check 3.7 -->
```bash
terraform -chdir=bootstrap fmt -check -recursive && echo "fmt OK"
```

Várt kimenet:

```text
fmt OK
```

### 3.8 bootstrap/s3.tf

A remote state bucketje négy erőforrással: maga a bucket `prevent_destroy`-jal (a state elvesztése után a Terraform nem tudná, mit kezel), versioning (egy elrontott state visszaállítható), SSE titkosítás és a nyilvános hozzáférés teljes tiltása. Zároláshoz nem kell DynamoDB: a fő Terraform `use_lockfile`-lal egy `.tflock` fájlt ír ugyanide.

Új fájl: `bootstrap/s3.tf`.

<!-- sbs:new bootstrap/s3.tf -->
````hcl
# S3 bucket a fő Terraform remote state-jének. A zárolás a use_lockfile miatt egy .tflock
# fájllal történik ugyanebben a bucketben, ezért DynamoDB tábla nem kell.
resource "aws_s3_bucket" "state" {
  bucket = local.state_bucket_name

  # Védőháló: a state elvesztése után a Terraform nem tudná, mit kezel. A bucketet csak
  # ennek a sornak a kivétele után lehet törölni (lásd README, lebontás).
  lifecycle {
    prevent_destroy = true
  }
}

# Versioning: egy elrontott vagy felülírt state korábbi változata visszaállítható.
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Alapértelmezett titkosítás (SSE-S3). A state érzékeny adatokat is tartalmazhat.
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Nyilvános hozzáférés tiltása mind a négy kapcsolóval (ACL és bucket policy oldalon is).
resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
````

**Ellenőrzés:**

<!-- sbs:check 3.8 -->
```bash
terraform -chdir=bootstrap fmt -check -recursive && echo "fmt OK"
```

Várt kimenet:

```text
fmt OK
```

### 3.9 bootstrap/iam.tf

A három GitHub Actions role (OIDC, access key nélkül). A trust policy `aud = sts.amazonaws.com` és szűk `sub` feltételt köt ki. A plan role `sub`-ja `pull_request` (és a main ágról kézzel indított planhez `ref:refs/heads/main`). Az apply és az app role-é `environment:production`: environmentet használó jobnál a GitHub ezt teszi a tokenbe, NEM a `ref:refs/heads/main`-t, és azt, hogy csak a main használhatja, az environment branch policyja biztosítja. Jogok: a plan `ReadOnlyAccess` + a `.tflock` írása; az apply `PowerUserAccess` (minden, kivéve az IAM-et) + egy saját IAM policy, amely a cluster név előtagra szűkít, csak az EKS-hez szükséges policykat engedi csatolni, és a GitHub OIDC providerhez nem fér hozzá (ezért nem `AdministratorAccess`); az app csak a két ECR repóba pusholhat, és a deployhoz szükséges két Describe hívást kapja.

Új fájl: `bootstrap/iam.tf`.

<!-- sbs:new bootstrap/iam.tf -->
````hcl
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
````

**Ellenőrzés:**

<!-- sbs:check 3.9 -->
```bash
terraform -chdir=bootstrap fmt -check -recursive && echo "fmt OK"
```

Várt kimenet:

```text
fmt OK
```

### 3.10 bootstrap/github.tf

A GitHub beállítások kódként. A role ARN-ek, a bucket és a `TF_VAR_*` értékek repository **Variables**-be kerülnek, nem secretbe: nem titkok, csak account-specifikusak, és a publikus repó kódjába nem valók. A `production` environment jóváhagyás nélküli, de csak a `main` ágról lehet rá deployolni. A main branch protectionje PR-t és a két gyűjtő job (`plan-status`, `build-status`) sikerét követeli meg; jóváhagyás nem kell (egyedül dolgozom), az `enforce_admins` miatt viszont a repó gazdája sem pusholhat közvetlenül.

Új fájl: `bootstrap/github.tf`.

<!-- sbs:new bootstrap/github.tf -->
````hcl
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
````

**Ellenőrzés:**

<!-- sbs:check 3.10 -->
```bash
terraform -chdir=bootstrap fmt -check -recursive && echo "fmt OK"
```

Várt kimenet:

```text
fmt OK
```

### 3.11 bootstrap/outputs.tf

A bucket neve és a három role ARN-je (minden output description-nel). A `local_tfvars` output a helyi használathoz kész `terraform/terraform.tfvars` tartalmat adja ki ugyanazokkal az értékekkel, mint amiket a CI a Variables-ből kap, így a helyi és a CI-os futás nem tér el.

Új fájl: `bootstrap/outputs.tf`.

<!-- sbs:new bootstrap/outputs.tf -->
````hcl
output "state_bucket" {
  description = "A fő Terraform state bucketje (terraform init -backend-config=\"bucket=...\")"
  value       = aws_s3_bucket.state.bucket
}

output "state_key" {
  description = "A fő Terraform state kulcsa a bucketben (a terraform/versions.tf backend blokkjával egyezik)"
  value       = local.state_key
}

output "terraform_plan_role_arn" {
  description = "A PR-os terraform plan role ARN-je (TF_PLAN_ROLE_ARN)"
  value       = aws_iam_role.github["terraform-plan"].arn
}

output "terraform_apply_role_arn" {
  description = "A terraform apply és destroy role ARN-je (TF_APPLY_ROLE_ARN)"
  value       = aws_iam_role.github["terraform-apply"].arn
}

output "app_role_arn" {
  description = "A build és deploy role ARN-je (APP_ROLE_ARN)"
  value       = aws_iam_role.github["app"].arn
}

output "local_tfvars" {
  description = "A terraform/terraform.tfvars tartalma a helyi használathoz (ugyanazok az értékek, mint a CI-ban)"
  value       = <<-EOT
    region                       = "${var.region}"
    cluster_name                 = "${var.cluster_name}"
    cluster_admin_principal_arns = ${local.github_variables["TF_VAR_cluster_admin_principal_arns"]}
    cluster_plan_principal_arns  = ${local.github_variables["TF_VAR_cluster_plan_principal_arns"]}
  EOT
}
````

**Ellenőrzés:**

<!-- sbs:check 3.11 -->
```bash
terraform -chdir=bootstrap fmt -check -recursive && echo "fmt OK"
```

Várt kimenet:

```text
fmt OK
```

### 3.12 bootstrap/terraform.tfvars.example

A bemenetek mintája. A valódi `terraform.tfvars`-t ebből másolod az 5. lépésben; a `.gitignore` miatt az nem kerül a gitbe, a minta igen.

Új fájl: `bootstrap/terraform.tfvars.example`.

<!-- sbs:new bootstrap/terraform.tfvars.example -->
````hcl
# Másold terraform.tfvars névre és töltsd ki (a terraform.tfvars gitignore-olt).
region       = "eu-west-1"
cluster_name = "szino-nginx-proxy-demo" # az IAM nevek fiókszinten egyediek: legyen benne a neved

github_owner      = "SziNo"
github_repository = "eks-nginx-proxy-pipeline"

# A saját IAM userem ARN-je: aws sts get-caller-identity --query Arn --output text
admin_user_arn = "arn:aws:iam::123456789012:user/your-user"
````

**Ellenőrzés:**

<!-- sbs:check 3.12 -->
```bash
terraform -chdir=bootstrap fmt -check -recursive && echo "fmt OK"
```

Várt kimenet:

```text
fmt OK
```

### 3.13 bootstrap/.terraform.lock.hcl és az első validate

A provider lock fájl rögzíti a pontos provider verziókat és a hash-eket. Ha ugyanezzel a tartalommal hozod létre, az init pontosan ugyanazokat a verziókat tölti le, mint az eredeti futásnál, és a `-lockfile=readonly` ezt ki is kényszeríti (eltérésnél hibát ad). Most már minden bootstrap fájl megvan, ezért a `validate` is lefuthat (az init `-backend=false`-szal, AWS nélkül; a providerek letöltéséhez internet kell).

Új fájl: `bootstrap/.terraform.lock.hcl`.

<!-- sbs:new bootstrap/.terraform.lock.hcl -->
````hcl
# This file is maintained automatically by "terraform init".
# Manual edits may be lost in future updates.

provider "registry.terraform.io/hashicorp/aws" {
  version     = "6.72.0"
  constraints = "~> 6.0"
  hashes = [
    "h1:v8OGTOUuY1sbRr4VDjYW7ypqV5NBB1cosUY5LrcwqTs=",
    "zh:2ffb6b2caaf320b61b406cff192d6e4303b64e32990b69384a056fe5af3d015b",
    "zh:33cd70e1b3d0f80bfdf07480139142f81a3daec26ab0fd160d00793e819b807e",
    "zh:37166439117b6ab889b02513e9cdc09b9ea4dd0b6e0733e83da47fc938acad35",
    "zh:676fc5b60e270af38f94da63bb0caa80c3fb24c8c68c77ceb4df8c09f5fd78f0",
    "zh:7218399da8607fd00b948e817941d3e543a09347272ff9103d9cf3797ad697e0",
    "zh:7fba55258fa19b283b465b2158141f8cffa23d4aa670cd9edfab9e4deaebc5d2",
    "zh:81da89c4557a9fb2943f10e229b4e289852df94255b7186dc7e1dcbd36641a9f",
    "zh:82b8dd415eb13a81e7e28fc29756e4639c77683534b0ffae6bf25c10b693a374",
    "zh:98fd4bbce8d01e99e983b09a824d0d76dacb9131c3d0d6246bc58f4a31ba1e51",
    "zh:9b12af85486a96aedd8d7984b0ff811a4b42e3d88dad1a3fb4c0b580d04fa425",
    "zh:9f4805d74c8a217d5226c0a0432aac48bf78e1f1211ebd8e637ef03c371dfe39",
    "zh:dea44ec068f2cf22d4c7de93c5639b494d37ae96afd030d930bfb52d5a56993b",
    "zh:e36e6b40ecb21c5c11c901a278b3ff8cb16ef553b155d7d22a774d051051803b",
    "zh:ed50513dd885ae66c3be4b170931e44775886339027431135cd41aa885307280",
    "zh:eefefe233dcb8934d4cdda1cb67e7e89b177a2717ee73822f4915cb3681cdc83",
    "zh:f67a7f2d76347698874caab82da856cfd6b99c418b0401768be06c5cc10a488d",
  ]
}

provider "registry.terraform.io/integrations/github" {
  version     = "6.13.0"
  constraints = "~> 6.13"
  hashes = [
    "h1:2kD+4leuV8tBBXv+EPeehmfW6cDhIzVki61OXsGCtRI=",
    "zh:0ab29fc21699f34345cf0bbbe44745fd1b143b7c73b410c1dc4abe05ffad0a84",
    "zh:1aed10d06755d420bb3a893bf548ab2932297a9d094c04c5a8501e949ca186ed",
    "zh:2a6a11c21eae408055f45b9533c07afd2e845f6d496fd1b645aec2e873012103",
    "zh:5dd05dee677f6ebdbed00cbb1b9be444ab2d1062d345cbc9ec50a47cb41b8622",
    "zh:6b757d034831243d67ddda869eac4368cef539848bd97511f4d68f1aa38a9c88",
    "zh:947c9b5b238f0364c57a705beabd24d3eea3159a6f3a24c07e3fbb13657ffae0",
    "zh:a676549a98164b61630658cbeb6c17820331ca04a049dc9b5095996a0c31ffbe",
    "zh:a8a81b7fe41dd61eb6a6fa5e08a4dd9ee070e862868252a7fd4cfce30364efee",
    "zh:c26a9bca4865665084e7f59b1402d7aff34ee63a418d7401a0658fa280cad4d4",
    "zh:c638d8d0762e62ea188f86302954ef4c92803f2160f0a45fca0cd13974bd3725",
    "zh:e739a0b7e81ca816944a18a38e679f4015edf8be7ac319815cdea865ba7727d7",
    "zh:ec099487ea3de8999c84b3b791e242d728461e51fe344832b37bd8d521201c77",
    "zh:f016ff9e2daab5b88185cec0795213049d105439ffd585d3309a714514ccae13",
    "zh:fbd1fee2c9df3aa19cf8851ce134dea6e45ea01cb85695c1726670c285797e25",
  ]
}
````

**Ellenőrzés:**

<!-- sbs:check 3.13 -->
```bash
terraform -chdir=bootstrap init -backend=false -input=false -lockfile=readonly > /dev/null \
  && terraform -chdir=bootstrap validate -no-color
```

Várt kimenet:

```text
Success! The configuration is valid.
```

### 3.14 terraform/versions.tf: partial S3 backend és pontos Terraform verzió

A kikommentelt backend helyére egy valódi `backend "s3"` blokk kerül, **partial configuration**: a key, a régió, a `use_lockfile` és az `encrypt` itt van, a bucket nevét viszont az init kapja (`-backend-config="bucket=..."`), mert account-specifikus, és a repó publikus. A backend blokkban változó nem használható, ezért nem lehet `var.`-ból. A `required_version` `>= 1.6` helyett pontosan `1.16.4`: ha egy újabb helyi Terraform írná a state-et, a CI régebbi verziója nem tudná olvasni.

Módosított fájl: `terraform/versions.tf`, 1 csere.

**Csere 1/1** (az eredeti fájl 3–30. sora). Keresd meg:

<!-- sbs:old terraform/versions.tf -->
````hcl
# a pontos verziót a "terraform init" után a .terraform.lock.hcl rögzíti (ezt commitold!).
terraform {
  # 1.6: a README is ezt írja elő; az itt használt nyelvi elemek (for_each, optional, precondition) ezzel mind működnek
  required_version = ">= 1.6"

  # Remote state S3-ban (most NINCS bekapcsolva, a state helyben van: terraform/terraform.tfstate).

  # A bucketet ELŐRE, kézzel kell létrehozni, mert az "init" már keresi, mielőtt bármit létrehozna:
  #   aws s3 mb s3://nginx-proxy-demo-tfstate-362099375729 --region eu-west-1
  #   aws s3api put-bucket-versioning --bucket nginx-proxy-demo-tfstate-362099375729 \
  #     --versioning-configuration Status=Enabled     # ajánlott: egy elrontott state visszaállítható
  # (A nyilvános hozzáférés tiltása és a titkosítás az új bucketeken alapból be van kapcsolva.)

  # Bekapcsolás: vedd ki a kommentet a blokk elől, majd "terraform init -migrate-state"
  # (átköltözteti a helyi state-et a bucketbe).
  # A backend blokkban NEM használhatók változók: az init minden más előtt olvassa be, ezért szó szerinti értékek.
  # A use_lockfile egy .tflock fájllal zárol az S3-ban, így két egyidejű apply nem írhatja felül egymást
  # (régebben ehhez DynamoDB tábla kellett).

  # backend "s3" {
  #   bucket       = "nginx-proxy-demo-tfstate-362099375729"
  #   key          = "eks-nginx-proxy/terraform.tfstate"
  #   region       = "eu-west-1"
  #   encrypt      = true
  #   use_lockfile = true
  # }

  required_providers {
````

Cseréld erre:

<!-- sbs:repl terraform/versions.tf -->
````hcl
# a pontos verziót a "terraform init" után a .terraform.lock.hcl rögzíti (ezt commitold!).
terraform {
  # Pontosan az a verzió, amelyet a CI telepít (setup-terraform, TF_VERSION). Ha a helyi gép
  # újabb verzióval írná a state-et, a CI régebbi Terraformja nem tudná olvasni.
  required_version = "1.16.4"

  # Remote state S3-ban, partial backend configuration: a bucket nevét az init kapja
  # (-backend-config="bucket=..."), mert account-specifikus, és a repó publikus.
  # Helyben: a bootstrap state_bucket outputjából; CI-ban: a TF_STATE_BUCKET variable-ből.
  # A backend blokkban nem használhatók változók: az init minden más előtt olvassa be.
  # A use_lockfile egy <key>.tflock fájllal zárol ugyanebben a bucketben, így két egyidejű
  # futás nem írhatja felül egymást (DynamoDB tábla nem kell).
  backend "s3" {
    key          = "production/terraform.tfstate"
    region       = "eu-west-1"
    use_lockfile = true
    encrypt      = true
  }

  required_providers {
````

**Ellenőrzés:**

<!-- sbs:check 3.14 -->
```bash
terraform -chdir=terraform init -backend=false -input=false -lockfile=readonly > /dev/null \
  && terraform -chdir=terraform validate -no-color
```

Várt kimenet:

```text
Success! The configuration is valid.
```

### 3.15 terraform/variables.tf: a két ARN lista

Az admin access entry eddig a `data "aws_caller_identity"`-ből jött, vagyis abból, aki éppen futtatja a Terraformot. CI-ban ez a role lenne, és a saját userem kiesne. Helyette két változó: `cluster_admin_principal_arns` (a saját user, az apply és az app role) és `cluster_plan_principal_arns` (a plan role, csak olvasás). Mindkettő `set(string)` (a for_each-hez), ARN validációval; CI-ban `TF_VAR_*` JSON listaként jönnek a Variables-ből. Az ECR mutability leírása is frissül, mert mostantól IMMUTABLE. A régi fájl végén nem volt sortörés, az újén van, ezért a teljes új fájl következik.

Módosított fájl, a teljes új tartalom: `terraform/variables.tf`

<!-- sbs:new terraform/variables.tf -->
````hcl
variable "region" {
  description = "AWS régió"
  type        = string
}

variable "cluster_name" {
  description = "Az EKS cluster neve (a legtöbb erőforrás neve is ebből képződik)"
  type        = string
}

variable "kubernetes_version" {
  description = "EKS Kubernetes verzió (ellenőrizd, hogy standard támogatásban van-e: aws eks describe-cluster-versions)"
  type        = string
}

variable "vpc_cidr" {
  description = "A VPC címtartománya; a subnets CIDR-jeinek ebbe kell esniük"
  type        = string
}

variable "subnets" {
  description = "Subnetek AZ-nként: a kulcs az AZ neve, az érték a privát és a publikus subnet CIDR-je"
  type = map(object({
    private_cidr = string
    public_cidr  = string
  }))

  validation {
    condition     = length(var.subnets) >= 2
    error_message = "Az EKS-hez legalább 2 AZ kell."
  }

  validation {
    condition = alltrue(flatten([
      for s in values(var.subnets) : [can(cidrhost(s.private_cidr, 0)), can(cidrhost(s.public_cidr, 0))]
    ]))
    error_message = "Minden private_cidr és public_cidr érvényes CIDR legyen (pl. 10.0.0.0/20)."
  }
}

variable "node_instance_types" {
  description = "A managed node group EC2 instance típusai"
  type        = list(string)
}

variable "node_ami_type" {
  description = "A node-ok AMI típusa; illeszkednie kell a node_instance_types architektúrájához (t3 = x86)"
  type        = string
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "Mely IP-tartományokból érhető el a publikus EKS API endpoint (gyakorláshoz mindenhonnan; élesben szűkítsd a saját IP-dre)"
  type        = list(string)
}

variable "node_desired_size" {
  description = "A node group kívánt node száma"
  type        = number
}

variable "node_min_size" {
  description = "A node group minimális node száma"
  type        = number
}

variable "node_max_size" {
  description = "A node group maximális node száma"
  type        = number
}

variable "lb_controller_chart_version" {
  description = "Az aws-load-balancer-controller Helm chart verziója; a 3.x óta megegyezik a controller verziójával, és a modules/lb-controller/iam_policy.json-nak ehhez kell illeszkednie. Ennek marad alapértéke, mert a policy JSON-hoz kötődik, vagyis a kód része."
  type        = string
  default     = "3.6.2"
}

variable "nlb_ingress_cidrs" {
  description = "Honnan érhető el az NLB a 80-as porton"
  type        = list(string)
}

variable "ecr_image_tag_mutability" {
  description = "MUTABLE: ugyanaz a tag felülírható; IMMUTABLE: egy tag csak egyszer tölthető fel (a CI egyedi commit SHA tagekkel dolgozik, ezért IMMUTABLE)"
  type        = string
}

variable "ecr_force_delete" {
  description = "true: a repó akkor is törölhető, ha van benne image (gyakorláshoz, hogy a destroy lefusson); élesben false"
  type        = bool
}

variable "cluster_admin_principal_arns" {
  description = "IAM user/role ARN-ek, amelyek cluster admin jogot kapnak (access entry, AmazonEKSClusterAdminPolicy, cluster scope): a saját IAM user, a terraform-apply és az app role. CI-ban a TF_VAR_cluster_admin_principal_arns variable-ből (JSON lista)."
  type        = set(string)

  validation {
    condition     = length(var.cluster_admin_principal_arns) > 0
    error_message = "Legalább egy cluster admin kell, különben a Helm provider sem éri el a clustert."
  }

  validation {
    condition     = alltrue([for arn in var.cluster_admin_principal_arns : can(regex("^arn:aws:iam::[0-9]{12}:(user|role)/.+$", arn))])
    error_message = "Minden elem IAM user vagy role ARN legyen (arn:aws:iam::<account>:user/... vagy :role/...)."
  }
}

variable "cluster_plan_principal_arns" {
  description = "IAM role ARN-ek, amelyek csak olvasási jogot kapnak a Helm release namespace-ében (AmazonEKSAdminViewPolicy, namespace scope): a terraform-plan role. CI-ban a TF_VAR_cluster_plan_principal_arns variable-ből (JSON lista)."
  type        = set(string)
  default     = []

  validation {
    condition     = alltrue([for arn in var.cluster_plan_principal_arns : can(regex("^arn:aws:iam::[0-9]{12}:(user|role)/.+$", arn))])
    error_message = "Minden elem IAM user vagy role ARN legyen."
  }
}
````

**Ellenőrzés:**

<!-- sbs:check 3.15 -->
```bash
terraform -chdir=terraform init -backend=false -input=false -lockfile=readonly > /dev/null \
  && terraform -chdir=terraform validate -no-color
```

Várt kimenet:

```text
Success! The configuration is valid.
```

### 3.16 terraform/locals.tf: a Helm release namespace-e

A `kube-system` két helyen kell: ide települ az LB Controller chartja, és a plan role csak ebben a namespace-ben olvashat. Egy localban van, hogy a kettő ne térhessen el. A fájl végén nincs sortörés.

Módosított fájl: `terraform/locals.tf`, 1 csere.

**Csere 1/1** (az eredeti fájl 2–6. sora). Keresd meg:

<!-- sbs:old terraform/locals.tf -->
````hcl
locals {
  # A két alkalmazás neve: ebből lesznek az ECR repók.
  # A scripts/build-push.sh ugyanezeket a neveket használja (külön, a saját ciklusában).
  services = ["service-a", "service-b"]
}
````

Cseréld erre:

<!-- sbs:repl terraform/locals.tf -->
````hcl
locals {
  # A két alkalmazás neve: ebből lesznek az ECR repók.
  # A CI mátrixa (_build.yml) és a scripts/build-push.sh ugyanezeket a neveket használja.
  services = ["service-a", "service-b"]

  # Az LB Controller Helm release namespace-e. Két helyen kell: itt települ a chart, és a
  # terraform-plan role csak ebben a namespace-ben olvashat (a Helm itt tárolja a release-t).
  lb_controller_namespace = "kube-system"
}
````

**Ellenőrzés:**

<!-- sbs:check 3.16 -->
```bash
terraform -chdir=terraform init -backend=false -input=false -lockfile=readonly > /dev/null \
  && terraform -chdir=terraform validate -no-color
```

Várt kimenet:

```text
Success! The configuration is valid.
```

### 3.17 terraform/modules/eks/variables.tf: az új modul bemenetek

Az eks modul két új bemenetet kap: a plan role ARN-jeit és a namespace-t, amelyre a joguk szól. A modulban nincs alapérték, mindent a root ad át. Ebben a pontban a `validate` még hibát adna (a root még nem adja át az új kötelező bemeneteket), ezért itt csak a formázást ellenőrizzük; a 3.19 után újra zöld. A fájl végén nincs sortörés.

Módosított fájl: `terraform/modules/eks/variables.tf`, 1 csere.

**Csere 1/1** (az eredeti fájl 50–55. sora). Keresd meg:

<!-- sbs:old terraform/modules/eks/variables.tf -->
````hcl

variable "cluster_admin_principal_arns" {
  description = "IAM user/role ARN-ek, amelyek cluster admin jogot kapnak (access entry)"
  type        = set(string)
}

````

Cseréld erre:

<!-- sbs:repl terraform/modules/eks/variables.tf -->
````hcl

variable "cluster_admin_principal_arns" {
  description = "IAM user/role ARN-ek, amelyek cluster admin jogot kapnak (access entry, cluster scope)"
  type        = set(string)
}

variable "cluster_plan_principal_arns" {
  description = "IAM role ARN-ek, amelyek csak olvashatnak a cluster_plan_namespace-ben (a terraform plan Helm refresh-éhez)"
  type        = set(string)
}

variable "cluster_plan_namespace" {
  description = "A namespace, amelyre a cluster_plan_principal_arns olvasási joga szól (a Helm release namespace-e)"
  type        = string
}

````

**Ellenőrzés:**

<!-- sbs:check 3.17 -->
```bash
terraform -chdir=terraform fmt -check -recursive && echo "fmt OK"
```

Várt kimenet:

```text
fmt OK
```

### 3.18 terraform/modules/eks/access.tf: a plan role olvasási joga

Az admin access entry változatlanul for_each-csel, cluster scope-pal megy. Új a plan role entryje: a PR-os plan alatt a Helm provider frissíti a `helm_release` állapotát, amelyet a Helm `sh.helm.release.v1.*` **Secretekben** tárol a release namespace-ében. Az `AmazonEKSViewPolicy` a Secreteket szándékosan nem engedi, ezért `AmazonEKSAdminViewPolicy` (csak get/list/watch, de a Secreteket is), namespace scope-pal csak a `kube-system`-re. Ez a legszűkebb, ami a planhez elég.

Módosított fájl, a teljes új tartalom: `terraform/modules/eks/access.tf`

<!-- sbs:new terraform/modules/eks/access.tf -->
````hcl
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
````

**Ellenőrzés:**

<!-- sbs:check 3.18 -->
```bash
terraform -chdir=terraform fmt -check -recursive && echo "fmt OK"
```

Várt kimenet:

```text
fmt OK
```

### 3.19 terraform/main.tf: az új változók átadása

Az eks modul az admin listát a változóból kapja (nem a `data.aws_caller_identity`-ből), és megkapja a plan role-okat és a namespace-t. Az lb-controller modul a namespace-t ugyanabból a localból kapja. Ettől a ponttól a `validate` újra zöld.

Módosított fájl: `terraform/main.tf`, 3 csere.

**Csere 1/3** (az eredeti fájl 25–29. sora). Keresd meg:

<!-- sbs:old terraform/main.tf -->
````hcl

# EKS cluster: IAM szerepek, security groupok (az NLB-é is), cluster, addonok,
# managed node group, OIDC provider és admin access entry.
module "eks" {
  source = "./modules/eks"
````

Cseréld erre:

<!-- sbs:repl terraform/main.tf -->
````hcl

# EKS cluster: IAM szerepek, security groupok (az NLB-é is), cluster, addonok,
# managed node group, OIDC provider és access entryk (admin és a plan role olvasási joga).
module "eks" {
  source = "./modules/eks"
````

**Csere 2/3** (az eredeti fájl 44–49. sora). Keresd meg:

<!-- sbs:old terraform/main.tf -->
````hcl
  nlb_ingress_cidrs            = var.nlb_ingress_cidrs

  # Aki a Terraformot futtatja (IAM user), cluster admin lesz
  cluster_admin_principal_arns = [data.aws_caller_identity.current.arn]
}

````

Cseréld erre:

<!-- sbs:repl terraform/main.tf -->
````hcl
  nlb_ingress_cidrs            = var.nlb_ingress_cidrs

  # Cluster admin: a saját IAM user, a terraform-apply és az app role (a bootstrap adja meg
  # a GitHub Variables-ben, helyben a terraform.tfvars-ban)
  cluster_admin_principal_arns = var.cluster_admin_principal_arns

  # A terraform-plan role csak a Helm release namespace-ében olvashat (a plan alatti refreshhez)
  cluster_plan_principal_arns = var.cluster_plan_principal_arns
  cluster_plan_namespace      = local.lb_controller_namespace
}

````

**Csere 3/3** (az eredeti fájl 59–62. sora). Keresd meg:

<!-- sbs:old terraform/main.tf -->
````hcl
  oidc_provider_url = module.eks.oidc_provider_url
  chart_version     = var.lb_controller_chart_version

  # A Helm release csak akkor induljon, ha az EKS modul MINDEN eleme kész: a node group
````

Cseréld erre:

<!-- sbs:repl terraform/main.tf -->
````hcl
  oidc_provider_url = module.eks.oidc_provider_url
  chart_version     = var.lb_controller_chart_version
  namespace         = local.lb_controller_namespace

  # A Helm release csak akkor induljon, ha az EKS modul MINDEN eleme kész: a node group
````

**Ellenőrzés:**

<!-- sbs:check 3.19 -->
```bash
terraform -chdir=terraform init -backend=false -input=false -lockfile=readonly > /dev/null \
  && terraform -chdir=terraform validate -no-color
```

Várt kimenet:

```text
Success! The configuration is valid.
```

### 3.20 terraform/data.tf törlése

Az `aws_caller_identity` már nem kell semmihez. A fájlban más nem volt, ezért az egész fájl törlődik.

<!-- sbs:run -->
````bash
git rm -q terraform/data.tf
````

**Ellenőrzés:**

<!-- sbs:check 3.20 -->
```bash
terraform -chdir=terraform init -backend=false -input=false -lockfile=readonly > /dev/null \
  && terraform -chdir=terraform validate -no-color
```

Várt kimenet:

```text
Success! The configuration is valid.
```

### 3.21 terraform/outputs.tf: kommentek

Csak a kommentek és egy output leírása változik: az NLB security group ID-ját mostantól a deploy név alapján kérdezi le, nem a Terraform outputból olvassa. A fájl végén nincs sortörés.

Módosított fájl: `terraform/outputs.tf`, 2 csere.

**Csere 1/2** (az eredeti fájl 1–3. sora). Keresd meg:

<!-- sbs:old terraform/outputs.tf -->
````hcl
# A scripts/ és a README ezekre a nevekre hivatkozik, ezért a nevek nem változtak.

output "region" {
````

Cseréld erre:

<!-- sbs:repl terraform/outputs.tf -->
````hcl
# A scripts/ és a README ezekre a nevekre hivatkozik.

output "region" {
````

**Csere 2/2** (az eredeti fájl 17–21. sora). Keresd meg:

<!-- sbs:old terraform/outputs.tf -->
````hcl

output "nlb_security_group_id" {
  description = "Az NLB security groupja (a render.sh az overlay patch-ével a Service annotációjába írja)"
  value       = module.eks.nlb_security_group_id
}
````

Cseréld erre:

<!-- sbs:repl terraform/outputs.tf -->
````hcl

output "nlb_security_group_id" {
  description = "Az NLB security groupja (a deploy és a render.sh név alapján kérdezi le, és patch-csel a Service annotációjába írja)"
  value       = module.eks.nlb_security_group_id
}
````

**Ellenőrzés:**

<!-- sbs:check 3.21 -->
```bash
terraform -chdir=terraform fmt -check -recursive && echo "fmt OK"
```

Várt kimenet:

```text
fmt OK
```

### 3.22 terraform/modules/ecr/main.tf: komment

A komment szerint mostantól a CI (és helyben a build-push.sh) tölti fel az image-eket. A fájl végén nincs sortörés.

Módosított fájl: `terraform/modules/ecr/main.tf`, 1 csere.

**Csere 1/1** (az eredeti fájl 1–3. sora). Keresd meg:

<!-- sbs:old terraform/modules/ecr/main.tf -->
````hcl
# ECR repók: ide tölti fel a scripts/build-push.sh a két alkalmazás image-ét, és innen
# húzzák le a node-ok (a node szerep AmazonEC2ContainerRegistryReadOnly policyjával).
# for_each a szolgáltatás nevével: stabil kulcs, egy repó törlése nem tolja el a többit (a count-tal ellentétben).
````

Cseréld erre:

<!-- sbs:repl terraform/modules/ecr/main.tf -->
````hcl
# ECR repók: ide tölti fel a CI (_build.yml, helyben a scripts/build-push.sh) a két image-et, és innen
# húzzák le a node-ok (a node szerep AmazonEC2ContainerRegistryReadOnly policyjával).
# for_each a szolgáltatás nevével: stabil kulcs, egy repó törlése nem tolja el a többit (a count-tal ellentétben).
````

**Ellenőrzés:**

<!-- sbs:check 3.22 -->
```bash
terraform -chdir=terraform fmt -check -recursive && echo "fmt OK"
```

Várt kimenet:

```text
fmt OK
```

### 3.23 terraform/modules/eks/outputs.tf: output leírás

Az `nlb_security_group_id` leírása a deployra hivatkozik a render.sh helyett.

Módosított fájl: `terraform/modules/eks/outputs.tf`, 1 csere.

**Csere 1/1** (az eredeti fájl 35–39. sora). Keresd meg:

<!-- sbs:old terraform/modules/eks/outputs.tf -->
````hcl

output "nlb_security_group_id" {
  description = "Az NLB security groupja (a render.sh az overlay patch-ével a Service annotációjába írja)"
  value       = aws_security_group.nlb.id
}
````

Cseréld erre:

<!-- sbs:repl terraform/modules/eks/outputs.tf -->
````hcl

output "nlb_security_group_id" {
  description = "Az NLB security groupja (a deploy patch-csel a Service annotációjába írja)"
  value       = aws_security_group.nlb.id
}
````

**Ellenőrzés:**

<!-- sbs:check 3.23 -->
```bash
terraform -chdir=terraform fmt -check -recursive && echo "fmt OK"
```

Várt kimenet:

```text
fmt OK
```

### 3.24 terraform/modules/eks/security-groups.tf: komment

Az NLB security group kommentje: a deploy név alapján kérdezi le, és patch-csel írja a Service annotációjába. Utána egy teljes `validate` a fő rootra.

Módosított fájl: `terraform/modules/eks/security-groups.tf`, 1 csere.

**Csere 1/1** (az eredeti fájl 44–48. sora). Keresd meg:

<!-- sbs:old terraform/modules/eks/security-groups.tf -->
````hcl

# Security group az NLB-nek. Az azonosítóját az nlb_security_group_id output adja ki,
# a scripts/render.sh pedig a generált overlay patch-ével beírja a Service annotációjába
# (service.beta.kubernetes.io/aws-load-balancer-security-groups).
resource "aws_security_group" "nlb" {
````

Cseréld erre:

<!-- sbs:repl terraform/modules/eks/security-groups.tf -->
````hcl

# Security group az NLB-nek. Az azonosítóját az nlb_security_group_id output adja ki,
# a deploy (_deploy.yml, helyben a scripts/render.sh) név alapján kérdezi le, és patch-csel beírja a Service annotációjába
# (service.beta.kubernetes.io/aws-load-balancer-security-groups).
resource "aws_security_group" "nlb" {
````

**Ellenőrzés:**

<!-- sbs:check 3.24 -->
```bash
terraform -chdir=terraform init -backend=false -input=false -lockfile=readonly > /dev/null \
  && terraform -chdir=terraform validate -no-color
```

Várt kimenet:

```text
Success! The configuration is valid.
```

### 3.25 terraform/production.tfvars

A production környezet NEM érzékeny értékei egy commitolt fájlban (a régi tfvars.example értékei). A `region` és a `cluster_name` nincs benne: ezek `TF_VAR_*`-ként jönnek a Variables-ből, így egy helyen vannak megadva (a bootstrap tfvars-ában). Az ECR `IMMUTABLE`, mert a CI egyedi commit SHA tagekkel dolgozik, és egy tag soha nem íródhat felül; a `force_delete` marad true, hogy a destroy képekkel teli repónál is lefusson.

Új fájl: `terraform/production.tfvars`.

<!-- sbs:new terraform/production.tfvars -->
````hcl
# A production környezet NEM érzékeny, nem account-specifikus értékei (commitolt fájl).
# Az account-specifikus és a bootstrapből jövő értékek (region, cluster_name, a két ARN lista)
# TF_VAR_* környezeti változóként jönnek: CI-ban a GitHub Variables-ből, helyben a
# gitignore-olt terraform.tfvars-ból. Használat: terraform plan -var-file=production.tfvars

# Subnetek AZ-nként, kézzel rögzítve (nem data source-ból), így kiszámítható és nem változik magától.
# A privát /20-asok nagyok, mert a VPC CNI miatt a podok is innen kapnak IP-t; a publikus /24-ekben
# csak az NLB és a NAT gateway van. Minden CIDR-nek a vpc_cidr-be kell esnie, és nem fedhetik egymást.
# Az AZ nevek a régióhoz kötődnek (eu-west-1).
subnets = {
  "eu-west-1a" = { private_cidr = "10.0.0.0/20", public_cidr = "10.0.48.0/24" }
  "eu-west-1b" = { private_cidr = "10.0.16.0/20", public_cidr = "10.0.49.0/24" }
  "eu-west-1c" = { private_cidr = "10.0.32.0/20", public_cidr = "10.0.50.0/24" }
}

kubernetes_version = "1.37"
vpc_cidr           = "10.0.0.0/16"

# Az AMI típusnak illeszkednie kell az instance típushoz (t3 = x86; egy t4g ARM lenne)
node_instance_types = ["t3.medium"]
node_ami_type       = "BOTTLEROCKET_x86_64"
node_desired_size   = 3
node_min_size       = 2
node_max_size       = 4

# Élesben szűkítsd; a GitHub-hosted runnerek IP-je nem fix, ezért a CI miatt nyitva marad
cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

# Honnan érhető el az NLB (a 80-as port); nyilvános szolgáltatásnál az egész internet
nlb_ingress_cidrs = ["0.0.0.0/0"]

# ECR: a CI egyedi commit SHA tagekkel dolgozik, ezért egy tag soha nem íródik felül.
# A force_delete true marad, hogy a destroy akkor is lefusson, ha vannak image-ek a repóban.
ecr_image_tag_mutability = "IMMUTABLE"
ecr_force_delete         = true
````

**Ellenőrzés:**

<!-- sbs:check 3.25 -->
```bash
terraform fmt -check terraform/production.tfvars && echo "fmt OK"
git check-ignore -q terraform/production.tfvars || echo "nem ignorált, commitolható"
```

Várt kimenet:

```text
fmt OK
nem ignorált, commitolható
```

### 3.26 terraform/terraform.tfvars.example

A helyi minta mostantól csak az account-specifikus értékeket tartalmazza (régió, cluster név, a két ARN lista); a többi a `production.tfvars`-ból jön. A kész tartalmat a bootstrap `local_tfvars` outputja adja ki. A változás nagy, ezért a teljes új fájl következik.

Módosított fájl, a teljes új tartalom: `terraform/terraform.tfvars.example`

<!-- sbs:new terraform/terraform.tfvars.example -->
````hcl
# HELYI használathoz: másold terraform.tfvars névre (gitignore-olt). A Terraform automatikusan
# betölti, a nem érzékeny értékek pedig a commitolt production.tfvars-ból jönnek:
#   terraform plan -var-file=production.tfvars
# A kész tartalmat a bootstrap kiírja: terraform -chdir=bootstrap output -raw local_tfvars
# CI-ban ugyanezek az értékek a GitHub Variables-ből jönnek (TF_VAR_* környezeti változók).

region       = "eu-west-1"
cluster_name = "szino-nginx-proxy-demo"

# Cluster admin: a saját IAM user, a terraform-apply és az app role
cluster_admin_principal_arns = [
  "arn:aws:iam::123456789012:role/gha-eks-nginx-proxy-pipeline-app",
  "arn:aws:iam::123456789012:role/gha-eks-nginx-proxy-pipeline-terraform-apply",
  "arn:aws:iam::123456789012:user/your-user",
]

# Csak olvasás a kube-system namespace-ben (a PR-os plan Helm refresh-éhez)
cluster_plan_principal_arns = [
  "arn:aws:iam::123456789012:role/gha-eks-nginx-proxy-pipeline-terraform-plan",
]
````

**Ellenőrzés:**

<!-- sbs:check 3.26 -->
```bash
terraform -chdir=terraform fmt -check -recursive && echo "fmt OK"
```

Várt kimenet:

```text
fmt OK
```

### 3.27 k8s/base: az image kommentek

A két Deploymentben az `image: service-a` / `service-b` helyőrző marad, csak a komment mutat a generált helyi overlay helyett a production overlayre.

Módosított fájl: `k8s/base/service-a.yaml`, 1 csere.

**Csere 1/1** (az eredeti fájl 20–24. sora). Keresd meg:

<!-- sbs:old k8s/base/service-a.yaml -->
````yaml
      containers:
        - name: app
          image: service-a # a render.sh által generált overlay (k8s/overlays/local) "images" része cseréli az ECR címre és a tagre
          ports:
            - containerPort: 8080
````

Cseréld erre:

<!-- sbs:repl k8s/base/service-a.yaml -->
````yaml
      containers:
        - name: app
          image: service-a # a k8s/overlays/production "images" része cseréli az ECR címre és a commit SHA tagre
          ports:
            - containerPort: 8080
````

Módosított fájl: `k8s/base/service-b.yaml`, 1 csere.

**Csere 1/1** (az eredeti fájl 20–24. sora). Keresd meg:

<!-- sbs:old k8s/base/service-b.yaml -->
````yaml
      containers:
        - name: app
          image: service-b # a render.sh által generált overlay (k8s/overlays/local) "images" része cseréli az ECR címre és a tagre
          ports:
            - containerPort: 8080
````

Cseréld erre:

<!-- sbs:repl k8s/base/service-b.yaml -->
````yaml
      containers:
        - name: app
          image: service-b # a k8s/overlays/production "images" része cseréli az ECR címre és a commit SHA tagre
          ports:
            - containerPort: 8080
````

**Ellenőrzés:**

<!-- sbs:check 3.27 -->
```bash
kubectl kustomize k8s/base | grep -E 'image:'
```

Várt kimenet:

```text
      - image: service-a
      - image: service-b
      - image: nginxinc/nginx-unprivileged:1.27-alpine
```

### 3.28 k8s/overlays/production/kustomization.yaml

A Kustomize szabványos base + overlay szerkezete. Az overlay commitolt, de környezetfüggő értéket NEM tartalmaz (az ECR címben benne lenne az account ID): az `images` bejegyzésekben csak a név van, az ECR címet és a commit SHA taget a deploy írja be `kustomize edit set image`-dzsel, az NLB security group ID-t pedig `kustomize edit add patch`-csel, mindkettőt csak a workspace-ben, commit nélkül.

<!-- sbs:run -->
````bash
mkdir -p k8s/overlays/production
````

Új fájl: `k8s/overlays/production/kustomization.yaml`.

<!-- sbs:new k8s/overlays/production/kustomization.yaml -->
````yaml
# A production overlay (commitolt). A környezetfüggő értékeket NEM tartalmazza (a repó publikus):
# a deploy (_deploy.yml, helyben a scripts/render.sh) a workspace-ben, commit nélkül egészíti ki:
#   kustomize edit set image service-a=<registry>/<cluster>/service-a:<commit SHA>   (és service-b)
#   kustomize edit add patch ...   (az NLB security group ID a Service annotációjába)
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

# A közös manifestek, környezetfüggő érték nélkül
resources:
  - ../../base

# Az "image: service-a" és "image: service-b" cseréje. A "name" a Deploymentben lévő image
# névre illeszkedik; a newName (ECR cím) és a newTag (commit SHA) a deploykor kerül ide.
images:
  - name: service-a
  - name: service-b
````

**Ellenőrzés:**

<!-- sbs:check 3.28 -->
```bash
kubectl kustomize k8s/overlays/production | grep -E 'image:'
```

Várt kimenet:

```text
      - image: service-a
      - image: service-b
      - image: nginxinc/nginx-unprivileged:1.27-alpine
```

### 3.29 scripts/common.sh

A három helyi script közös része, hogy ne térjenek el egymástól és a CI-tól: partial backend init a bootstrap outputjából, a régió és a cluster a Terraform outputból, az ECR registry címe, és az NLB security group lekérdezése név alapján, pontosan úgy, mint a `_deploy.yml`-ben. Ha nincs önálló `kustomize` bináris, a hivatalos image-et futtatja dockerrel. Nem futtatható (source-olják), ezért nincs rajta végrehajtási jog.

Új fájl: `scripts/common.sh`.

<!-- sbs:new scripts/common.sh -->
````bash
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
````

**Ellenőrzés:**

<!-- sbs:check 3.29 -->
```bash
bash -n scripts/common.sh && echo "bash -n OK"
docker run --rm -v "$PWD:/mnt" -w /mnt koalaman/shellcheck:stable -x scripts/common.sh && echo "shellcheck OK"
```

Várt kimenet:

```text
bash -n OK
shellcheck OK
```

### 3.30 scripts/build-push.sh

Ugyanaz, mint a CI `_build.yml` push jobja: `src/` útvonal, a tag alapból a commit SHA (`git rev-parse HEAD`), és a már létező tag kimarad, mert a repók IMMUTABLE-k. Ha a `src/` alatt nem commitolt változás van, megáll, mert a SHA tag mást jelölne. A változás nagy, ezért a teljes új fájl következik (a végrehajtási jog megmarad).

Módosított fájl, a teljes új tartalom: `scripts/build-push.sh`

<!-- sbs:new scripts/build-push.sh -->
````bash
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
````

**Ellenőrzés:**

<!-- sbs:check 3.30 -->
```bash
bash -n scripts/build-push.sh && echo "bash -n OK"
docker run --rm -v "$PWD:/mnt" -w /mnt koalaman/shellcheck:stable -x scripts/build-push.sh && echo "shellcheck OK"
```

Várt kimenet:

```text
bash -n OK
shellcheck OK
```

### 3.31 scripts/render.sh

A régi verzió heredoc-kal írt egy overlayt; az új a commitolt production overlay másolatán (`k8s/overlays/local`, gitignore-olt) pontosan ugyanazokat a `kustomize edit` parancsokat futtatja, mint a CI, így a helyi telepítés nem térhet el. A teljes új fájl következik.

Módosított fájl, a teljes új tartalom: `scripts/render.sh`

<!-- sbs:new scripts/render.sh -->
````bash
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
````

**Ellenőrzés:**

<!-- sbs:check 3.31 -->
```bash
bash -n scripts/render.sh && echo "bash -n OK"
docker run --rm -v "$PWD:/mnt" -w /mnt koalaman/shellcheck:stable -x scripts/render.sh && echo "shellcheck OK"
```

Várt kimenet:

```text
bash -n OK
shellcheck OK
```

### 3.32 scripts/teardown.sh

Ugyanaz a sorrend, mint a `destroy.yml`-ben: az NLB ARN-je a Service-ből, `kubectl delete -k k8s/base --wait`, `aws elbv2 wait load-balancers-deleted`, majd `terraform destroy -var-file=production.tfvars`. Helyben szándékosan nincs `-auto-approve`. A teljes új fájl következik.

Módosított fájl, a teljes új tartalom: `scripts/teardown.sh`

<!-- sbs:new scripts/teardown.sh -->
````bash
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
````

**Ellenőrzés:**

<!-- sbs:check 3.32 -->
```bash
bash -n scripts/teardown.sh && echo "bash -n OK"
docker run --rm -v "$PWD:/mnt" -w /mnt koalaman/shellcheck:stable -x scripts/teardown.sh && echo "shellcheck OK"
ls -l scripts/ | awk 'NR>1 {print $1, $NF}'
```

Várt kimenet:

```text
bash -n OK
shellcheck OK
-rwxr-xr-x build-push.sh
-rw-r--r-- common.sh
-rwxr-xr-x render.sh
-rwxr-xr-x teardown.sh
```

### 3.33 .github/workflows/_build.yml

Újrahasznosítható (`workflow_call`) build, mátrix a két szolgáltatásra. **Két külön job**: a `check` push, AWS és environment nélkül fut (PR-on csak azt ellenőrzi, hogy a Dockerfile felépül), a `push` a `production` environmenttel, mert az app role trustja csak az `environment:production` `sub`-ot fogadja el, és a PR-ok ezt az environmentet nem is használhatják. A push előtt `aws ecr describe-images` ellenőrzi, hogy a tag létezik-e: az IMMUTABLE repóba egy második push hibát adna. Cache: `type=gha`, szolgáltatásonként külön scope. Az actionök commit SHA-ra rögzítve.

<!-- sbs:run -->
````bash
mkdir -p .github/workflows
````

Új fájl: `.github/workflows/_build.yml`.

<!-- sbs:new .github/workflows/_build.yml -->
````yaml
# Újrahasznosítható build workflow (workflow_call), két külön jobbal:
# - check: push nélkül, AWS és environment nélkül (PR-on a Dockerfile-ok ellenőrzése);
# - push: production environmenttel (az app role trust policyja erre szól), ECR push.
# A hívó a push inputtal választ; a kettő közül mindig csak az egyik fut.
name: _build

on:
  workflow_call:
    inputs:
      push:
        description: "true: build és push az ECR-be (production environment); false: csak build"
        type: boolean
        required: true
      image_tag:
        description: "Az image tag (a commit SHA)"
        type: string
        required: true

permissions:
  contents: read

jobs:
  # Csak build (PR): ellenőrzi, hogy mindkét image felépül. Nincs AWS, nincs push.
  check:
    if: ${{ !inputs.push }}
    name: check (${{ matrix.service }})
    runs-on: ubuntu-24.04
    permissions:
      contents: read
    strategy:
      fail-fast: false
      matrix:
        service: [service-a, service-b]
    steps:
      # A forráskód (src/<szolgáltatás>) a build contexthez.
      - name: Checkout
        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1

      # Buildx builder: ez kell a gha cache-hez és a platform megadásához.
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@f87e5991a6d7451dcb8d9637bfbc97413f497069 # v4.4.1

      # Build push nélkül. A cache-t csak olvassa (a main ág buildjeié), nem írja, hogy a PR-ok
      # ne foglalják a cache helyét.
      - name: Build (no push)
        uses: docker/build-push-action@c3c9e263c25d99ce0380d002d59b67737d91b0dc # v7.4.0
        with:
          context: src/${{ matrix.service }}
          platforms: linux/amd64
          push: false
          tags: ${{ matrix.service }}:${{ inputs.image_tag }}
          cache-from: type=gha,scope=${{ matrix.service }}

  # Build és push az ECR-be, a commit SHA taggel.
  push:
    if: ${{ inputs.push }}
    name: push (${{ matrix.service }})
    runs-on: ubuntu-24.04
    environment: production
    permissions:
      contents: read
      id-token: write # OIDC token az app role felvételéhez
    strategy:
      fail-fast: false
      matrix:
        service: [service-a, service-b]
    env:
      REPOSITORY: ${{ vars.CLUSTER_NAME }}/${{ matrix.service }}
      IMAGE_TAG: ${{ inputs.image_tag }}
    steps:
      # A forráskód (src/<szolgáltatás>) a build contexthez.
      - name: Checkout
        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1

      # OIDC: rövid életű AWS kulcsok az app role-lal, access key nélkül.
      - name: Configure AWS credentials (app role)
        uses: aws-actions/configure-aws-credentials@e1253824e5c10ff9df46874f81ed3ec929e19cfd # v6.3.0
        with:
          role-to-assume: ${{ vars.APP_ROLE_ARN }}
          aws-region: ${{ vars.AWS_REGION }}

      # docker login az ECR registrybe; a registry címe (<account>.dkr.ecr.<régió>.amazonaws.com) az outputja.
      - name: Login to Amazon ECR
        id: ecr
        uses: aws-actions/amazon-ecr-login@03f1aad4c6c7ffd436567f42f9384779290529bd # v2.1.7

      # A repó IMMUTABLE: egy már feltöltött tag újbóli push-a hibát adna. Ha a tag megvan
      # (pl. újrafuttatás, vagy a terraform-apply.yml ugyanazt a commitot buildeli), a build kimarad.
      # Erre nincs action, ezért AWS CLI; csak az ImageNotFoundException jelenti, hogy nincs meg.
      - name: Check if tag exists
        id: tag
        run: |
          if out=$(aws ecr describe-images --repository-name "$REPOSITORY" \
              --image-ids imageTag="$IMAGE_TAG" 2>&1); then
            echo "exists=true" >> "$GITHUB_OUTPUT"
            echo "${REPOSITORY}:${IMAGE_TAG} már létezik, a build kimarad."
          elif grep -q ImageNotFoundException <<<"$out"; then
            echo "exists=false" >> "$GITHUB_OUTPUT"
          else
            echo "$out" >&2
            exit 1
          fi

      # Buildx builder: ez kell a gha cache-hez és a platform megadásához.
      - name: Set up Docker Buildx
        if: steps.tag.outputs.exists == 'false'
        uses: docker/setup-buildx-action@f87e5991a6d7451dcb8d9637bfbc97413f497069 # v4.4.1

      # Build linux/amd64-re (a node-ok x86-osak) és push. A gha cache szolgáltatásonként külön
      # scope-ban van, hogy a két image ne írja felül egymás cache-ét.
      - name: Build and push
        if: steps.tag.outputs.exists == 'false'
        uses: docker/build-push-action@c3c9e263c25d99ce0380d002d59b67737d91b0dc # v7.4.0
        with:
          context: src/${{ matrix.service }}
          platforms: linux/amd64
          push: true
          tags: ${{ steps.ecr.outputs.registry }}/${{ env.REPOSITORY }}:${{ env.IMAGE_TAG }}
          cache-from: type=gha,scope=${{ matrix.service }}
          cache-to: type=gha,mode=max,scope=${{ matrix.service }}

      # A feltöltött (vagy már meglévő) image a job summary-ba.
      - name: Job summary
        env:
          EXISTS: ${{ steps.tag.outputs.exists }}
          REGISTRY: ${{ steps.ecr.outputs.registry }}
        run: |
          if [ "$EXISTS" = "true" ]; then status="már létezett, kimaradt"; else status="feltöltve"; fi
          echo "- \`${REGISTRY}/${REPOSITORY}:${IMAGE_TAG}\`: ${status}" >> "$GITHUB_STEP_SUMMARY"
````

**Ellenőrzés:**

<!-- sbs:check 3.33 -->
```bash
docker run --rm -v "$PWD:/repo" -w /repo rhysd/actionlint:1.7.12 -no-color .github/workflows/_build.yml \
  && echo "actionlint OK"
```

Várt kimenet:

```text
actionlint OK
```

### 3.34 .github/workflows/_deploy.yml

Újrahasznosítható deploy: kubeconfig az app role-lal, az NLB security group lekérdezése név alapján, `kustomize edit` (image + patch) csak a workspace-ben, `kubectl apply -k`, rollout ellenőrzés a két Deploymentre és a DaemonSetre, várakozás az NLB hostnevére, majd smoke teszt a curl beépített retry-ával (az új NLB DNS-e és target healthje pár perc). `concurrency: deploy-production` megszakítás nélkül: egyszerre egy deploy.

Új fájl: `.github/workflows/_deploy.yml`.

<!-- sbs:new .github/workflows/_deploy.yml -->
````yaml
# Újrahasznosítható deploy workflow (workflow_call): a k8s/overlays/production telepítése a
# megadott image taggel (commit SHA), rollout ellenőrzés és smoke teszt az NLB-n keresztül.
name: _deploy

on:
  workflow_call:
    inputs:
      image_tag:
        description: "A telepítendő image tag (a commit SHA)"
        type: string
        required: true

permissions:
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-24.04
    # production environment: csak a main ágról, és az app role trust policyja erre szól.
    # Az url a GitHub Deployments oldalon az NLB címére mutat.
    environment:
      name: production
      url: ${{ steps.nlb.outputs.url }}
    # Egyszerre egy deploy; a következő megvárja az előzőt (nem szakítja meg).
    concurrency:
      group: deploy-production
      cancel-in-progress: false
    permissions:
      contents: read
      id-token: write # OIDC token az app role felvételéhez
    env:
      AWS_REGION: ${{ vars.AWS_REGION }}
      CLUSTER_NAME: ${{ vars.CLUSTER_NAME }}
      IMAGE_TAG: ${{ inputs.image_tag }}
      NAMESPACE: demo
      OVERLAY: k8s/overlays/production
    steps:
      # A manifestek (k8s/base és a production overlay).
      - name: Checkout
        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1

      # OIDC: rövid életű AWS kulcsok az app role-lal; az aws-account-id output a registry címéhez kell.
      - name: Configure AWS credentials (app role)
        id: aws
        uses: aws-actions/configure-aws-credentials@e1253824e5c10ff9df46874f81ed3ec929e19cfd # v6.3.0
        with:
          role-to-assume: ${{ vars.APP_ROLE_ARN }}
          aws-region: ${{ vars.AWS_REGION }}

      # A cluster verziójához illő kubectl (±1 alverzió támogatott).
      - name: Setup kubectl
        uses: azure/setup-kubectl@bda439f5f36b99b262ebdcd3613869bddb064c8e # v5.2.0
        with:
          version: v1.37.2

      # kubeconfig: a kubectl az aws eks get-token-nel hitelesít (az app role access entryje).
      - name: Update kubeconfig
        run: aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$AWS_REGION"

      # Az NLB security group ID-ja név alapján (a Terraform <cluster>-nlb néven hozza létre).
      # Minden friss infrastruktúránál más, ezért nem lehet a commitolt overlayben.
      - name: Look up NLB security group
        id: sg
        run: |
          sg_id=$(aws ec2 describe-security-groups \
            --filters "Name=group-name,Values=${CLUSTER_NAME}-nlb" \
            --query 'SecurityGroups[0].GroupId' --output text)
          if [[ "$sg_id" != sg-* ]]; then
            echo "Nem található a ${CLUSTER_NAME}-nlb security group (fut a Terraform infrastruktúra?)" >&2
            exit 1
          fi
          echo "id=${sg_id}" >> "$GITHUB_OUTPUT"
          echo "NLB security group: ${sg_id}"

      # Az overlay kiegészítése CSAK a workspace-ben (nem commitoljuk): az image-ek ECR címe és
      # a commit SHA tag, valamint az SG ID a Service annotációjába (JSON6902 patch). A kustomize
      # bináris a GitHub-hosted runner image része.
      - name: Kustomize edit (image tag and NLB security group)
        working-directory: ${{ env.OVERLAY }}
        env:
          REGISTRY: ${{ steps.aws.outputs.aws-account-id }}.dkr.ecr.${{ vars.AWS_REGION }}.amazonaws.com
          SG_ID: ${{ steps.sg.outputs.id }}
        run: |
          kustomize edit set image \
            "service-a=${REGISTRY}/${CLUSTER_NAME}/service-a:${IMAGE_TAG}" \
            "service-b=${REGISTRY}/${CLUSTER_NAME}/service-b:${IMAGE_TAG}"
          kustomize edit add patch --kind Service --name nginx-proxy \
            --patch "[{\"op\":\"add\",\"path\":\"/metadata/annotations/service.beta.kubernetes.io~1aws-load-balancer-security-groups\",\"value\":\"${SG_ID}\"}]"
          cat kustomization.yaml

      # A kubectl parancs: a teljes overlay telepítése (namespace, ConfigMap, Deploymentek,
      # DaemonSet, Service-ek).
      - name: kubectl apply
        run: kubectl apply -k "$OVERLAY"

      # Megvárja, amíg az új podok mind ready-k (különben a deploy sikeresnek látszana, miközben
      # pl. az image pull elbukik).
      - name: Wait for rollout
        run: |
          for resource in deployment/service-a deployment/service-b daemonset/nginx-proxy; do
            kubectl -n "$NAMESPACE" rollout status "$resource" --timeout=5m
          done

      # Megvárja, amíg az AWS Load Balancer Controller létrehozza az NLB-t, és a Service
      # státuszába beírja a hostnevét (első telepítésnél ez pár perc).
      - name: Wait for NLB hostname
        id: nlb
        run: |
          kubectl -n "$NAMESPACE" wait service/nginx-proxy \
            --for=jsonpath='{.status.loadBalancer.ingress[0].hostname}' --timeout=10m
          host=$(kubectl -n "$NAMESPACE" get service nginx-proxy \
            -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
          echo "host=${host}" >> "$GITHUB_OUTPUT"
          echo "url=http://${host}" >> "$GITHUB_OUTPUT"
          echo "NLB: ${host}"

      # Smoke teszt a két útvonalra. Egy új NLB-nél a DNS és a target health pár percig tart,
      # ezért a curl saját retry-a próbálkozik újra (minden hibánál, legfeljebb kb. 10 percig).
      - name: Smoke test
        env:
          URL: ${{ steps.nlb.outputs.url }}
        run: |
          check() {
            local path="$1" expected="$2" body
            body=$(curl --fail --silent --show-error --max-time 10 \
              --retry 40 --retry-delay 15 --retry-all-errors --retry-max-time 600 \
              "${URL}${path}")
            echo "${path}: ${body}"
            grep -q "$expected" <<<"$body"
          }
          check /api/sa "Service A"
          check /api/sb "Service B"

      # Az NLB címe és a telepített image tag a job summary-ba.
      - name: Job summary
        env:
          HOST: ${{ steps.nlb.outputs.host }}
        run: |
          {
            echo "### Deploy"
            echo "- Image tag: \`${IMAGE_TAG}\`"
            echo "- NLB: \`${HOST}\`"
            echo "- http://${HOST}/api/sa"
            echo "- http://${HOST}/api/sb"
          } >> "$GITHUB_STEP_SUMMARY"
````

**Ellenőrzés:**

<!-- sbs:check 3.34 -->
```bash
docker run --rm -v "$PWD:/repo" -w /repo rhysd/actionlint:1.7.12 -no-color .github/workflows/_deploy.yml \
  && echo "actionlint OK"
```

Várt kimenet:

```text
actionlint OK
```

### 3.35 .github/workflows/terraform-plan.yml

Plan minden main-re nyitott PR-on. A `pull_request` triggeren **nincs paths szűrő**: a `plan-status` kötelező check, és ha a workflow el sem indulna, a check örökre „Expected” maradna. Helyette a `changes` job dönt **git diff**-fel (harmadik féltől származó action nélkül; a `fetch-depth: 0` kell, különben a diff nem találja a bázist), a kihagyott job a GitHub szerint sikeres, a `plan-status` pedig összegzi az eredményt. A plan a PR kommentjébe kerül, egy rejtett marker alapján frissülve.

Új fájl: `.github/workflows/terraform-plan.yml`.

<!-- sbs:new .github/workflows/terraform-plan.yml -->
````yaml
# Terraform plan minden main-re nyitott PR-on. A pull_request triggeren SZÁNDÉKOSAN nincs
# paths szűrő: a plan-status kötelező status check (branch protection), és egy el sem induló
# workflow checkje örökre "Expected" állapotban maradna. Helyette a changes job git diff-fel
# dönti el, kell-e plan; a kihagyott (skipped) job a GitHub szerint sikeres.
name: terraform-plan

on:
  pull_request:
    branches: [main]
  workflow_dispatch:

# Alapból csak olvasás; a jobok szükség szerint bővítik.
permissions:
  contents: read

# Ugyanarra a PR-ra csak a legfrissebb commit planje fusson, a régebbi megszakítható.
concurrency:
  group: terraform-plan-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: true

jobs:
  # Változott-e a Terraform kód vagy a Terraform workflow-k a PR-ban?
  changes:
    runs-on: ubuntu-24.04
    outputs:
      terraform: ${{ steps.diff.outputs.terraform }}
    steps:
      # A teljes history kell, különben a git diff nem találja a PR bázis commitját.
      - name: Checkout
        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          fetch-depth: 0

      # Három pontos diff: a PR ága mit változtatott a main-hez képest (a közös őstől).
      # workflow_dispatch esetén nincs PR, ilyenkor mindig fut a plan.
      - name: Detect Terraform changes
        id: diff
        env:
          EVENT_NAME: ${{ github.event_name }}
          BASE_SHA: ${{ github.event.pull_request.base.sha }}
          HEAD_SHA: ${{ github.event.pull_request.head.sha }}
        run: |
          if [ "$EVENT_NAME" != "pull_request" ]; then
            changed=true
          elif git diff --quiet "${BASE_SHA}...${HEAD_SHA}" -- terraform/ \
              .github/workflows/terraform-plan.yml .github/workflows/terraform-apply.yml; then
            changed=false
          else
            changed=true
          fi
          echo "terraform=${changed}" >> "$GITHUB_OUTPUT"
          echo "Terraform changed: ${changed}"

  # fmt, init, validate, plan; az eredmény a PR kommentjébe és a job summary-ba kerül.
  plan:
    needs: changes
    if: needs.changes.outputs.terraform == 'true'
    runs-on: ubuntu-24.04
    permissions:
      contents: read
      id-token: write # OIDC token az AWS role felvételéhez
      pull-requests: write # a plan kommentje a PR-ba
    defaults:
      run:
        working-directory: terraform
    env:
      TF_IN_AUTOMATION: "true"
      TF_INPUT: "false"
      # Az account-specifikus értékek a GitHub Variables-ből (a bootstrap állítja be)
      TF_VAR_region: ${{ vars.AWS_REGION }}
      TF_VAR_cluster_name: ${{ vars.CLUSTER_NAME }}
      TF_VAR_cluster_admin_principal_arns: ${{ vars.TF_VAR_cluster_admin_principal_arns }}
      TF_VAR_cluster_plan_principal_arns: ${{ vars.TF_VAR_cluster_plan_principal_arns }}
    steps:
      # A PR merge commitja (a main + a PR változásai): azt planeljük, ami a merge után lesz.
      - name: Checkout
        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1

      # OIDC: rövid életű AWS kulcsok a terraform-plan role-lal, access key nélkül.
      - name: Configure AWS credentials (terraform-plan role)
        uses: aws-actions/configure-aws-credentials@e1253824e5c10ff9df46874f81ed3ec929e19cfd # v6.3.0
        with:
          role-to-assume: ${{ vars.TF_PLAN_ROLE_ARN }}
          aws-region: ${{ vars.AWS_REGION }}

      # Ugyanaz a Terraform verzió, mint a required_version. A wrapper ki van kapcsolva,
      # mert a plan szövegét a terraform show-val fájlba írjuk.
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@dfe3c3f87815947d99a8997f908cb6525fc44e9e # v4.0.1
        with:
          terraform_version: "1.16.4"
          terraform_wrapper: false

      # Formázás ellenőrzése (a modulokban is); a -diff megmutatja, mi a hiba.
      - name: Terraform fmt
        id: fmt
        run: terraform fmt -check -recursive -diff

      # Partial backend configuration: a bucket nevét a TF_STATE_BUCKET variable adja.
      # -lockfile=readonly: a CI nem módosíthatja a commitolt provider lock fájlt.
      - name: Terraform init
        id: init
        run: terraform init -backend-config="bucket=${{ vars.TF_STATE_BUCKET }}" -lockfile=readonly

      # Szintaktikai és típusellenőrzés.
      - name: Terraform validate
        id: validate
        run: terraform validate -no-color

      # A plan fájlba, majd olvasható szövegként a plan.txt-be (a kommenthez és a summary-hoz).
      - name: Terraform plan
        id: plan
        run: |
          terraform plan -var-file=production.tfvars -no-color -lock-timeout=5m -out=tfplan
          terraform show -no-color tfplan > plan.txt

      # Job summary: a lépések eredménye és a teljes plan (akkor is, ha valamelyik lépés elbukott).
      - name: Job summary
        if: always()
        env:
          FMT: ${{ steps.fmt.outcome }}
          INIT: ${{ steps.init.outcome }}
          VALIDATE: ${{ steps.validate.outcome }}
          PLAN: ${{ steps.plan.outcome }}
        run: |
          {
            echo "### Terraform plan"
            echo "| fmt | init | validate | plan |"
            echo "| --- | --- | --- | --- |"
            echo "| ${FMT} | ${INIT} | ${VALIDATE} | ${PLAN} |"
            if [ -f plan.txt ]; then
              echo '```'
              cat plan.txt
              echo '```'
            fi
          } >> "$GITHUB_STEP_SUMMARY"

      # PR komment: egy rejtett marker alapján megkeresi a korábbi kommentet, és azt frissíti,
      # így a PR-ban mindig csak egy, a legfrissebb plan-t mutató komment van.
      - name: Comment plan on PR
        if: always() && github.event_name == 'pull_request'
        uses: actions/github-script@3a2844b7e9c422d3c10d287c895573f7108da1b3 # v9.0.0
        env:
          FMT: ${{ steps.fmt.outcome }}
          INIT: ${{ steps.init.outcome }}
          VALIDATE: ${{ steps.validate.outcome }}
          PLAN: ${{ steps.plan.outcome }}
        with:
          script: |
            const fs = require('fs');
            const marker = '<!-- terraform-plan -->';
            const maxLength = 60000; // a GitHub komment felső határa 65536 karakter

            let plan = 'A plan nem készült el, lásd a job logját.';
            if (fs.existsSync('terraform/plan.txt')) {
              plan = fs.readFileSync('terraform/plan.txt', 'utf8');
              if (plan.length > maxLength) {
                plan = plan.slice(0, maxLength) + '\n... (csonkolva, a teljes plan a job summary-ban van)';
              }
            }

            const { FMT, INIT, VALIDATE, PLAN } = process.env;
            const runUrl = `${context.serverUrl}/${context.repo.owner}/${context.repo.repo}/actions/runs/${context.runId}`;
            const body = [
              marker,
              '### Terraform plan',
              '| fmt | init | validate | plan |',
              '| --- | --- | --- | --- |',
              `| ${FMT} | ${INIT} | ${VALIDATE} | ${PLAN} |`,
              '',
              `<details><summary>Plan (commit ${context.sha.substring(0, 7)})</summary>`,
              '',
              '```',
              plan,
              '```',
              '',
              '</details>',
              '',
              `[Workflow run](${runUrl})`,
            ].join('\n');

            const { owner, repo } = context.repo;
            const issue_number = context.issue.number;
            const comments = await github.paginate(github.rest.issues.listComments, { owner, repo, issue_number });
            const existing = comments.find(c => c.user.type === 'Bot' && c.body.includes(marker));

            if (existing) {
              await github.rest.issues.updateComment({ owner, repo, comment_id: existing.id, body });
            } else {
              await github.rest.issues.createComment({ owner, repo, issue_number, body });
            }

  # Gyűjtő job: ez a kötelező status check. Akkor sikeres, ha a changes lefutott, és a plan
  # sikeres volt vagy nem kellett (skipped). Az if: always() miatt akkor is lefut, ha a plan elbukott.
  plan-status:
    needs: [changes, plan]
    if: always()
    runs-on: ubuntu-24.04
    steps:
      # A függőségek eredményének ellenőrzése.
      - name: Check results
        env:
          CHANGES: ${{ needs.changes.result }}
          PLAN: ${{ needs.plan.result }}
        run: |
          echo "changes: ${CHANGES}, plan: ${PLAN}"
          [ "$CHANGES" = "success" ] || exit 1
          case "$PLAN" in
            success | skipped) ;;
            *) exit 1 ;;
          esac
````

**Ellenőrzés:**

<!-- sbs:check 3.35 -->
```bash
docker run --rm -v "$PWD:/repo" -w /repo rhysd/actionlint:1.7.12 -no-color .github/workflows/terraform-plan.yml \
  && echo "actionlint OK"
```

Várt kimenet:

```text
actionlint OK
```

### 3.36 .github/workflows/terraform-apply.yml

Apply a main-en, `production` environmenttel és `concurrency: terraform-production` csoporttal (egy félbeszakított apply félkész infrastruktúrát hagyna, ezért nincs megszakítás). Az apply UTÁN (`needs`) meghívja a `_build.yml`-t és a `_deploy.yml`-t a commit SHA-val, így egy friss infrastruktúrán is lesz alkalmazás. A paths szűrőben a hívott workflow-k is benne vannak.

Új fájl: `.github/workflows/terraform-apply.yml`.

<!-- sbs:new .github/workflows/terraform-apply.yml -->
````yaml
# Terraform apply a main ágon, majd build és deploy ugyanazzal a commit SHA-val.
# Az apply után mindig buildel és deployol, hogy egy friss (vagy újraépített) infrastruktúrán
# is legyen futó alkalmazás. A paths szűrőben a hívott workflow-k is benne vannak; a
# build-and-push.yml ugyanezt a listát figyeli, és ilyenkor nem fut párhuzamosan vele.
name: terraform-apply

on:
  push:
    branches: [main]
    paths:
      - "terraform/**"
      - ".github/workflows/terraform-apply.yml"
      - ".github/workflows/_build.yml"
      - ".github/workflows/_deploy.yml"
  workflow_dispatch:

# Alapból csak olvasás; a jobok szükség szerint bővítik.
permissions:
  contents: read

jobs:
  # Az infrastruktúra frissítése. A plan-t a PR-ban néztük át, ezért itt -auto-approve.
  apply:
    runs-on: ubuntu-24.04
    # production environment: csak a main ágról, és a terraform-apply role trust policyja erre szól.
    environment: production
    # Egyszerre egy Terraform futás (apply vagy destroy); a következő megvárja, nem szakítja meg
    # (egy félbeszakított apply félkész infrastruktúrát és zárolt state-et hagyna).
    concurrency:
      group: terraform-production
      cancel-in-progress: false
    permissions:
      contents: read
      id-token: write # OIDC token az AWS role felvételéhez
    defaults:
      run:
        working-directory: terraform
    env:
      TF_IN_AUTOMATION: "true"
      TF_INPUT: "false"
      # Az account-specifikus értékek a GitHub Variables-ből (a bootstrap állítja be)
      TF_VAR_region: ${{ vars.AWS_REGION }}
      TF_VAR_cluster_name: ${{ vars.CLUSTER_NAME }}
      TF_VAR_cluster_admin_principal_arns: ${{ vars.TF_VAR_cluster_admin_principal_arns }}
      TF_VAR_cluster_plan_principal_arns: ${{ vars.TF_VAR_cluster_plan_principal_arns }}
    steps:
      # A main ág aktuális commitja.
      - name: Checkout
        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1

      # OIDC: rövid életű AWS kulcsok a terraform-apply role-lal, access key nélkül.
      - name: Configure AWS credentials (terraform-apply role)
        uses: aws-actions/configure-aws-credentials@e1253824e5c10ff9df46874f81ed3ec929e19cfd # v6.3.0
        with:
          role-to-assume: ${{ vars.TF_APPLY_ROLE_ARN }}
          aws-region: ${{ vars.AWS_REGION }}

      # Ugyanaz a Terraform verzió, mint a required_version.
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@dfe3c3f87815947d99a8997f908cb6525fc44e9e # v4.0.1
        with:
          terraform_version: "1.16.4"
          terraform_wrapper: false

      # Partial backend configuration: a bucket nevét a TF_STATE_BUCKET variable adja.
      - name: Terraform init
        run: terraform init -backend-config="bucket=${{ vars.TF_STATE_BUCKET }}" -lockfile=readonly

      # Az apply. A lock-timeout miatt egy éppen futó másik művelet zárolását kivárja.
      - name: Terraform apply
        run: terraform apply -var-file=production.tfvars -auto-approve -no-color -lock-timeout=10m

      # A fontosabb outputok a job summary-ba.
      - name: Job summary
        run: |
          {
            echo "### Terraform apply"
            echo '```'
            terraform output -no-color
            echo '```'
          } >> "$GITHUB_STEP_SUMMARY"

  # Build és push az apply UTÁN (needs), a jelenlegi commit SHA-val. Ha a tag már létezik
  # az ECR-ben, a _build.yml kihagyja.
  build:
    needs: apply
    uses: ./.github/workflows/_build.yml
    permissions:
      contents: read
      id-token: write
    with:
      push: true
      image_tag: ${{ github.sha }}

  # Deploy a build UTÁN (needs), ugyanazzal a taggel.
  deploy:
    needs: build
    uses: ./.github/workflows/_deploy.yml
    permissions:
      contents: read
      id-token: write
    with:
      image_tag: ${{ github.sha }}
````

**Ellenőrzés:**

<!-- sbs:check 3.36 -->
```bash
docker run --rm -v "$PWD:/repo" -w /repo rhysd/actionlint:1.7.12 -no-color .github/workflows/terraform-apply.yml \
  && echo "actionlint OK"
```

Várt kimenet:

```text
actionlint OK
```

### 3.37 .github/workflows/build-and-push.yml

Az alkalmazás CI/CD-je: PR-on csak build (ha a `src/` változott), a main-en build, push és deploy. Pushnál a `changes` job `git diff github.event.before github.sha`-val nézi, változott-e a `terraform-apply.yml` által figyelt fájlok bármelyike. Ha igen, ez a workflow se nem buildel, se nem deployol: a terraform-apply.yml az apply után megteszi, így a sorrend garantált, és nincs versenyhelyzet ugyanarra az IMMUTABLE tagre. A kötelező check a `build-status` gyűjtő job, mert a hívott workflow checkjeinek neve futáskor más, mint kihagyáskor.

Új fájl: `.github/workflows/build-and-push.yml`.

<!-- sbs:new .github/workflows/build-and-push.yml -->
````yaml
# Az alkalmazás CI/CD-je.
# - push a main-re (src/, k8s/ vagy a build/deploy workflow-k változtak): build + push + deploy.
#   Ha ugyanebben a pushban a terraform-apply.yml is elindul (terraform/ vagy az általa hívott
#   workflow-k változtak), ez a workflow NEM buildel és NEM deployol: a terraform-apply.yml az
#   apply UTÁN ugyanezzel a commit SHA-val buildel és deployol, így a sorrend garantált, és nincs
#   versenyhelyzet ugyanarra az IMMUTABLE tagre.
# - pull_request: csak build (push és AWS nélkül), ha a src/ változott. A pull_request triggeren
#   nincs paths szűrő, mert a build-status kötelező status check (lásd terraform-plan.yml).
# - workflow_dispatch: build + push + deploy a kiválasztott ág fejéről (a production environment
#   miatt csak main).
name: build-and-push

on:
  push:
    branches: [main]
    paths:
      - "src/**"
      - "k8s/**"
      - ".github/workflows/build-and-push.yml"
      - ".github/workflows/_build.yml"
      - ".github/workflows/_deploy.yml"
  pull_request:
    branches: [main]
  workflow_dispatch:

# Alapból csak olvasás; a hívott workflow-k jobjai szükség szerint bővítik (vagy szűkítik).
permissions:
  contents: read

# PR-on a régebbi futás megszakítható; a main-en nem (a deploy concurrency-je amúgy is sorba állít).
concurrency:
  group: build-and-push-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: ${{ github.event_name == 'pull_request' }}

jobs:
  # Mi változott? PR-on: a src/ a main-hez képest. Pushnál: a terraform-apply.yml paths szűrője
  # a push előtti és utáni commit között (github.event.before..github.sha).
  changes:
    runs-on: ubuntu-24.04
    outputs:
      build: ${{ steps.diff.outputs.build }}
    steps:
      # A teljes history kell, különben a git diff nem találja a bázis (before / base) commitot.
      - name: Checkout
        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          fetch-depth: 0

      # A döntés git diff-fel, harmadik féltől származó action nélkül.
      - name: Detect changes
        id: diff
        env:
          EVENT_NAME: ${{ github.event_name }}
          BASE_SHA: ${{ github.event.pull_request.base.sha }}
          HEAD_SHA: ${{ github.event.pull_request.head.sha }}
          BEFORE_SHA: ${{ github.event.before }}
          AFTER_SHA: ${{ github.sha }}
        run: |
          # A terraform-apply.yml push paths szűrője: ha ezek közül bármi változott, az a workflow
          # is elindul, és az apply után ő buildel és deployol.
          apply_paths=(terraform/ .github/workflows/terraform-apply.yml
            .github/workflows/_build.yml .github/workflows/_deploy.yml)

          case "$EVENT_NAME" in
            pull_request)
              if git diff --quiet "${BASE_SHA}...${HEAD_SHA}" -- src/ \
                  .github/workflows/build-and-push.yml .github/workflows/_build.yml; then
                build=false
              else
                build=true
              fi
              ;;
            push)
              if [[ "$BEFORE_SHA" =~ ^0+$ ]] || ! git cat-file -e "${BEFORE_SHA}^{commit}" 2>/dev/null; then
                # Nincs összehasonlítható előző commit (pl. az ág első pusha): deployolunk.
                echo "::warning::A push előtti commit nem elérhető, a terraform/ változását nem lehet ellenőrizni."
                build=true
              elif git diff --quiet "$BEFORE_SHA" "$AFTER_SHA" -- "${apply_paths[@]}"; then
                build=true
              else
                echo "A pushban a terraform-apply.yml által figyelt fájlok is változtak: az buildel és deployol."
                build=false
              fi
              ;;
            *)
              build=true
              ;;
          esac
          echo "build=${build}" >> "$GITHUB_OUTPUT"
          echo "build: ${build}"

  # Build: PR-on csak build (check job), egyébként build + push (push job, production environment).
  build:
    needs: changes
    if: needs.changes.outputs.build == 'true'
    uses: ./.github/workflows/_build.yml
    permissions:
      contents: read
      id-token: write # csak a push job használja; a check job maga szűkíti contents: read-re
    with:
      push: ${{ github.event_name != 'pull_request' }}
      image_tag: ${{ github.sha }}

  # Deploy a frissen feltöltött commit SHA taggel (PR-on soha).
  deploy:
    needs: [changes, build]
    if: needs.changes.outputs.build == 'true' && github.event_name != 'pull_request'
    uses: ./.github/workflows/_deploy.yml
    permissions:
      contents: read
      id-token: write
    with:
      image_tag: ${{ github.sha }}

  # Gyűjtő job: ez a kötelező status check. A hívott workflow jobjainak neve futáskor más, mint
  # kihagyáskor (build / check (service-a) vs. build), ezért a check egy stabil nevű jobra szól.
  # Sikeres, ha a changes lefutott, és a build sikeres volt vagy nem kellett (skipped).
  build-status:
    needs: [changes, build]
    if: always()
    runs-on: ubuntu-24.04
    steps:
      # A függőségek eredményének ellenőrzése.
      - name: Check results
        env:
          CHANGES: ${{ needs.changes.result }}
          BUILD: ${{ needs.build.result }}
        run: |
          echo "changes: ${CHANGES}, build: ${BUILD}"
          [ "$CHANGES" = "success" ] || exit 1
          case "$BUILD" in
            success | skipped) ;;
            *) exit 1 ;;
          esac
````

**Ellenőrzés:**

<!-- sbs:check 3.37 -->
```bash
docker run --rm -v "$PWD:/repo" -w /repo rhysd/actionlint:1.7.12 -no-color .github/workflows/build-and-push.yml \
  && echo "actionlint OK"
```

Várt kimenet:

```text
actionlint OK
```

### 3.38 .github/workflows/destroy.yml

Lebontás csak kézzel, a `destroy` szó beírásával. A sorrend: előbb a Kubernetes erőforrások (az NLB-t a controller hozta létre, neki kell törölnie, amíg a cluster él), megvárja az NLB eltűnését, utána `terraform destroy`. Ugyanabban a concurrency csoportban van, mint az apply, így a kettő soha nem fut egyszerre. A bootstrapet és az OIDC providert nem bontja le.

Új fájl: `.github/workflows/destroy.yml`.

<!-- sbs:new .github/workflows/destroy.yml -->
````yaml
# A teljes alkalmazás és infrastruktúra lebontása, csak kézi indítással és megerősítéssel.
# A sorrend: előbb a Kubernetes erőforrások (az NLB-t az AWS Load Balancer Controller hozta
# létre, nem a Terraform, ezért a controllernek kell törölnie, amíg a cluster még létezik),
# utána a terraform destroy. A bootstrapet (state bucket, GitHub Actions role-ok) és a GitHub
# OIDC providert NEM bontja le.
name: destroy

on:
  workflow_dispatch:
    inputs:
      confirm:
        description: 'Írd be: destroy'
        type: string
        required: true

permissions:
  contents: read

jobs:
  destroy:
    # Csak a pontos megerősítő szóval fut; minden más esetben a job kimarad.
    if: inputs.confirm == 'destroy'
    runs-on: ubuntu-24.04
    environment: production
    # Ugyanaz a csoport, mint az apply-é: a kettő soha nem fut egyszerre.
    concurrency:
      group: terraform-production
      cancel-in-progress: false
    permissions:
      contents: read
      id-token: write # OIDC token az AWS role felvételéhez
    env:
      AWS_REGION: ${{ vars.AWS_REGION }}
      CLUSTER_NAME: ${{ vars.CLUSTER_NAME }}
      NAMESPACE: demo
      TF_IN_AUTOMATION: "true"
      TF_INPUT: "false"
      TF_VAR_region: ${{ vars.AWS_REGION }}
      TF_VAR_cluster_name: ${{ vars.CLUSTER_NAME }}
      TF_VAR_cluster_admin_principal_arns: ${{ vars.TF_VAR_cluster_admin_principal_arns }}
      TF_VAR_cluster_plan_principal_arns: ${{ vars.TF_VAR_cluster_plan_principal_arns }}
    steps:
      # A manifestek (a törléshez a k8s/base elég: a delete csak a neveket nézi) és a Terraform kód.
      - name: Checkout
        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1

      # OIDC: a terraform-apply role (cluster admin a Kubernetesben, és a destroyhoz is ez kell).
      - name: Configure AWS credentials (terraform-apply role)
        uses: aws-actions/configure-aws-credentials@e1253824e5c10ff9df46874f81ed3ec929e19cfd # v6.3.0
        with:
          role-to-assume: ${{ vars.TF_APPLY_ROLE_ARN }}
          aws-region: ${{ vars.AWS_REGION }}

      # A cluster verziójához illő kubectl.
      - name: Setup kubectl
        uses: azure/setup-kubectl@bda439f5f36b99b262ebdcd3613869bddb064c8e # v5.2.0
        with:
          version: v1.37.2

      # Ugyanaz a Terraform verzió, mint a required_version.
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@dfe3c3f87815947d99a8997f908cb6525fc44e9e # v4.0.1
        with:
          terraform_version: "1.16.4"
          terraform_wrapper: false

      # Létezik még a cluster? Ha nem (pl. egy félbeszakadt destroy után), a Kubernetes lépések kimaradnak.
      - name: Check cluster
        id: cluster
        run: |
          if aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" >/dev/null 2>&1; then
            aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$AWS_REGION"
            echo "exists=true" >> "$GITHUB_OUTPUT"
          else
            echo "A cluster nem létezik, a Kubernetes lépések kimaradnak."
            echo "exists=false" >> "$GITHUB_OUTPUT"
          fi

      # Az NLB ARN-je a Service hostnevéből, MIELŐTT a Service törlődik (utána már nem kérdezhető le).
      - name: Find NLB
        id: nlb
        if: steps.cluster.outputs.exists == 'true'
        run: |
          host=$(kubectl -n "$NAMESPACE" get service nginx-proxy \
            -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' --ignore-not-found)
          arn=""
          if [ -n "$host" ]; then
            arn=$(aws elbv2 describe-load-balancers \
              --query "LoadBalancers[?DNSName=='${host}'].LoadBalancerArn" --output text)
          fi
          echo "arn=${arn}" >> "$GITHUB_OUTPUT"
          echo "NLB: ${host:-nincs} ${arn}"

      # A kubectl parancs: az alkalmazás törlése. A --wait a Service controller finalizere miatt
      # csak akkor tér vissza, amikor a controller már törölte az NLB-t és a target groupokat.
      - name: kubectl delete
        if: steps.cluster.outputs.exists == 'true'
        run: kubectl delete -k k8s/base --ignore-not-found --wait=true --timeout=10m

      # Biztonsági ellenőrzés az AWS oldalon: megvárja, amíg az NLB ténylegesen eltűnik, különben a
      # terraform destroy elakadna a VPC-n (a gazdátlan NLB ENI-jei miatt).
      - name: Wait for NLB deletion
        if: steps.nlb.outputs.arn != ''
        env:
          NLB_ARN: ${{ steps.nlb.outputs.arn }}
        run: aws elbv2 wait load-balancers-deleted --load-balancer-arns "$NLB_ARN"

      # Partial backend configuration, mint az apply-nál.
      - name: Terraform init
        working-directory: terraform
        run: terraform init -backend-config="bucket=${{ vars.TF_STATE_BUCKET }}" -lockfile=readonly

      # Minden más (EKS, VPC, NAT, ECR, IAM) lebontása.
      - name: Terraform destroy
        working-directory: terraform
        run: terraform destroy -var-file=production.tfvars -auto-approve -no-color -lock-timeout=10m
````

**Ellenőrzés:**

<!-- sbs:check 3.38 -->
```bash
docker run --rm -v "$PWD:/repo" -w /repo rhysd/actionlint:1.7.12 -no-color .github/workflows/destroy.yml \
  && echo "actionlint OK"
```

Várt kimenet:

```text
actionlint OK
```

### 3.39 .github/dependabot.yml

A SHA-ra rögzített actionök nem frissülnek maguktól; a Dependabot hetente PR-t nyit, és a SHA-t és a mellette lévő verzió kommentet is frissíti.

Új fájl: `.github/dependabot.yml`.

<!-- sbs:new .github/dependabot.yml -->
````yaml
# Dependabot: hetente PR-t nyit, ha a workflow-kban használt actionöknek új verziója jelent meg.
# A SHA-ra rögzített actionöknél a SHA-t és a mellette lévő verzió kommentet is frissíti.
version: 2
updates:
  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: weekly
````

**Ellenőrzés:**

<!-- sbs:check 3.39 -->
```bash
python3 -c 'import yaml; u = yaml.safe_load(open(".github/dependabot.yml"))["updates"][0]; print(u["package-ecosystem"], u["schedule"]["interval"])'
```

Várt kimenet:

```text
github-actions weekly
```

### 3.40 README.md

A README teljesen új: architektúra ábrával, a workflow-k táblázata, a repó szerkezete, a használat a nulláról, a tesztparancsok, a lebontás és a döntések indoklása. A teljes fájl következik.

Módosított fájl, a teljes új tartalom: `README.md`

<!-- sbs:new README.md -->
````markdown
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
git switch -c feature/pipeline
git add -A && git commit -m "GitHub Actions CI/CD pipeline"
git push -u origin feature/pipeline
```

A push egy nem main ágra a bootstrap előtt is biztonságos (a workflow-k csak main pushra és main-re nyitott PR-ra indulnak), a PR-t viszont csak a bootstrap után nyisd meg. PR a main-re a GitHubon. Lefut a `terraform-plan` (a plan kommentben: a teljes infrastruktúra létrehozása) és a `build-and-push` (push nélküli build). Ha a `plan-status` és a `build-status` zöld, mergeld. A main-en elindul a `terraform-apply.yml`: apply (kb. 15–20 perc), build, push, deploy. A `build-and-push.yml` ilyenkor nem deployol, mert a `terraform/` is változott. A deploy job summary-jában ott az NLB DNS neve.

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
````

**Ellenőrzés:**

<!-- sbs:check 3.40 -->
```bash
head -1 README.md
```

Várt kimenet:

```text
# EKS nginx proxy – GitHub Actions CI/CD pipeline
```

### 3.41 docs/notes.md

Az 1on1 felkészítő, teljesen új tartalommal (GitHub Actions és CI/CD, ennek a projektnek a workflow-ival). A teljes fájl következik.

Módosított fájl, a teljes új tartalom: `docs/notes.md`

<!-- sbs:new docs/notes.md -->
````markdown
# 1on1 felkészítő

A két 1on1 témái, ennek a repónak a workflow-ival példának. A fájlnevek a `.github/workflows/` alá mutatnak.

---

## 1. GitHub Actions

### Workflow, job, step

- **Workflow:** egy YAML fájl a `.github/workflows/` alatt. Megmondja, *mikor* fut (`on:`) és *mit* csinál (`jobs:`). Példa: a `terraform-plan.yml` egy workflow.
- **Job:** egy workflow-n belüli egység, amely **saját, friss runneren** (virtuális gépen) fut. A jobok alapból **párhuzamosan** futnak, a sorrendet a `needs:` adja. Minden jobnak saját fájlrendszere van: ami az egyik jobban készült, az a másikban nincs meg, csak `outputs`-on vagy artifacton keresztül adható át. Példa: a `terraform-plan.yml`-ben a `changes` → `plan` → `plan-status`.
- **Step:** egy job lépése, és a job összes stepje **ugyanazon a runneren, egymás után** fut, közös fájlrendszerrel. Egy step vagy egy action (`uses:`), vagy egy shell parancs (`run:`). Példa: a `plan` jobban a `Checkout` → `Configure AWS credentials` → `Terraform init` → ….

**Step vagy job?** Ha a lépéseknek közös fájlokra (checkout, kubeconfig, plan fájl) és sorrendre van szükségük, akkor ugyanannak a jobnak a stepjei. Új job akkor kell, ha a munka más jogot vagy környezetet kér (`permissions`, `environment`), ha párhuzamosan futhat (a mátrix két buildje), vagy ha egy feltétel (`if`) egészében kihagyhatja. Példa: a `_deploy.yml` minden lépése egy job, mert a `kustomize edit` által módosított fájlt a `kubectl apply`-nak ugyanott kell látnia. A `_build.yml` `check` és `push` jobja viszont külön job, mert más a joguk és az environmentjük.

### actions/checkout

A runner egy üres gép, a repó kódja nincs rajta. Az `actions/checkout` klónozza a repót a workspace-be (`$GITHUB_WORKSPACE`) az eseményhez tartozó commitra: pushnál a `github.sha`-ra, PR-nál a PR merge commitjára (`refs/pull/<n>/merge`). Szinte mindig ez az **első step**, mert minden további lépés (`terraform init`, `docker build src/...`, `kubectl apply -k k8s/...`) a repó fájljaival dolgozik.

Alapból csak **egy commitot** tölt le (`fetch-depth: 1`). Ezért a `changes` jobokban `fetch-depth: 0` van: a `git diff BASE...HEAD`-hez a bázis commit és a közös ős is kell, egy commitból a diff nem tudná, mihez hasonlítson.

### Event filterek

```yaml
on:
  push:
    branches: [main]
    paths:
      - "src/**"
      - "k8s/**"
```

- **`branches`**: melyik ágra érkező eseménynél fusson. Pushnál a cél ág, PR-nál a PR **bázis** ága (`pull_request: branches: [main]` = a main-re nyitott PR-ok).
- **`paths`**: csak akkor fusson, ha **legalább egy** megváltozott fájl illeszkedik a mintára. A `**` minden alkönyvtárra illeszkedik.
- **`paths-ignore`**: fordítva, akkor NEM fut, ha **minden** megváltozott fájl illeszkedik (pl. `paths-ignore: ["**.md"]`: csak dokumentáció változásnál nincs build). Ugyanarra az eseményre a `paths` és a `paths-ignore` közül csak az egyik használható; a `paths`-ban a `!` előtaggal lehet kivételt tenni.
- **ÉS kapcsolat:** ha egy eseménynél több filter van (`branches` ÉS `paths`), **mindegyiknek** teljesülnie kell. A fenti példa csak akkor fut, ha main-re érkezett a push, ÉS változott valami a `src/` vagy a `k8s/` alatt. Egy filteren belül a lista elemei között VAGY kapcsolat van.

**Miért `paths: ['src/**']`?** Hogy a build csak akkor fusson, ha a kód tényleg változott. Egy README javítás miatt nem kell image-et buildelni és deployolni. Ez időt és pénzt spórol, és nem kerül feleslegesen új tag az ECR-be. Ebben a repóban a `build-and-push.yml` push triggere a `src/**`, a `k8s/**` és a saját workflow fájljai, a `terraform-apply.yml`-é a `terraform/**` és a saját workflow fájljai.

**Csapda (ezt itt meg is oldottuk):** ha egy workflow `paths` miatt el sem indul, a checkje nem „skipped”, hanem **meg sem jelenik**. Ha ez a check kötelező a branch protectionben, a PR örökre „Expected – Waiting” állapotban marad. Ezért a `pull_request` triggeren nincs `paths`: a `changes` job dönt `git diff`-fel, a kihagyott job a GitHub szerint sikeres, a kötelező check pedig a mindig lefutó `plan-status` / `build-status` gyűjtő job.

### Contextek: github, env, vars, secrets

- **`github`**: az eseményről és a futásról szóló adatok. Példák: `github.sha` (a commit, nálunk ez az image tag), `github.ref`, `github.event_name`, `github.event.before` (a push előtti commit, a `build-and-push.yml` ehhez hasonlít), `github.event.pull_request.base.sha`.
- **`env`**: a workflowban megadott környezeti változók (`env:` kulcs). A stepekben shell változóként is elérhetők (`$CLUSTER_NAME`), kifejezésben `${{ env.REPOSITORY }}`.
- **`vars`**: a repó (vagy organization, environment) **Variables**-ei, a GitHub beállításaiban tárolt, nem titkos konfiguráció. Nálunk a bootstrap hozza létre őket: `vars.AWS_REGION`, `vars.CLUSTER_NAME`, `vars.TF_STATE_BUCKET`, `vars.APP_ROLE_ARN` stb.
- **`secrets`**: titkos értékek. Titkosítva tárolódnak, a logban `***`-ként jelennek meg, és fork PR-ok nem kapják meg. Nálunk **nincs secret**, mert az OIDC miatt nincs tárolt AWS kulcs (a `GITHUB_TOKEN`-t a GitHub minden futáshoz automatikusan adja).

### env vs vars

- A **`vars`** a workflow fájlon **kívül**, a GitHub beállításaiban él. Kódváltozás nélkül módosítható, több workflow is olvashatja, és **nem kerül a kódba**. Ezért itt vannak az account-specifikus értékek (role ARN-ek, bucket név): a repó publikus.
- Az **`env`** a workflow fájlban van megadva, és a stepek **környezeti változóként** látják. Ide jönnek a futás belső értékei. Gyakran a kettőt összekötjük: `env: TF_VAR_cluster_name: ${{ vars.CLUSTER_NAME }}`. A `vars` a forrás, az `env` teszi elérhetővé a programnak (itt a Terraformnak, amely a `TF_VAR_*` környezeti változókat olvassa).

### Változó precedencia

Az `env` három szinten adható meg: workflow, job, step. **A szűkebb szint nyer**: step > job > workflow. Ha ugyanaz a változó workflow és job szinten is szerepel, a job stepjei a **job szintű** értéket látják, a többi job a workflow szintűt. A `vars`-nál ugyanez a logika érvényes: environment > repository > organization.

Ebben a repóban a `_deploy.yml` job szinten adja meg az `IMAGE_TAG`-et, és a `Kustomize edit` step a saját `env:`-jében ad hozzá egy `REGISTRY`-t, amely csak abban a stepben él.

### Expressionök és if feltételek

A `${{ ... }}` egy **expression**: a GitHub értékeli ki, mielőtt a step lefut, a shell már csak az eredményt látja. Operátorok: `==`, `!=`, `&&`, `||`, `!`. Függvények: `contains()`, `startsWith()`, `format()`, `toJSON()`, `always()`, `success()`, `failure()`, `cancelled()`.

Az **`if:`** jobra vagy stepre tehető. Alapból egy job csak akkor fut, ha a `needs` jobjai sikeresek voltak (`success()`). Példák a repóból:

- `if: needs.changes.outputs.terraform == 'true'`: a plan csak Terraform változásnál fut;
- `if: ${{ !inputs.push }}` / `if: ${{ inputs.push }}`: a `_build.yml` két jobja közül mindig csak az egyik fut;
- `if: always()`: a gyűjtő job és a PR komment akkor is lefut, ha előtte valami elbukott;
- `if: inputs.confirm == 'destroy'`: a destroy csak a megerősítő szóval fut.

**Miért `contains(github.event.head_commit.message, '[skip-tests]')`?** Ezzel a commit üzenetéből vezérelhető egy step vagy job. Például `if: ${{ !contains(github.event.head_commit.message, '[skip-tests]') }}` esetén a tesztek kimaradnak, ha a commit üzenetben szerepel a `[skip-tests]`. A `contains()` részszöveget keres (kis- és nagybetűtől függetlenül), így az üzenet bárhol tartalmazhatja a jelölőt. A `head_commit` csak push eseménynél létezik, PR-nál üres. (A GitHub beépítve ismeri a `[skip ci]`-t, amely az egész workflow-t kihagyja.) Ebben a repóban ilyet nem használunk, mert a teszt (plan, build) a kötelező check része.

**Miért expression egy alapértékhez (`||`)?** Az expressionben az `a || b` az első „igaz” (nem üres, nem `false`, nem 0) értéket adja vissza, ezért alapértékre használható. Példa a repóból:

```yaml
concurrency:
  group: terraform-plan-${{ github.event.pull_request.number || github.ref }}
```

PR-nál a PR száma a csoport, `workflow_dispatch`-nél (ahol nincs PR szám) a `github.ref`. Shellben a `${VAR:-default}` ugyanez, de az expression már a futás előtt kiértékelődik, így olyan helyen is működik, ahol nincs shell (`concurrency`, `with:` inputok, `environment`).

### Mit tartalmaz a github.ref?

A futást kiváltó **teljes git ref**:
- push egy ágra: `refs/heads/main`;
- tag push: `refs/tags/v1.0.0`;
- pull_request: `refs/pull/<PR szám>/merge` (a PR merge commitja);
- workflow_dispatch: a kiválasztott ág, pl. `refs/heads/main`.

A rövid név a `github.ref_name` (pl. `main`). Az OIDC tokenben is szerepel: environment nélküli jobnál a `sub` claim `repo:SziNo/eks-nginx-proxy-pipeline:ref:refs/heads/main` (ezért fogadja el a plan role a main ágról indított kézi plant), PR-nál `...:pull_request`.

### Miért secrets és nem sima szöveg?

Egy jelszó vagy kulcs a workflow fájlban sima szövegként a git historyba kerül (publikus repónál bárki láthatja, és egy törlés után is megmarad). A logban is megjelenne. A **secret** titkosítva tárolódik, a logban automatikusan maszkolódik (`***`), fork PR-ok nem kapják meg, és kódváltozás nélkül cserélhető.

Még jobb, ha **nincs tárolt titok**: ezt adja az OIDC. A GitHub minden jobhoz rövid életű tokent ad, amelyet az AWS STS egy órán belül lejáró kulcsokra cserél. Ezért ebben a repóban nincs AWS secret.

### Third-party actionök, megbízható forrás, SHA rögzítés

Egy action más kódja, amely **a mi jogainkkal** fut a runneren: látja a checkoutolt kódot, a `GITHUB_TOKEN`-t, az AWS kulcsokat. Egy rosszindulatú vagy feltört action ezeket ellophatja. Volt már ilyen támadás: 2025-ben a `tj-actions/changed-files` tagjeit átírták, és a CI secretek a logokba kerültek.

- **Megbízható forrás:** lehetőleg a GitHub (`actions/*`), a szolgáltató (`aws-actions/*`, `docker/*`, `hashicorp/*`, `azure/*`) vagy a Marketplace-en „verified creator” jelöléssel ellátott actionök. Ebben a repóban csak ilyenek vannak. A változásdetektálásra **szándékosan nincs** third-party action (pl. `dorny/paths-filter`): a `git diff` elég.
- **SHA rögzítés:** a `@v4` egy tag, amelyet a gazdája (vagy egy támadó) bármikor átírhat egy másik commitra. A teljes commit SHA (`@3d3c42e5...`) megváltoztathatatlan. A mellette lévő `# v7.0.1` komment az olvasónak szól. A **Dependabot** (`.github/dependabot.yml`) hetente PR-t nyit, ha új verzió jön, és a SHA-t és a kommentet is frissíti.

### GitHub-hosted vs self-hosted runner

- **GitHub-hosted** (`runs-on: ubuntu-24.04`): a GitHub üzemelteti. Minden job **friss, eldobható** VM-en fut, előre telepített eszközökkel (docker, AWS CLI, kustomize stb.). Publikus repóban ingyenes, nincs vele üzemeltetési teher. Hátránya, hogy nem fix az IP-je, nem lát bele privát hálózatba, és a gép mérete kötött.
- **Self-hosted:** a saját gépünkön vagy VM-ünkön fut a runner agent.

**Mikor self-hosted?** Ha a runnernek **privát hálózatot** kell elérnie (pl. egy csak privát endpointú EKS API-t vagy egy belső adatbázist), ha speciális hardver kell (GPU, ARM, sok memória), ha fix IP kell (allowlist), vagy ha nagy mennyiségnél olcsóbb. **Publikus repóban kerülendő:** egy fork PR-ja tetszőleges kódot futtathatna a saját gépünkön, és a nem eldobható gépen a következő futásra is maradhat utána valami. Ebben a projektben GitHub-hosted runner van, ezért kell az EKS API publikus endpointja (`cluster_endpoint_public_access_cidrs`).

---

## 2. CI/CD ebben a projektben

### Mi indítja az egyes workflow-kat?

| Workflow | Trigger | paths |
| --- | --- | --- |
| `terraform-plan.yml` | `pull_request` → main, `workflow_dispatch` | nincs (a `changes` job dönt: `terraform/`, `terraform-plan.yml`, `terraform-apply.yml`) |
| `terraform-apply.yml` | `push` → main, `workflow_dispatch` | `terraform/**`, `terraform-apply.yml`, `_build.yml`, `_deploy.yml` |
| `build-and-push.yml` | `push` → main | `src/**`, `k8s/**`, `build-and-push.yml`, `_build.yml`, `_deploy.yml` |
| | `pull_request` → main | nincs (a `changes` job dönt: `src/`, `build-and-push.yml`, `_build.yml`) |
| | `workflow_dispatch` | |
| `_build.yml`, `_deploy.yml` | `workflow_call` (csak más workflow hívja) | |
| `destroy.yml` | csak `workflow_dispatch` + `destroy` megerősítés | |

A push `paths` szűrői azért tartalmazzák a workflow fájlokat is, hogy egy workflow módosítása rögtön ki is próbálódjon a main-en.

### A build folyamat, a tagelés és a push

`_build.yml`, mátrix a két szolgáltatásra (`service-a`, `service-b`, párhuzamosan):

1. **PR-on (`check` job):** checkout → `docker/setup-buildx-action` → `docker/build-push-action` `push: false`-szal. Csak azt ellenőrzi, hogy a Dockerfile felépül. Nincs AWS, nincs environment, a jog csak `contents: read`.
2. **main-en (`push` job, `production` environment):**
   - `configure-aws-credentials` (OIDC, app role) → `amazon-ecr-login` (docker login, a kimenete a registry címe);
   - **tag-ellenőrzés:** `aws ecr describe-images`. Ha a tag már megvan, a build kimarad. A repó `IMMUTABLE`, egy második push hibát adna. Ez újrafuttatásnál fordul elő, vagy ha a `terraform-apply.yml` ugyanazt a commitot buildeli;
   - **build és push:** `platforms: linux/amd64` (a node-ok x86-osak), a tag `<registry>/<cluster>/<svc>:<github.sha>`, a cache `type=gha`, szolgáltatásonként külön `scope`.

**A tag a teljes commit SHA:** egyértelműen visszavezethető a kódra (`git show <tag>`), soha nem ismétlődik, és együtt jár az `IMMUTABLE` repóval. A `latest`-tel ellentétben a Deploymentben is látszik, pontosan mi fut, és a rollback egy korábbi SHA-ra egyszerű.

### A Terraform folyamat és a state

1. **PR:** `terraform-plan.yml`, ezen belül:
   - `fmt -check -recursive`;
   - `init -backend-config="bucket=${{ vars.TF_STATE_BUCKET }}" -lockfile=readonly`;
   - `validate`;
   - `plan -var-file=production.tfvars -out=tfplan`;
   - `show` → PR komment (egy marker alapján frissül, nem halmozódik) és job summary.
2. **Merge:** `terraform-apply.yml`. Az `apply -auto-approve` a `production` environmenttel fut, `concurrency: terraform-production` mellett. Az auto-approve azért elfogadható, mert a plan-t a PR-ban átnéztük.
3. **A state:** S3 bucket (`tfstate-<account>-<régió>-eks-nginx-proxy-pipeline`), a kulcs `production/terraform.tfstate`. A bucketen versioning, SSE titkosítás, public access block és `prevent_destroy` van. A zárolás `use_lockfile = true`-val egy `.tflock` fájl ugyanabban a bucketben, DynamoDB tábla nélkül. A backend **partial configuration**: a bucket neve account-specifikus, ezért nincs a kódban, az `init` kapja.
4. **Változók:** a nem érzékeny értékek a commitolt `terraform/production.tfvars`-ban vannak, az account-specifikusak (`region`, `cluster_name`, ARN listák) `TF_VAR_*` környezeti változóként a GitHub Variables-ből jönnek.

A bootstrap (a bucket és a role-ok) külön Terraform root **helyi state-tel**, mert a saját state-je nem lehet abban a bucketben, amelyet létrehoz.

### Az OIDC működése és a beállítása

1. A job `permissions: id-token: write` mellett kérhet egy **OIDC tokent** (JWT) a GitHubtól. A token claimjei többek között: `iss: https://token.actions.githubusercontent.com`, `aud: sts.amazonaws.com` és a `sub`, amely leírja, honnan jön a kérés.
2. A `configure-aws-credentials` ezzel a tokennel hívja meg az `sts:AssumeRoleWithWebIdentity`-t.
3. Az AWS ellenőrzi a token aláírását a fiókban regisztrált **IAM OIDC provider** alapján, majd a role **trust policyja** szerint az `aud` és a `sub` feltételt.
4. Ha minden egyezik, az STS **rövid életű** (itt 1 órás) kulcsokat ad. Tárolt access key nincs.

**A beállítás (bootstrap):**
- Az OIDC provider már létezett a megosztott accountban, ezért csak `data` forrással hivatkozunk rá. Soha nem hozzuk létre és nem töröljük.
- Három role: `gha-eks-nginx-proxy-pipeline-terraform-plan`, `-terraform-apply` és `-app`. Trust: `Federated` = az OIDC provider, `StringEquals` az `aud = sts.amazonaws.com`-ra és a `sub`-ra.
- **A `sub` értékek:**
  - plan: `repo:SziNo/eks-nginx-proxy-pipeline:pull_request` (és a kézi planhez `...:ref:refs/heads/main`);
  - apply és app: `repo:SziNo/eks-nginx-proxy-pipeline:environment:production`.
- **Environment sub:** ha a job `environment:`-et használ, a `sub` **nem** `ref:refs/heads/main`, hanem `environment:production`. Azt, hogy ezt csak a main ág használhatja, az environment **deployment branch policyja** biztosítja (a bootstrapben: csak `main`). A két dolog együtt adja a védelmet.

**A jogok:**
- **plan:** `ReadOnlyAccess` + a `.tflock` írása. Az EKS-ben `AmazonEKSAdminViewPolicy`, csak a `kube-system`-re: a Helm release Secretjeit olvassa.
- **apply:** `PowerUserAccess` + saját IAM policy, a cluster név előtagra szűkítve.
- **app:** ECR push a két repóba, `eks:DescribeCluster`, `ec2:DescribeSecurityGroups`, és cluster admin access entry.

### A repó szerkezete és miért

- **`bootstrap/` külön:** más az életciklusa (egyszer fut, helyben, helyi state-tel), és ez adja a CI jogait. Ha a CI kezelné, a saját jogait is módosíthatná.
- **`terraform/` saját modulokkal:** az infrastruktúra, egy state. A `production.tfvars` a nem érzékeny konfiguráció.
- **`src/`:** csak az alkalmazás kódja. Ezért elég a `paths: src/**` a build triggerhez.
- **`k8s/base` + `k8s/overlays/production`:** a Kustomize szabványos szerkezete. A base környezetfüggetlen, az overlay a környezeti különbség. A környezetfüggő értékek (ECR cím, SG ID) a publikus repó miatt nincsenek commitolva, a CI `kustomize edit`-tel írja be őket.
- **`.github/workflows/`:** a fő workflow-k és az `_` előtagú, újrahasznosítható (`workflow_call`) részek.
- **`scripts/`:** a helyi megfelelők, ugyanazzal a logikával.

### Függ-e a Terraform az image buildtől?

**A Terraform nem függ az image-től:** az ECR repót létrehozza, de az image tartalmára nincs szüksége. **Fordítva viszont van függés:** a pushhoz kell az ECR repó, a deployhoz a cluster, az LB Controller és az NLB security group. Ezért mindig a Terraform az első.

**A megoldás:**
- A `terraform-apply.yml` az apply **után** (`needs`) maga hívja meg a `_build.yml`-t és a `_deploy.yml`-t a jelenlegi commit SHA-val. Így egy friss infrastruktúrán is mindig lesz alkalmazás.
- A `build-and-push.yml` csak `src/` vagy `k8s/` változásnál fut. Ilyenkor az infrastruktúra már áll.

### Mi történik, ha egy pushban a src és a terraform is változik?

Mindkét workflow elindul (mindkettő `paths` szűrője illeszkedik):

- **`build-and-push.yml`:** a `changes` jobja `git diff github.event.before github.sha -- terraform/ ...` alapján látja, hogy a `terraform-apply.yml` is fut. Ezért **nem buildel és nem deployol**, és a log megmondja, miért.
- **`terraform-apply.yml`:** apply → build (az új `src/`-ből, a commit SHA taggel) → deploy.

**Így:**
- a deploy az új infrastruktúrára megy;
- nincs versenyhelyzet az `IMMUTABLE` tagre (két workflow nem pusholja ugyanazt);
- friss infrastruktúránál nem próbál pusholni egy még nem létező ECR repóba.

Ugyanez érvényes, ha csak a `_build.yml` vagy a `_deploy.yml` változik, mert ezek mindkét workflow `paths`-ában benne vannak.

### Hogyan biztosítjuk a sorrendet?

- **`needs`:** egy workflow-n belül a jobok sorrendje.
  - `terraform-apply.yml`: `apply` → `build` → `deploy`;
  - `build-and-push.yml`: `changes` → `build` → `deploy`.

  Ha egy job elbukik, a tőle függők nem futnak (nincs deploy egy elbukott build után).
- **`workflow_call`:** a build és a deploy egy helyen van megírva, és két workflow hívja ugyanazokkal az inputokkal. Ezért a két út nem térhet el.
- **`concurrency`:**
  - `terraform-production`: apply és destroy, soha nem egyszerre. A `cancel-in-progress: false` miatt nem szakít meg egy futó applyt, mert az félkész infrastruktúrát és zárolt state-et hagyna;
  - `deploy-production`: egyszerre egy deploy;
  - a PR-os workflow-knál `cancel-in-progress: true`: egy új commit megszakítja a régi PR futást.

  Egy csoportban egyszerre csak egy futó és egy várakozó lehet: ha egy harmadik érkezik, a várakozó törlődik, és a legújabb marad. Deploynál ez pont jó, mert a legfrissebb commit a lényeg.
- **A git diff kapu** a két párhuzamos push workflow között (lásd az előző pontot).
- **Az S3 state lock** (`use_lockfile`) a Terraform szintjén is véd, a `-lock-timeout` miatt a második futás megvárja az elsőt.

### Mit változtatnék?

- **Szűkebb deploy jog:** a `demo` namespace-t a Terraform hozná létre, és az app role csak namespace scope-ú `AmazonEKSEditPolicy`-t kapna cluster admin helyett.
- **Permissions boundary** az apply role által létrehozott IAM role-okra: az előtag és a csatolható policyk listája most is szűkít, de egy saját `<cluster>-*` policyba elvileg bármi írható.
- **Plan artifact:** a PR-ban jóváhagyott plan fájlt (`tfplan`) alkalmaznám a main-en, nem egy új plant. Ehhez a plan a merge commiton kellene, hogy készüljön (pl. merge queue).
- **Több környezet** (`staging` → `production`), ugyanazzal az image-dzsel (promotion), environment jóváhagyással a production előtt.
- **Image szkennelés** kötelező kapuként (az ECR `scan_on_push` most is fut, de nem állítja meg a deployt), SBOM és aláírás (cosign).
- **GitOps (Argo CD / Flux):** a cluster húzza le a manifesteket, a CI-nak nem kell cluster hozzáférés.
- **Privát EKS endpoint** self-hosted runnerrel vagy egy VPC-n belüli runnerrel.
- **Tesztek** a buildben (pytest, hadolint, `kubeconform` a manifestekre, `tflint`/`checkov` a Terraformra).

### A felmerült hibák és megoldásuk

> **TODO – a valódi futások után kitöltendő.** A tervezett formátum: mi történt (a hibaüzenet), mi volt az oka, mi lett a megoldás és a tanulság.

| # | Mi történt | Ok | Megoldás, tanulság |
| --- | --- | --- | --- |
| 1 | *(a tervezés közben)* A `workflow_dispatch`-csel indított plan nem tudta volna felvenni a plan role-t | A `sub` ilyenkor `ref:refs/heads/main`, nem `pull_request` | A plan role trust policyja mindkét `sub`-ot elfogadja (csak olvasási jog) |
| 2 | *(a tervezés közben)* Kötelező status check + `paths` szűrő a PR-on: a PR örökre „Expected” állapotban maradt volna | Ha a workflow el sem indul, a checkje meg sem jelenik | `paths` nélküli PR trigger, `git diff` alapú `changes` job, stabil nevű gyűjtő job (`plan-status`, `build-status`) |
| … | | | |
````

**Ellenőrzés:**

<!-- sbs:check 3.41 -->
```bash
head -1 docs/notes.md
```

Várt kimenet:

```text
# 1on1 felkészítő
```

### 3.42 docs/step-by-step.md

Ez a fájl maga: másold ide változtatás nélkül (önmagát nem tudja kódblokkban tartalmazni).

<!-- sbs:self -->
Hozd létre a `docs/step-by-step.md` fájlt ennek a fájlnak a tartalmával.

**Ellenőrzés:**

<!-- sbs:check 3.42 -->
```bash
head -2 docs/step-by-step.md
```

Várt kimenet:

```text
# Lépésről lépésre
```

### 3.43 Teljes ellenőrzés

A 3. lépés végén minden ellenőrzés egyben: formázás és validate mindkét rootban, actionlint az összes workflow-ra, bash -n és shellcheck a scriptekre, a production overlay egy ideiglenes másolaton példa taggel és SG patch-csel (a CI parancsaival), a régi `apps/` útvonal maradványai, és a változott fájlok listája.

**Ellenőrzés:**

<!-- sbs:check 3.43 -->
```bash
terraform -chdir=bootstrap fmt -check -recursive && echo "fmt OK"
terraform -chdir=terraform fmt -check -recursive && echo "fmt OK"
terraform -chdir=bootstrap init -backend=false -input=false -lockfile=readonly > /dev/null \
  && terraform -chdir=bootstrap validate -no-color
terraform -chdir=terraform init -backend=false -input=false -lockfile=readonly > /dev/null \
  && terraform -chdir=terraform validate -no-color
docker run --rm -v "$PWD:/repo" -w /repo rhysd/actionlint:1.7.12 -no-color && echo "actionlint OK"
for f in scripts/*.sh; do bash -n "$f"; done && echo "bash -n OK"
docker run --rm -v "$PWD:/mnt" -w /mnt koalaman/shellcheck:stable -x scripts/*.sh && echo "shellcheck OK"
tmp=$(mktemp -d) && cp -r k8s "$tmp/"
(
  source scripts/common.sh   # kustomize: a bináris, vagy ha nincs, a docker image
  cd "$tmp/k8s/overlays/production"
  kustomize edit set image \
    service-a=123456789012.dkr.ecr.eu-west-1.amazonaws.com/demo/service-a:abc123 \
    service-b=123456789012.dkr.ecr.eu-west-1.amazonaws.com/demo/service-b:abc123
  kustomize edit add patch --kind Service --name nginx-proxy \
    --patch '[{"op":"add","path":"/metadata/annotations/service.beta.kubernetes.io~1aws-load-balancer-security-groups","value":"sg-0123456789abcdef0"}]'
)
kubectl kustomize "$tmp/k8s/overlays/production" | grep -E "image:|security-groups"
rm -rf "$tmp"
grep -rn "apps/" --exclude-dir=.git --exclude-dir=.terraform --exclude=step-by-step.md .
git status --short
```

Várt kimenet:

```text
fmt OK
fmt OK
Success! The configuration is valid.

Success! The configuration is valid.

actionlint OK
bash -n OK
shellcheck OK
    service.beta.kubernetes.io/aws-load-balancer-security-groups: sg-0123456789abcdef0
      - image: 123456789012.dkr.ecr.eu-west-1.amazonaws.com/demo/service-a:abc123
      - image: 123456789012.dkr.ecr.eu-west-1.amazonaws.com/demo/service-b:abc123
      - image: nginxinc/nginx-unprivileged:1.27-alpine
./k8s/base/service-b.yaml:1:apiVersion: apps/v1
./k8s/base/nginx-daemonset.yaml:1:apiVersion: apps/v1
./k8s/base/service-a.yaml:1:apiVersion: apps/v1
 M .gitignore
 M README.md
 M docs/notes.md
 M k8s/base/service-a.yaml
 M k8s/base/service-b.yaml
 M scripts/build-push.sh
 M scripts/render.sh
 M scripts/teardown.sh
D  terraform/data.tf
 M terraform/locals.tf
 M terraform/main.tf
 M terraform/modules/ecr/main.tf
 M terraform/modules/eks/access.tf
 M terraform/modules/eks/outputs.tf
 M terraform/modules/eks/security-groups.tf
 M terraform/modules/eks/variables.tf
 M terraform/outputs.tf
 M terraform/terraform.tfvars.example
 M terraform/variables.tf
 M terraform/versions.tf
?? .github/
?? bootstrap/
?? docs/step-by-step.md
?? k8s/overlays/
?? scripts/common.sh
?? terraform/production.tfvars
```

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

## 7. 🖐 KÉZI LÉPÉS: commit, push és az első PR

A munkaág (`feature/pipeline`) a 3.1-ben készült, minden változás ezen van.

```bash
git branch --show-current    # feature/pipeline
git add -A
git status --short           # nincs benne: bootstrap/terraform.tfvars, *.tfstate, terraform/terraform.tfvars
git commit -m "GitHub Actions pipeline: bootstrap, workflow-k, remote state, dokumentáció"
git push -u origin feature/pipeline
```

**A commit és a push a bootstrap ELŐTT is biztonságos**, ha nem a main-re megy: a workflow-k csak a main-re érkező pushra (`push: branches: [main]`), a main-re nyitott PR-ra (`pull_request: branches: [main]`) és kézi indításra (`workflow_dispatch`) futnak. Egy push a `feature/pipeline` ágra egyiket sem indítja el, ezért ez a 3. lépés után bármikor megtehető, akár a 4–5. lépés előtt is.

**A PR-t viszont csak a bootstrap (5. lépés) UTÁN szabad megnyitni.** A PR elindítja a `terraform-plan` és a `build-and-push` workflow-t. A bootstrap előtt még nincsenek meg a Variables (pl. a `vars.TF_PLAN_ROLE_ARN` üres) és az IAM role-ok, ezért a plan elbukna, és a branch protection sem létezne még, vagyis a PR ellenőrzés nélkül is mergelhető lenne. Ha mégis korábban nyitottad meg, a bootstrap után egy üres commit újraindítja a checkeket: `git commit --allow-empty -m "rerun checks" && git push`.

GitHubon: **Compare & pull request** → base: `main` ← compare: `feature/pipeline` → **Create pull request**.

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

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

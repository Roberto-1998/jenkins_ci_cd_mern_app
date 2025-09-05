# Jenkins Branch — CI/CD Pipeline for MERN + Kubernetes

This branch (`jenkins`) contains a production‑grade **Jenkins Pipeline** that builds, tests, packages (Docker), and deploys (Helm) a MERN application to Kubernetes. The goal of this README is to make the pipeline’s logic crystal‑clear so that you can learn, maintain, and extend it confidently.

> GitHub Branch: [`jenkins`](https://github.com/Roberto-1998/jenkins_ci_cd_mern_app/tree/jenkins)  
> App Source: `mern_blog_app/` (backend in `server/`, frontend in `client/`)  
> Helm Chart: `deploy/helm/mern`

---

## Prerequisites (Jenkins Controller/Agent)

- **Tools on the Jenkins agent** (where the pipeline runs):
  - Docker Engine & access to the Docker socket
  - Node.js **tool** configured in Jenkins as `NODE18` (Manage Jenkins → Global Tool Configuration → NodeJS)
  - `kubectl` and `helm` installed and on `PATH`
  - Git client
- **Credentials (Jenkins → Manage Credentials):**
  - `dockerhublogin` → *Username with password* (for `docker.withRegistry`)
  - `kubeconfig-jenkins` → *Kubeconfig file credential* (used by `withKubeConfig` to talk to the cluster)
- **Minimal plugins** (names may vary by distribution/version):
  - *Pipeline* (Workflow) & *Git* plugin
  - *NodeJS* plugin (to use the `tools { nodejs 'NODE18' }` directive)
  - *Docker Pipeline* plugin (for `docker.build`, `docker.withRegistry`)
  - *Kubernetes CLI* plugin (for `withKubeConfig`)
  - *JUnit* plugin (for the `junit` step)
  - *AnsiColor* and *Timestamper* plugins
  - *Workspace Cleanup* plugin (for `cleanWs`)
  - *(Optional)* Checks API (we suppress it with `skipPublishingChecks`)

---

## High‑Level Flow

```
             ┌──────────────┐
             │   Checkout   │  → get repo @ main
             └──────┬───────┘
                    │
             ┌──────▼────────────┐
             │   Set Build Vars  │  → COMMIT, TS, BRANCH, TAG
             └──────┬────────────┘
                    │
       ┌────────────▼─────────────┐
       │   CI in Parallel         │
       │  ┌──────────┐ ┌────────┐ │
       │  │ Backend  │ │Frontend│ │
       │  │ test/lint│ │test/lint│ │
       │  │ docker   │ │docker   │ │
       │  └──────────┘ └────────┘ │
       └────────────┬─────────────┘
                    │
             ┌──────▼────────────┐
             │  Smoke k8s Access │  → kubectl context, RBAC check, nodes
             └──────┬────────────┘
                    │
             ┌──────▼────────────┐
             │   Helm Upgrade    │  → atomic, wait, rollback on failure
             └──────┬────────────┘
                    │
             ┌──────▼────────────┐
             │ Post‑Deploy Checks│  → rollouts, services, ingress, smoke tests
             └────────┬──────────┘
                      │
                ┌─────▼─────┐
                │  Cleanup  │  → cleanWs
                └───────────┘
```

---

## Pipeline Options & Environment

```groovy
tools { nodejs 'NODE18' }  // Node tool managed by Jenkins
options {
  timestamps()                 // Prefix log lines with time
  ansiColor('xterm')           // Colorized logs
  disableConcurrentBuilds()    // Prevent overlapping builds
  timeout(time: 30, unit: 'MINUTES')
  buildDiscarder(logRotator(numToKeepStr: '30', artifactNumToKeepStr: '15'))
  parallelsAlwaysFailFast()    // Fail other parallel branches early when one fails
}
environment {
  IMAGE_PREFIX = 'masterdevopscloud'    // DockerHub namespace
  DOCKERHUB_CREDENTIALS = 'dockerhublogin'
  DOCKER_BUILDKIT = '1'                 // Enable faster Docker builds
  CI = 'true'                           // Non-interactive CI mode for Node tooling
}
```

**Why these choices?**
- **Timestamps/ANSI** improve observability.
- **disableConcurrentBuilds** avoids racing deployments.
- **Timeout** caps stuck builds to 30 minutes.
- **buildDiscarder** keeps logs tidy (last 30 builds / 15 artifacts).
- **parallelsAlwaysFailFast** saves time when one branch breaks.
- **DOCKER_BUILDKIT=1** activates BuildKit and inline caching for speed.

---

## Stage‑by‑Stage Walkthrough

### 1) `Checkout`
```groovy
git branch: 'main', url:'https://github.com/Roberto-1998/jenkins_ci_cd_mern_app.git'
```
- We build from `main` to ensure we deploy only merged, green code.

### 2) `Set Build Vars`
```groovy
env.COMMIT = sh(... 'git rev-parse --short HEAD')
env.TS     = (env.BUILD_TIMESTAMP ?: sh('date -u +%Y%m%d%H%M%S'))
env.BRANCH = (env.BRANCH_NAME ?: 'main').toLowerCase().replaceAll(/[^a-z0-9_.-]/, '-')
env.TAG    = "${env.BRANCH}-${env.COMMIT}-${env.TS}"
```
- **COMMIT**: short SHA for traceability.
- **TS**: UTC timestamp to make tags unique.
- **BRANCH**: sanitized for Docker tags and Helm labels.
- **TAG**: the immutable image tag used for both backend and frontend.

### 3) `CI - Backend & Frontend in Parallel`
Two nested stage groups run **in parallel** to maximize throughput.

#### Backend → `Install & Test`
```groovy
npm ci || npm install || yarn install
npm run lint
JEST_JUNIT_OUTPUT=./junit.xml npm test -- --watchAll=false --reporters=default --reporters=jest-junit --coverage || echo "No backend tests yet"
```
- Installs dependencies (prefers `npm ci`).
- Lints code.
- Runs **Jest** tests and exports **JUnit XML** → consumed by the `junit` step.
- We **allow empty** & **do not mark UNSTABLE** to keep CD flowing while tests evolve:
  ```groovy
  junit(testResults: '.../junit.xml', allowEmptyResults: true, skipPublishingChecks: true, skipMarkingBuildUnstable: true)
  ```
- Coverage is archived as build artifacts.

#### Backend → `Docker Build & Push`
```groovy
docker pull ${imageName}:${BRANCH} || true   // warm cache for inline cache
def img = docker.build("${imageName}:${TAG}",
  "--build-arg BUILDKIT_INLINE_CACHE=1 --cache-from=${imageName}:${BRANCH} -f Dockerfile ."
)
docker.withRegistry('https://index.docker.io/v1/', env.DOCKERHUB_CREDENTIALS) {
  img.push(TAG)      // immutable tag
  img.push(BRANCH)   // moving tag (branch channel)
  if (env.BRANCH_NAME == 'main') { img.push('latest') } // convenience tag
}
```
- **Inline cache + cache‑from**: speeds up rebuilds dramatically.
- Pushes **three** tags (immutable `TAG`, floating `BRANCH`, and `latest` for `main`).
- Cleans up local images with `docker image prune -f`.

> The **Frontend** branch mirrors the same pattern: install/lint/test/build, then Docker build & push to `${IMAGE_PREFIX}/mern-frontend` using the same caching strategy. Its static build output is archived as artifacts for traceability.

### 4) `CD - Smoke Kube Access`
```groovy
withKubeConfig(credentialsId: 'kubeconfig-jenkins') {
  kubectl config current-context
  kubectl auth can-i get pods || (echo "RBAC check failed"; exit 1)
  kubectl get nodes
}
```
- Proves the **cluster is reachable** with the provided kubeconfig.
- **RBAC check** catches permission regressions before deployment.

### 5) `CD - Helm Upgrade`
```groovy
helm upgrade --install mern deploy/helm/mern -n default   --set backend_app.image.name=docker.io/${IMAGE_PREFIX}/mern-backend   --set backend_app.image.tag=${TAG}   --set frontend_app.image.name=docker.io/${IMAGE_PREFIX}/mern-frontend   --set frontend_app.image.tag=${TAG}   --set backend_app.resources.requests.cpu=50m   --set backend_app.resources.requests.memory=128Mi   --set frontend_app.resources.requests.cpu=50m   --set frontend_app.resources.requests.memory=64Mi   --set db_app.resources.requests.cpu=100m   --set db_app.resources.requests.memory=256Mi   --wait --atomic --cleanup-on-fail --history-max 10 --timeout 5m
```
**Key flags explained:**
- `upgrade --install` → creates or updates the release.
- `--wait` → blocks until all resources are ready.
- `--atomic` → auto‑rollback if the upgrade fails.
- `--cleanup-on-fail` → removes partial resources on failure.
- `--history-max 10` → trims history to last 10 revisions.
- `--timeout 5m` → cap rollout wait time.

**Extra safety net on failure:** we compute the **last deployed** revision using `helm history` (with `jq` if available, otherwise `awk`) and **explicitly rollback** to it. This complements `--atomic` and covers edge cases.

### 6) `Post-Deploy Checks`
```groovy
kubectl rollout status deploy/backend-deployment  --timeout=180s
kubectl rollout status deploy/frontend-deployment --timeout=180s
kubectl get svc -n default
kubectl get endpoints -n default
kubectl get ingress mern-app-ingress -n default -o wide || kubectl get ingress -n default -o wide

# DNS wait (best-effort)
for i in 1 2 3 4 5 6; do nslookup mernapp.rcginfo.xyz && break || sleep 10; done || true

# HTTP smoke test (best-effort, non-fatal)
curl -f --max-time 15 http://mernapp.rcginfo.xyz/ || curl -I --max-time 15 http://mernapp.rcginfo.xyz/ || true
curl -sf --max-time 15 http://mernapp.rcginfo.xyz/api/health || true
```
- Verifies **rollouts** for backend/frontend.
- Lists **Services/Endpoints** and **Ingress** for quick triage.
- Performs **best‑effort** DNS wait and HTTP **smoke tests** (non‑fatal to avoid flakiness).
- Always exports helpful artifacts for debugging:
  ```bash
  helm status mern
  kubectl get pods -o wide
  kubectl get events --sort-by=.lastTimestamp | tail -n 50
  helm get manifest mern > helm_manifest.yaml
  helm get values   mern > helm_values.yaml
  ```
  These files are **archived** to the build.

### 7) `post { always { cleanWs(...) } }`
- Cleans the Jenkins workspace folders after each build to avoid cross‑build contamination.

---

## What Is Being Tested?

Both **backend** and **frontend** run:
- **Linting** (code quality gates).
- **Unit tests** via **Jest**, publishing **JUnit** for Jenkins.
- The frontend also runs a **production build** to catch build‑time regressions.  
Even if tests are **missing/failing**, the pipeline does **not** mark the build unstable (configurable), allowing you to evolve test coverage without blocking deployments.

---

## Docker Strategy

- **BuildKit** + `BUILDKIT_INLINE_CACHE=1` and `--cache-from=${image}:${BRANCH}` to accelerate incremental builds.
- Push **immutable** tags (for traceability) and **moving** tags (`branch`, `latest`) for convenience.
- **Registry auth** handled via `docker.withRegistry` + `dockerhublogin` credentials.
- **Prune** images after each build to save disk space on the agent.

---

## Helm & Kubernetes Strategy

- Single chart at `deploy/helm/mern` controls **frontend**, **backend**, and **MongoDB**.
- Image coordinates are injected via `--set` to pin the exact Docker **TAG** built in CI.
- Resource **requests** are set to improve scheduling predictability.
- `--atomic` and the **manual rollback** safeguard ensure safe deployments.
- Post‑deploy checks validate rollouts, service wiring, ingress exposure, and app health (`/api/health`).

---

## Observability & Artifacts

- **JUnit** results per component (even if empty) → trending over time.
- **Coverage** folders archived for both components.
- **Helm manifests/values** captured for each deployment → audits and rollbacks are easier.
- Colorized, timestamped logs for readability.

---

## Security & Secrets

- Never hardcode credentials in the `Jenkinsfile`.
- Use Jenkins **Credentials**:
  - DockerHub: `dockerhublogin`
  - Kubernetes: `kubeconfig-jenkins` (file credential)
- Lock down Docker on agents and least‑privilege RBAC for the Kubernetes service account behind the kubeconfig.

---

## Troubleshooting

- **RBAC check fails**: validate the kubeconfig user/SA permissions (`kubectl auth can-i ...`).
- **Helm upgrade timeout**: inspect `kubectl describe` on pods, and check events; see archived `helm_manifest.yaml` and `helm_values.yaml`.
- **Images not pulled**: confirm pushed tags exist on DockerHub and that the cluster nodes can reach DockerHub.
- **DNS/Ingress issues**: ensure the Ingress Controller is healthy and DNS has propagated; use the ALB/NLB address to test traffic path.
- **Cache not used**: make sure the `${BRANCH}` tag exists so `--cache-from` has something to pull.

---

## Extending the Pipeline

- Add **E2E tests** (e.g., Cypress) after `Helm Upgrade` before marking success.
- Promote images between environments by retagging immutable `TAG` into `staging`/`prod` channels.
- Add Slack/MS Teams notifications in `post` blocks.
- Parameterize **environment** (`dev`, `prod`) and pass env‑specific value files to Helm.

---

**This pipeline demonstrates a complete CI/CD feedback loop** for a MERN application on Kubernetes, emphasizing speed (parallelism, caching), safety (atomic upgrades, rollbacks), and observability (tests, artifacts, logs).
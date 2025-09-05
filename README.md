# Helm Chart for MERN App Deployment

This branch (`helm`) contains a complete Helm chart for deploying a full-stack MERN (MongoDB, Express, React, Node.js) application on a Kubernetes cluster.

> GitHub Branch: [`helm`](https://github.com/Roberto-1998/jenkins_ci_cd_mern_app/tree/helm)

---

## 🚀 Why Helm?

**Helm** is the package manager for Kubernetes. It allows us to define, install, and upgrade complex Kubernetes applications using reusable, versioned charts.

### Benefits of using Helm

✅ **Templating**: DRY and reusable manifests with dynamic values  
✅ **Separation of config and logic**: Through `values.yaml`  
✅ **Version control**: Easily upgrade or rollback releases  
✅ **Reproducibility**: Install the same stack in different environments  
✅ **Standardization**: Share charts across teams or projects

Without Helm, you’d have to manage long, static YAML manifests manually. Helm provides **automation**, **consistency**, and **maintainability**.

---

## 📁 Chart Structure

```
deploy/helm/mern/
├── Chart.yaml                # Chart metadata (name, version, etc.)
├── values.yaml              # Default configuration values (dev/local)
├── values.prod.yaml         # Production-specific overrides
├── templates/               # Kubernetes manifest templates
│   ├── backend-deployment.yaml
│   ├── backend-service.yaml
│   ├── frontend-deployment.yaml
│   ├── frontend-service.yaml
│   ├── frontend-ingress.yaml
│   ├── db-statefulset.yaml
│   ├── db-headless-service.yaml
│   ├── db-secret.yaml
│   └── NOTES.txt
└── charts/                  # For chart dependencies (empty here)
```

---

## 🧱 Components Deployed

This Helm chart deploys the following:

- **MongoDB**
  - `StatefulSet`: ensures pod identity and persistent storage
  - `Secret`: stores DB credentials
  - `Headless Service`: enables DNS-based stable discovery
- **Backend App** (`Express`)
  - `Deployment`: manages stateless replicas
  - `Service`: ClusterIP for internal communication
- **Frontend App** (`React`)
  - `Deployment`: React static files served via container
  - `Service`: ClusterIP
  - `Ingress`: Exposes frontend over HTTP using NGINX

All of these are dynamically configured using Helm templates and values.

---

## ⚙️ Configuration with `values.yaml`

Helm uses the `values.yaml` file to inject configuration into templates. We maintain two versions:

- `values.yaml`: for **development/local testing**
- `values.prod.yaml`: for **production deployments**

Examples of what you configure:

```yaml
replicaCount: 1

backend_app:
  image:
    repository: your-dockerhub-user/backend
    tag: latest

frontend_app:
  image:
    repository: your-dockerhub-user/frontend
    tag: latest

db_app:
  username: admin
  password: securepassword
```

This design allows you to use the **same chart** in different environments by simply swapping the values file:

```bash
# Deploy with dev config
helm install mern ./mern

# Deploy with prod config
helm install mern ./mern -f values.prod.yaml
```

---

## 📦 Chart.yaml

```yaml
apiVersion: v2
name: mern
description: A Helm chart to deploy a MERN stack application
type: application
version: 0.1.0
appVersion: 1.0.0
```

This file is the chart’s metadata. It declares this as an **application** (not a library chart), with semantic versions for Helm tracking.

---

## 📝 NOTES.txt

This file gives post-install instructions such as:

- Access URLs
- How to check service status
- Reminder to configure DNS if using an Ingress

It’s automatically printed by Helm after install/upgrade.

---

## 🚀 Installing the Chart

```bash
cd deploy/helm

# Dry-run
helm install mern ./mern --dry-run

# Actual deployment (default values)
helm install mern ./mern

# Using production values
helm install mern ./mern -f mern/values.prod.yaml
```

To upgrade:

```bash
helm upgrade mern ./mern -f mern/values.prod.yaml
```

To uninstall:

```bash
helm uninstall mern
```

---

## 📚 Summary

| Feature        | Without Helm                         | With Helm                           |
|----------------|--------------------------------------|--------------------------------------|
| Deployment     | Manual, repetitive YAML              | Templated, reusable manifests        |
| Configuration  | Hardcoded in each manifest           | Centralized in `values.yaml`        |
| Environments   | Requires separate manifest copies    | Same chart, different values         |
| Versioning     | Manual tracking                      | Built-in rollback and history        |
| Maintenance    | Error-prone                          | Scalable and maintainable            |

Using Helm was a major improvement for deploying this project into Kubernetes clusters. It brought **clarity**, **automation**, and **production readiness**.


# Infrastructure Automation — Terraform & Ansible

This branch (`infra`) documents the **infrastructure layer** of the project. It is built using two main tools:

- **Terraform**: To declaratively provision the infrastructure on AWS using a modular architecture.
- **Ansible**: To configure the provisioned EC2 instances (Jenkins host and Kubernetes admin host) and to manage the lifecycle of the Kubernetes cluster via `kOps`.

---

## 🏗️ Terraform — Infrastructure as Code (IaC)

In this project, **Terraform** is responsible for provisioning all the necessary AWS infrastructure using a **modular architecture** that promotes reusability, clarity, and scalability.

### What we provision with Terraform

We divided the infrastructure into two scopes:

1. **kops_admin** (`terraform/kops_admin`)
   - EC2 instance that will act as the Kubernetes cluster admin.
   - S3 bucket to store `kOps` state (cluster definitions and artifacts).
   - Route53 Hosted Zone or records for the cluster domain.
   - SSH key pair for secure access.
   - Security groups for admin access.
   
2. **ci_cd** (`terraform/ci_cd`)
   - EC2 instance to run **Jenkins**.
   - SSH key pair for Jenkins server.
   - Security groups allowing SSH and HTTP access.

### Benefits of Modular Architecture

We used a module-based approach (`modules/`) for:

- `ec2`: provisioning instances with tags, volumes, and appropriate AMIs.
- `keypair`: to create or use existing SSH keys.
- `secgroup`: reusable and parameterized security groups.
- `route53`: dynamic record creation.
- `s3`: versioned S3 buckets with lifecycle policies.

This modular approach allowed us to:

✅ Separate concerns clearly.  
✅ Reuse logic across environments (e.g., dev/prod).  
✅ Isolate resources and simplify testing & troubleshooting.  
✅ Learn **best practices** of clean Terraform composition.

### Environment separation

Each Terraform folder supports **multiple environments** via:
- Workspaces (`dev`, `prod`) or
- Local `terraform.tfstate.d/` structure.

Variables are declared in `variables.tf` and passed through `terraform.tfvars` for better control.

### Summary of Terraform's role

- ✅ Automated creation of infrastructure.
- ✅ Clean separation between Jenkins and Kubernetes admin infrastructure.
- ✅ Powerful state management and versioning with S3 (for `kOps`).
- ✅ Security best practices using controlled SSH access.

---

## ⚙️ Ansible — Configuration Management

Once the infrastructure is provisioned, we use **Ansible** to configure both EC2 instances.

### Jenkins Host Setup (`ansible/ci_cd`)

Using the `ci_cd/playbook.yaml`, we:

- Install **Docker**, **Node.js**, and **Jenkins**.
- Add required Jenkins plugins and global tools.
- Manage user/group permissions for Docker.
- Ensure the system is ready to run our CI/CD pipelines.

The Ansible inventory (`hosts.ini`) includes the IP/DNS of the Jenkins EC2 (output from Terraform).

### Kubernetes Admin Host Setup (`ansible/kops_admin`)

Using the `site.yaml` playbook, we install:

- `kOps`, `kubectl`, and `awscli`.
- Any supporting packages needed to manage the cluster.

We then manage the Kubernetes cluster lifecycle with the following playbooks:

- `kops_cluster_create.yaml` → Creates the cluster using `kops`, based on the domain and S3 state bucket provisioned by Terraform.
- `kops_cluster_update.yaml` → Applies rolling updates to the cluster.
- `kops_cluster_delete.yaml` → Destroys the cluster completely.

These playbooks allow us to abstract the `kOps` CLI and create **idempotent**, trackable workflows.

### Why `kOps`?

- ✅ Supports deploying production-grade Kubernetes clusters on AWS.
- ✅ Fully integrates with Route53, S3, EC2, and SSH.
- ✅ Easily customizable via manifests or CLI arguments.
- ✅ Community-driven and widely adopted.

In our case, we used `kOps` to create a cluster accessible via a subdomain (e.g., `kubeapp.example.com`), using the state stored in the S3 bucket.

We also installed the **NGINX Ingress Controller**, using a compatible version with our Kubernetes release (e.g., controller v1.11.x for K8s 1.30+). This allows clean HTTP routing and future TLS termination.

---

## ✅ Summary

| Tool       | Purpose                                                   |
|------------|-----------------------------------------------------------|
| **Terraform** | Provision AWS infrastructure using modular, reusable IaC |
| **Ansible**   | Configure servers and manage Kubernetes via `kOps`       |
| **kOps**      | Bootstrap Kubernetes clusters with AWS-native integration |
| **Ingress**   | NGINX Controller for load-balanced HTTP routing          |

This branch is a full example of combining **Terraform + Ansible + kOps** to automate the provisioning and management of infrastructure for a CI/CD-ready Kubernetes environment.


# EKS Infrastructure with ArgoCD Deployment 🚀

This project automates the creation of an Amazon Elastic Kubernetes Service (EKS) cluster and the deployment of ArgoCD using Terraform. It provides a fully functional and configurable EKS environment, complete with networking, node groups, and essential Kubernetes addons. ArgoCD is configured to manage application deployments on the cluster, enabling GitOps-based continuous delivery. This setup solves the problem of manually provisioning and configuring EKS clusters and streamlines the deployment process with ArgoCD.

## 🚀 Key Features

- **Automated EKS Cluster Creation:** Deploys a fully functional EKS cluster with managed node groups.
- **ArgoCD Deployment:** Installs and configures ArgoCD for GitOps-based application deployments.
- **Networking Configuration:** Provisions a VPC with public, private, and intra subnets, along with a NAT gateway.
- **IAM Role for Service Accounts (IRSA):** Configures IAM roles for the EBS CSI driver, allowing it to dynamically provision EBS volumes.
- **Secrets Management:** Creates and manages secrets in AWS Secrets Manager, encrypted with the EKS cluster's KMS key.
- **Configurable Infrastructure:** Uses Terraform variables to customize the environment, region, VPC CIDR, and EKS settings.
- **Node Placement:** Configures node placement for Argo CD components using `nodeSelector` and `tolerations` to ensure they run on designated "system" nodes.

## 🛠️ Tech Stack

* **Infrastructure as Code:** Terraform  
* **Cloud Provider:** AWS  
* **Container Orchestration:** Kubernetes (EKS)  
* **Continuous Delivery:** ArgoCD  
* **Networking:** VPC, Subnets, NAT Gateway  
* **IAM:** AWS IAM, IRSA  
* **Secrets Management:** AWS Secrets Manager  
* **Modules:** `terraform-aws-modules/vpc/aws`, `terraform-aws-modules/eks/aws`, `terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc`  
* **Languages:** HCL (Terraform), YAML  
* **Other:** Helm

## 📦 Getting Started

Follow these steps to set up the infrastructure and deploy ArgoCD.

### Prerequisites

- [ ] Terraform installed (version >= 1.0)  
- [ ] AWS CLI installed and configured with appropriate credentials  
- [ ] kubectl installed  
- [ ] helm installed

### Installation

1. **Clone the repository:**

```bash
git clone https://github.com/alon-shviki/shviki-fitness-infra.git
cd shviki-fitness-infra
```

2. **Configure AWS Credentials:**

```bash
aws configure
```

3. **Define Variables:**

Create a `terraform.tfvars` file or use `tfvars/prod.tfvars` and customize the variables according to your needs. Populate `secrets.auto.tfvars` with:

- `mysql_root_password`
- `mysql_user`
- `mysql_user_password`
- `mysql_database`
- `flask_secret_key`
- `rapidapi_key`

**Important:** Ensure `secrets.auto.tfvars` is git-ignored.

4. **Initialize Terraform:**

```bash
terraform init
```

5. **Apply Terraform Configuration:**

```bash
terraform apply
```

Confirm with `yes` when prompted.

### Running Locally

1. **Configure `kubectl`:**

```bash
aws eks update-kubeconfig --name <cluster_name> --region <region>
```

2. **Verify the EKS Cluster:**

```bash
kubectl get nodes
```

3. **Access ArgoCD:**

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
kubectl port-forward svc/argo-cd-server -n argocd 8080:443
```

Open: `https://localhost:8080`  
Login: `admin` + retrieved password

## 📂 Project Structure

```
# EKS Infrastructure with ArgoCD Deployment 🚀

This project automates the creation of an Amazon Elastic Kubernetes Service (EKS) cluster and the deployment of ArgoCD using Terraform. It provides a fully functional and configurable EKS environment, complete with networking, node groups, and essential Kubernetes addons. ArgoCD is configured to manage application deployments on the cluster, enabling GitOps-based continuous delivery. This setup solves the problem of manually provisioning and configuring EKS clusters and streamlines the deployment process with ArgoCD.

## 🚀 Key Features

- **Automated EKS Cluster Creation:** Deploys a fully functional EKS cluster with managed node groups.
- **ArgoCD Deployment:** Installs and configures ArgoCD for GitOps-based application deployments.
- **Networking Configuration:** Provisions a VPC with public, private, and intra subnets, along with a NAT gateway.
- **IAM Role for Service Accounts (IRSA):** Configures IAM roles for the EBS CSI driver, allowing it to dynamically provision EBS volumes.
- **Secrets Management:** Creates and manages secrets in AWS Secrets Manager, encrypted with the EKS cluster's KMS key.
- **Configurable Infrastructure:** Uses Terraform variables to customize the environment, region, VPC CIDR, and EKS settings.
- **Node Placement:** Configures node placement for Argo CD components using `nodeSelector` and `tolerations` to ensure they run on designated "system" nodes.

## 🛠️ Tech Stack

* **Infrastructure as Code:** Terraform  
* **Cloud Provider:** AWS  
* **Container Orchestration:** Kubernetes (EKS)  
* **Continuous Delivery:** ArgoCD  
* **Networking:** VPC, Subnets, NAT Gateway  
* **IAM:** AWS IAM, IRSA  
* **Secrets Management:** AWS Secrets Manager  
* **Modules:** `terraform-aws-modules/vpc/aws`, `terraform-aws-modules/eks/aws`, `terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc`  
* **Languages:** HCL (Terraform), YAML  
* **Other:** Helm

## 📦 Getting Started

Follow these steps to set up the infrastructure and deploy ArgoCD.

### Prerequisites

- [ ] Terraform installed (version >= 1.0)  
- [ ] AWS CLI installed and configured with appropriate credentials  
- [ ] kubectl installed  
- [ ] helm installed

### Installation

1. **Clone the repository:**

```bash
git clone <https://github.com/alon-shviki/shviki-fitness-infra.git>
cd shviki-fitness-infra
```

2. **Configure AWS Credentials:**

```bash
aws configure
```

3. **Define Variables:**

Create a `terraform.tfvars` file or use `tfvars/prod.tfvars` and customize the variables according to your needs. Populate `secrets.auto.tfvars` with:

- `mysql_root_password`
- `mysql_user`
- `mysql_user_password`
- `mysql_database`
- `flask_secret_key`
- `rapidapi_key`

**Important:** Ensure `secrets.auto.tfvars` is git-ignored.

4. **Initialize Terraform:**

```bash
terraform init
```

5. **Apply Terraform Configuration:**

```bash
terraform apply
```

Confirm with `yes` when prompted.

### Running Locally

1. **Configure `kubectl`:**

```bash
aws eks update-kubeconfig --name <cluster_name> --region <region>
```

2. **Verify the EKS Cluster:**

```bash
kubectl get nodes
```

3. **Access ArgoCD:**

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
kubectl port-forward svc/argo-cd-server -n argocd 8080:443
```

Open: `https://localhost:8080`  
Login: `admin` + retrieved password

## 📂 Project Structure

```
.
├── argocd/                                   # Directory holding ArgoCD Helm values and configuration overrides
│   └── values.yaml                           # Custom values file for tuning ArgoCD deployment (nodeSelector, tolerations, RBAC, etc.)
├── argocd.tf                                 # Deploys ArgoCD into EKS using the Helm provider and configures GitOps settings
├── destroy.sh                                # Script to safely destroy the EKS cluster and tear down AWS resources
├── eks-storageclass.tf                       # Defines the StorageClass for dynamic provisioning using the EBS CSI driver
├── eks.tf                                    # Main EKS module: creates cluster, node groups, and associates IAM roles
├── iam.tf                                    # All IAM roles and policies (including IRSA) for EKS and addons like EBS CSI driver
├── locals.tf                                 # Local Terraform variables used internally for naming, tags, and reusable expressions
├── providers.tf                              # Terraform providers configuration (AWS, Kubernetes, Helm, etc.)
├── README.MD                                 # Full documentation for infrastructure setup and architecture
├── s3-backend-bootstrap.tf                   # Bootstraps the remote S3 backend and DynamoDB lock table for Terraform state
├── scripts/                                  # Utility scripts for cluster lifecycle operations
│   └── k8s-pre-destroy.sh                    # Pre-destroy script that cleans up LoadBalancers and Kubernetes resources before teardown
├── secrets.auto.tfvars                       # Auto-loaded secrets file with DB credentials and app keys (never committed to git)
├── secrets.tf                                # Defines AWS Secrets Manager resources, KMS encryption, and secret lifecycle│
├── tfbackend/                                # Terraform backend configuration separated by environment
│   └── prod.tfbackend                        # Backend config pointing Terraform state to S3 + DynamoDB in production│
├── tfvars/                                   # Variable overrides for each environment
│   └── prod.tfvars                           # Production variable values (cluster name, VPC CIDR, region, etc.)
├── variables-secrets.tf                      # Variables definition for sensitive values (referenced in secrets.auto.tfvars)
├── variables.tf                              # Main variables file for all configurable infra components
└── vpc.tf                                    # Provisions AWS VPC, subnets, NAT gateway, routing tables, and networking primitives

---

## 🧠 Core Architecture Concepts

This section explains the core design decisions behind the infrastructure and how they enable a secure, scalable, production-grade EKS setup.

### 🔐 IAM Roles for Service Accounts (IRSA)

EKS integrates Kubernetes service accounts with AWS IAM using OIDC, enabling pods to assume AWS roles without storing credentials.

**Benefits:**
- No static credentials in pods
- Per-pod least-privilege access
- AWS-native identity integration

**Flow:**

```
K8s Pod → ServiceAccount → IAM Role → AWS STS → AWS API
```

Used here for the **EBS CSI driver**, enabling pods to provision EBS volumes securely.

---

### 🌐 VPC & Networking Design

The VPC uses **public, private, and intra subnets**:

| Subnet Type      | Purpose |
|------------------|---------|
| Public           | NAT Gateway, load balancers |
| Private          | Worker nodes, workloads |
| Intra            | Internal-only services |

```
[VPC]
 ├─ Public Subnets     → IGW + NAT
 ├─ Private Subnets    → EKS Nodes
 └─ Intra Subnets      → Internal Services
```

This aligns with AWS Well-Architected Framework networking standards.

---

### 🧱 Node Groups & Workload Scheduling

To isolate workloads, this cluster uses **dedicated node groups**:

- **system nodes** → ArgoCD, control-plane services  
- **application nodes** → end-user workloads

```
System Pods → nodes with system=true
App Pods    → nodes without system label
```

Ensures resource predictability and cost-efficient autoscaling.

---

### 🔑 Secrets Management Strategy

Secrets are **never stored in Git**.

| Component     | Technology |
|--------------|-----------|
| Storage      | AWS Secrets Manager |
| Encryption   | AWS KMS |
| Access       | IRSA-linked roles |

Benefits:

- Central secrets lifecycle
- Auditable
- No plaintext exposure

---

### 🧱 Terraform Remote Backend Architecture

Terraform state runs remotely for safe collaboration:

- **S3 bucket** → stores Terraform state
- **DynamoDB table** → state locking

```
Terraform → S3 State
                ↳ DynamoDB Lock
```

Prevents corruption when multiple people apply infrastructure changes.

---

### 📦 Storage Provisioning (EBS CSI Driver)

EKS uses the **EBS CSI driver** for PersistentVolumes:

```
PVC → StorageClass → CSI Driver → EBS Volume
```

Volumes are encrypted automatically and lifecycle-managed by Kubernetes.

---

### 🛡️ Security Posture

| Layer | Protection |
|------|------------|
| IAM    | Scoped pod access via IRSA |
| Network| Private workloads, no public nodes |
| Storage| Encrypted EBS volumes |
| Secrets| Managed externally, KMS encrypted |
| Access | ArgoCD default admin reset post-install |

---

### 🧭 Architecture Overview Diagram

```
                 ┌────────────────┐
                 │ Git Repository │
                 └───────┬────────┘
                         │ GitOps
                         ▼
                 ┌───────────────┐
                 │    ArgoCD     │
                 └───────┬───────┘
                         │ Deploys Apps
                         ▼
              ┌──────────────────────┐
              │       EKS Cluster     │
              │  system & app nodes   │
              └──────────┬───────────┘
                         │
       ┌─────────────────┴────────────────┐
       ▼                                  ▼
AWS IAM (IRSA)                    AWS Secrets Manager
Scoped Pod Access               Encrypted Secrets Store
```

---

## 🎉 Conclusion

This architecture delivers a **production-ready, GitOps-driven EKS environment** with:

- Secure identity boundaries
- Automated application delivery
- Scalable and isolated workloads
- Managed secrets and storage provisioning

You now have everything required to deploy, operate, and extend this environment confidently.

```

---

## 🧠 Core Architecture Concepts

This section explains the core design decisions behind the infrastructure and how they enable a secure, scalable, production-grade EKS setup.

### 🔐 IAM Roles for Service Accounts (IRSA)

EKS integrates Kubernetes service accounts with AWS IAM using OIDC, enabling pods to assume AWS roles without storing credentials.

**Benefits:**
- No static credentials in pods
- Per-pod least-privilege access
- AWS-native identity integration

**Flow:**

```
K8s Pod → ServiceAccount → IAM Role → AWS STS → AWS API
```

Used here for the **EBS CSI driver**, enabling pods to provision EBS volumes securely.

---

### 🌐 VPC & Networking Design

The VPC uses **public, private, and intra subnets**:

| Subnet Type      | Purpose |
|------------------|---------|
| Public           | NAT Gateway, load balancers |
| Private          | Worker nodes, workloads |
| Intra            | Internal-only services |

```
[VPC]
 ├─ Public Subnets     → IGW + NAT
 ├─ Private Subnets    → EKS Nodes
 └─ Intra Subnets      → Internal Services
```

This aligns with AWS Well-Architected Framework networking standards.

---

### 🧱 Node Groups & Workload Scheduling

To isolate workloads, this cluster uses **dedicated node groups**:

- **system nodes** → ArgoCD, control-plane services  
- **application nodes** → end-user workloads

```
System Pods → nodes with system=true
App Pods    → nodes without system label
```

Ensures resource predictability and cost-efficient autoscaling.

---

### 🔑 Secrets Management Strategy

Secrets are **never stored in Git**.

| Component     | Technology |
|--------------|-----------|
| Storage      | AWS Secrets Manager |
| Encryption   | AWS KMS |
| Access       | IRSA-linked roles |

Benefits:

- Central secrets lifecycle
- Auditable
- No plaintext exposure

---

### 🧱 Terraform Remote Backend Architecture

Terraform state runs remotely for safe collaboration:

- **S3 bucket** → stores Terraform state
- **DynamoDB table** → state locking

```
Terraform → S3 State
                ↳ DynamoDB Lock
```

Prevents corruption when multiple people apply infrastructure changes.

---

### 📦 Storage Provisioning (EBS CSI Driver)

EKS uses the **EBS CSI driver** for PersistentVolumes:

```
PVC → StorageClass → CSI Driver → EBS Volume
```

Volumes are encrypted automatically and lifecycle-managed by Kubernetes.

---

### 🛡️ Security Posture

| Layer | Protection |
|------|------------|
| IAM    | Scoped pod access via IRSA |
| Network| Private workloads, no public nodes |
| Storage| Encrypted EBS volumes |
| Secrets| Managed externally, KMS encrypted |
| Access | ArgoCD default admin reset post-install |

---

### 🧭 Architecture Overview Diagram

```
                 ┌────────────────┐
                 │ Git Repository │
                 └───────┬────────┘
                         │ GitOps
                         ▼
                 ┌───────────────┐
                 │    ArgoCD     │
                 └───────┬───────┘
                         │ Deploys Apps
                         ▼
              ┌──────────────────────┐
              │       EKS Cluster     │
              │  system & app nodes   │
              └──────────┬───────────┘
                         │
       ┌─────────────────┴────────────────┐
       ▼                                  ▼
AWS IAM (IRSA)                    AWS Secrets Manager
Scoped Pod Access               Encrypted Secrets Store
```

---

## 🎉 Conclusion

This architecture delivers a **production-ready, GitOps-driven EKS environment** with:

- Secure identity boundaries
- Automated application delivery
- Scalable and isolated workloads
- Managed secrets and storage provisioning

You now have everything required to deploy, operate, and extend this environment confidently.

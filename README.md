# ☁️ Cloud Task — DevOps & Cloud Engineering Portfolio

[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5.svg?style=for-the-badge&logo=Kubernetes&logoColor=white)](https://kubernetes.io/)
[![Terraform](https://img.shields.io/badge/Terraform-7B42BC.svg?style=for-the-badge&logo=Terraform&logoColor=white)](https://www.terraform.io/)
[![Docker](https://img.shields.io/badge/Docker-2496ED.svg?style=for-the-badge&logo=Docker&logoColor=white)](https://www.docker.com/)
[![Ansible](https://img.shields.io/badge/Ansible-EE0000.svg?style=for-the-badge&logo=Ansible&logoColor=white)](https://www.ansible.com/)
[![AWS](https://img.shields.io/badge/AWS-232F3E.svg?style=for-the-badge&logo=Amazon-AWS&logoColor=white)](https://aws.amazon.com/)
[![Azure](https://img.shields.io/badge/Azure-0078D4.svg?style=for-the-badge&logo=Microsoft-Azure&logoColor=white)](https://azure.microsoft.com/)
[![Prometheus](https://img.shields.io/badge/Prometheus-E6522C.svg?style=for-the-badge&logo=Prometheus&logoColor=white)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/Grafana-F46800.svg?style=for-the-badge&logo=Grafana&logoColor=white)](https://grafana.com/)
[![ArgoCD](https://img.shields.io/badge/ArgoCD-EF7B4D.svg?style=for-the-badge&logo=Argo-CD&logoColor=white)](https://argo-cd.readthedocs.io/en/stable/)
[![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF.svg?style=for-the-badge&logo=GitHub-Actions&logoColor=white)](https://github.com/features/actions)

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Open in Cloud Shell](https://gstatic.com/cloudshell/images/open-btn.svg)](https://console.cloud.google.com/cloudshell/)

> A hands-on portfolio of real-world DevOps and cloud infrastructure projects — covering VMs, containers, Kubernetes, serverless, and self-hosted platforms. Built with Terraform (HCL), Shell scripting, Docker, and more.

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Repository Structure](#-repository-structure)
- [Projects](#-projects)
  - [Virtual Machines (vms)](#%EF%B8%8F-virtual-machines-vms)
  - [Kubernetes (k8s)](#-kubernetes-k8s)
  - [Docker](#-docker)
  - [Serverless](#-serverless)
  - [Coolify](#-coolify)
- [Tech Stack](#%EF%B8%8F-tech-stack)
- [Prerequisites](#-prerequisites)
- [Getting Started](#-getting-started)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🔍 Overview

**Cloud Task** is a curated collection of infrastructure and DevOps projects demonstrating practical, production-aligned patterns across the modern cloud stack.

Each section focuses on a distinct layer of the infrastructure landscape — from provisioning bare VMs and configuring them with Ansible, to orchestrating workloads in Kubernetes, packaging apps with Docker, deploying serverless functions, and running self-hosted platforms with Coolify.

**Primary languages:** HCL (Terraform) · Shell · PHP · Dockerfile

---

## 📁 Repository Structure

```
cloud-task/
├── vms/          # Virtual machine provisioning and configuration (Terraform + Ansible)
├── k8s/          # Kubernetes manifests, Helm charts, and cluster configs
├── Docker/       # Dockerfiles, Compose files, and containerisation examples
├── serverless/   # Serverless function deployments (AWS Lambda, GCP Functions, etc.)
├── coolify/      # Self-hosted PaaS setup and app deployment via Coolify
├── LICENSE
└── README.md
```

Each directory contains its own `README.md` with project-specific context, architecture notes, and usage instructions.

---

## 🗂️ Projects

### 🖥️ Virtual Machines (`vms`)

Provision and configure cloud VMs using **Terraform** for infrastructure-as-code and **Ansible** for configuration management. Projects here demonstrate multi-cloud VM deployments, networking setup, SSH hardening, and automated provisioning pipelines.

**Key tools:** Terraform · Ansible · AWS EC2 · Azure VMs · Shell scripting

---

### ☸️ Kubernetes (`k8s`)

End-to-end Kubernetes configurations covering cluster setup, workload deployment, GitOps workflows, and observability. Includes Helm charts, ArgoCD pipelines, Prometheus/Grafana monitoring stacks, and multi-namespace patterns.

**Key tools:** Kubernetes · Helm · ArgoCD · Prometheus · Grafana · OpenTelemetry · GitHub Actions

---

### 🐳 Docker (`Docker`)

Containerisation examples from simple single-service Dockerfiles to multi-container Compose setups. Explores image optimisation, multi-stage builds, and container networking patterns.

**Key tools:** Docker · Docker Compose · Dockerfile best practices

---

### ⚡ Serverless (`serverless`)

Deploy event-driven, serverless workloads across major cloud providers. Projects include HTTP-triggered functions, scheduled jobs, and integration with managed services like databases and queues.

**Key tools:** AWS Lambda · GCP Cloud Functions · Azure Functions · Terraform · Shell

---

### 🚀 Coolify (`coolify`)

Self-hosted PaaS deployments using [Coolify](https://coolify.io/) — an open-source alternative to Heroku/Vercel. Covers server provisioning, app onboarding, SSL configuration, and CI/CD integration on your own infrastructure.

**Key tools:** Coolify · Docker · Shell · Nginx

---

## 🛠️ Tech Stack

| Category | Tools |
|---|---|
| **Cloud Providers** | AWS · Azure · GCP |
| **Infrastructure as Code** | Terraform · Ansible |
| **Containers & Orchestration** | Docker · Kubernetes · Helm |
| **CI/CD & GitOps** | GitHub Actions · ArgoCD |
| **Monitoring & Observability** | Prometheus · Grafana · OpenTelemetry · ELK Stack |
| **Serverless** | AWS Lambda · GCP Cloud Functions · Azure Functions |
| **Self-hosted PaaS** | Coolify |
| **Scripting** | Bash · Shell · PHP |

---

## ✅ Prerequisites

Before diving in, make sure you have the following installed locally:

- [Git](https://git-scm.com/)
- [Terraform](https://developer.hashicorp.com/terraform/install) ≥ 1.5
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/) ≥ 2.14
- [Docker](https://docs.docker.com/get-docker/) & [Docker Compose](https://docs.docker.com/compose/install/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) + access to a Kubernetes cluster
- Cloud provider CLI configured:
  - [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
  - [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
  - [gcloud CLI](https://cloud.google.com/sdk/docs/install)

---

## 🚀 Getting Started

**1. Clone the repository**

```bash
git clone https://github.com/kibablu/cloud-task.git
cd cloud-task
```

**2. Pick a project**

Navigate to the directory that matches your area of interest:

```bash
cd k8s       # Kubernetes projects
cd vms       # VM provisioning with Terraform + Ansible
cd Docker    # Container examples
cd serverless # Serverless deployments
cd coolify   # Self-hosted PaaS
```

**3. Read the project README**

Each directory has a `README.md` with full setup instructions, architecture notes, and any required environment variables or credentials.

**4. Deploy and experiment**

Follow the step-by-step instructions inside the project folder. Most Terraform projects follow the standard workflow:

```bash
terraform init
terraform plan
terraform apply
```

---

## 🤝 Contributing

Contributions are welcome! If you have an improvement, new project, or bug fix:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Commit your changes: `git commit -m "feat: add your feature description"`
4. Push to your branch: `git push origin feature/your-feature-name`
5. Open a Pull Request

Please keep each project self-contained with its own `README.md`, and follow the existing directory structure conventions.

---

## 📄 License

This project is licensed under the **GNU General Public License v3.0**. See the [LICENSE](LICENSE) file for full details.

---

<div align="center">

Built with ☁️ by [kibablu](https://github.com/kibablu)

*Happy Deploying! 🚀*

</div>
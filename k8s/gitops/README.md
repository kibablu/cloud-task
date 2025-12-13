# GitOps

[![Terraform](https://img.shields.io/badge/Terraform-623ce4?logo=terraform&logoColor=white)](https://www.terraform.io/) [![GKE](https://img.shields.io/badge/GKE-4285F4?logo=google-cloud&logoColor=white)](https://cloud.google.com/kubernetes-engine) [![Argo CD](https://img.shields.io/badge/Argo%20CD-1F8FFF?logo=argo&logoColor=white)](https://argoproj.github.io/argo-cd/) [![Helm](https://img.shields.io/badge/Helm-0F172A?logo=helm&logoColor=white)](https://helm.sh/) [![Traefik](https://img.shields.io/badge/Traefik-00C7B7?logo=traefik&logoColor=white)](https://traefik.io/)

Overview

This folder contains GitOps manifests and Terraform code used to provision and configure a GKE cluster and deploy applications via Argo CD and Helm.

Quickstart

1) Provision infrastructure (Terraform)

   - Ensure you have the required tools installed: Terraform, gcloud, kubectl, and optionally Helm and the Argo CD CLI.
   - From the repository root or this directory, run:
     ```bash
     # adjust variables as needed; gke.tf manages cluster + related resources
     terraform init
     terraform apply
     ```

   - Terraform (gke.tf) provisions the GKE cluster and any cluster-level addons and service accounts required for the GitOps flow.

2) Deploy GitOps components

   - Depending on how gke.tf is configured, Argo CD, Traefik (Ingress), and other components may already be installed by Terraform. If not, use Helm or the manifests in this folder to install them. Example:
     ```bash
     # install Argo CD with Helm (if not provisioned by terraform)
     helm repo add argo https://argoproj.github.io/argo-helm
     helm repo update
     helm upgrade --install argo-cd argo/argo-cd -n argocd --create-namespace
     ```

Notes

- Terraform (gke.tf) is the source of truth for cluster provisioning in this repo — it handles APIs, service accounts, and cluster creation. 
- Use Argo CD to manage application deployment via GitOps once the cluster and control-plane components are available.

Repository layout (relevant files/directories)

- gke.tf               - Terraform code that provisions GKE and cluster-level resources
- terraform/           - (optional) additional Terraform modules/state files
- argocd/              - Argo CD application manifests (if present)
- helm/                - Helm charts or values used to deploy components
- traefik/             - Traefik Helm chart or manifests (if present)

Troubleshooting

- If Terraform applies fail, check GCP project/credentials and enable required APIs.
- Use kubectl get pods -A to inspect workloads once the cluster is up.


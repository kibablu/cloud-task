
![otel](https://github.com/user-attachments/assets/580866b1-1a13-4619-8f79-fe43359cc4da)

# 🌌 OpenTelemetry Demo on GKE with Custom Domain
This project automates the deployment of a public GKE cluster, reserves a static global IP, configures Cloud DNS, and deploys the OpenTelemetry (OTel) Demo via Helm. It is configured to serve the demo over HTTPS via a Google-managed SSL certificate.

## 🏗 Infrastructure (Terraform)
The infrastructure consists of:

- **VPC & Subnets**: Custom network for GKE.

- **GKE Cluster**: A public cluster using e2-standard-4 nodes to handle the OTel microservices.

- **Global Static IP**: Reserved for the External HTTP(S) Load Balancer.

- **Managed SSL Certificate**: Provisioned by Google for your custom domain (klaudmazoezi.top).

- **Cloud DNS**: Managed zone and A-record pointing to the static IP.

## Prerequisites

Before you begin, ensure you have the following:

1.  **Google Cloud Project**: A GCP project with billing enabled.
2.  **Registered Domain Name**: You must own a public domain name that you can manage.
3.  **Required Permissions**: Your GCP user or service account must have sufficient permissions to create the resources defined in this project (e.g., `Project Owner`, `Editor`, or a custom role with Compute Engine, GKE, and DNS admin rights).
4.  **Terraform**: Terraform installed on your local machine.
5.  **Google Cloud SDK**: The `gcloud` command-line tool installed and authenticated.

## Configuration

1.  **Clone the repository** (if you haven't already).

2.  **Update Terraform Variables**:
    Open the `variables.tf` file and modify the default values for the following variables:

    -   `project_id`: Your Google Cloud project ID.
    -   `domain_name`: Your registered public domain (e.g., `my-otel-demo.com`).

    ```terraform
    variable "project_id" {
      description = "The GCP project ID to deploy resources into"
      type        = string
      default     = "your-gcp-project-id" // <-- UPDATE THIS
    }

    variable "domain_name" {
      description = "The public domain name for your Cloud DNS zone (e.g., chrisproject.org)"
      type        = string
      default     = "your-domain.com" // <-- UPDATE THIS
    }
    ```

## Deployment

Follow these steps to provision the infrastructure:

1.  **Initialize Terraform**:
    Open your terminal in the `otel` directory and run:
    ```sh
    terraform init
    ```

2.  **Review the Plan**:
    Check the resources that Terraform will create:
    ```sh
    terraform plan
    ```

3.  **Apply the Configuration**:
    Deploy the resources to your GCP project. Confirm with `yes` when prompted.
    ```sh
    terraform apply
    ```
## Post-Deployment Steps

### 1. Update Your Domain's Name Servers

After `terraform apply` completes, Terraform will output the name servers for your new Cloud DNS zone. You need to update the name server records at your domain registrar (e.g., GoDaddy, Namecheap, Google Domains) to point to these values.

Example output:
```
Outputs:

name_servers = [
  "ns-cloud-e1.googledomains.com.",
  "ns-cloud-e2.googledomains.com.",
  "ns-cloud-e3.googledomains.com.",
  "ns-cloud-e4.googledomains.com.",
]
```

## ☸️ Kubernetes Setup
Once the infrastructure is ready, you must configure GKE to handle the Load Balancer health checks and routing.

### 1. Create the BackendConfig
GKE Ingress requires a BackendConfig to accurately monitor the health of the frontend-proxy.

```yaml
# backend-config.yaml
apiVersion: cloud.google.com/v1
kind: BackendConfig
metadata:
  name: otel-frontend-config
spec:
  healthCheck:
    type: HTTP
    port: 8080
    requestPath: /
```
Apply it: `kubectl apply -f backend-config.yaml`

## 🚀 OpenTelemetry Demo Deployment
We use the official OpenTelemetry Helm chart with a custom values.yaml to integrate with GCE Ingress.

### 1. The `values.yaml` Configuration
The configuration ensures that:

- The Ingress uses the reserved IP and SSL certificate.

- A wildcard path (`/*`) is used so Google Cloud Load Balancer routes all sub-tools (Grafana, Jaeger) to the Envoy proxy.

- The frontend is aware of the public domain for browser-side tracing

```yaml
components:
  frontend-proxy:
    service:
      type: NodePort
      annotations:
        cloud.google.com/backend-config: '{"default": "otel-frontend-config"}'
    ingress:
      enabled: true
      annotations:
        kubernetes.io/ingress.class: "gce"
        kubernetes.io/ingress.global-static-ip-name: "chris-ingress-global"
        networking.gke.io/managed-certificates: "chris-otel-demo-cert"
      hosts:
        - host: "example.com"
          paths:
            - path: /*
              pathType: ImplementationSpecific
              port: 8080
  frontend:
    envOverrides:
      - name: PUBLIC_OTEL_EXPORTER_OTLP_TRACES_ENDPOINT
        value: "https://example.com/otlp-http/v1/traces"
```

### 2. Helm Installation
```sh
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update
helm install otel-demo open-telemetry/opentelemetry-demo -f values.yaml
```
## 🔗 Accessing the Demo
After deployment, the Google Cloud Load Balancer and SSL certificate can take 10–20 minutes to fully provision.

|Service | URL
|--------| ------
|Astronomy Shop|https://example.com/
|Grafana|https://example.com/grafana/
|Jaeger UI|https://example.com/jaeger/ui/
|Feature Flags|https://example.com/feature/
|Load Gen UI|https://example.com/loadgen/

## 🛠 Troubleshooting
- `404` Backend NotFound: This usually means the Google Load Balancer is still provisioning or the health check on port 8080 is failing. Check status with:
    ```sh
     kubectl describe ingress otel-demo-frontendproxy
    ```
- SSL Handshake Failed: Ensure the DNS A-record matches your reserved IP. Check certificate status:
    ```sh
    kubectl get managedcertificate chris-otel-demo-cert
    ```
- Products Not Loading: Check the browser console (`F12`). If you see connection errors to `localhost`, ensure the `PUBLIC_OTEL_EXPORTER_OTLP_TRACES_ENDPOINT` in `values.yaml` is set to your real domain.

## 🗑️ Cleanup

To avoid incurring ongoing charges, destroy the resources when you are finished:

```sh
terraform destroy
```


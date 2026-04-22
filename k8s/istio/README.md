# Production-Ready Istio Service Mesh on GKE

> Deploy the Istio Bookinfo application on Google Kubernetes Engine with automatic HTTPS, mTLS and full observability — provisioned with Terraform and installed with Helm.

![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![Google Cloud](https://img.shields.io/badge/Google_Cloud-4285F4?style=for-the-badge&logo=google-cloud&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![Istio](https://img.shields.io/badge/Istio-466BB0?style=for-the-badge&logo=istio&logoColor=white)
![Helm](https://img.shields.io/badge/Helm-0F1689?style=for-the-badge&logo=helm&logoColor=white)
![Cert Manager](https://img.shields.io/badge/Cert_Manager-00BFFF?style=for-the-badge&logo=letsencrypt&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white)
![Jaeger](https://img.shields.io/badge/Jaeger-66CFE2?style=for-the-badge&logo=jaeger&logoColor=white)
![Kiali](https://img.shields.io/badge/Kiali-006EAF?style=for-the-badge&logo=kiali&logoColor=white)

---

## Overview

This repository contains everything needed to deploy the [Istio Bookinfo](https://istio.io/latest/docs/examples/bookinfo/) sample application on a production-grade GKE Standard cluster. Starting from an empty GCP project, we provision all infrastructure using Terraform, install Istio and the full observability stack using Helm, and expose all services securely over HTTPS using Cert-Manager and Let's Encrypt.

## Architecture

```
Internet
   │
   ▼  HTTPS (443)
┌──────────────────────────────────────┐
│     GCP External LoadBalancer        │
└───────────────┬──────────────────────┘
                │
                ▼
┌───────────────────────────────────────────────────────────┐
│   GKE Standard Cluster (public master, private nodes)     │
│                                                           │
│   ┌─────────────────────────────────┐                     │
│   │  Namespace: istio-ingress       │                     │
│   │  Istio IngressGateway (Envoy)   │                     │
│   │  TLS terminated by Cert-Manager │                     │
│   └────────────┬────────────────────┘                     │
│                │                                          │
│   ┌────────────▼──────────────────────────────────┐       │
│   │  Namespace: default (istio-injection=enabled) │       │
│   │                                               │       │
│   │  productpage ──► details                      │       │
│   │       └──────► reviews v1/v2/v3               │       │
│   │                     └──► ratings              │       │
│   └───────────────────────────────────────────────┘       │
│                                                           │
│   ┌─────────────────────────────────┐                     │
│   │  Namespace: istio-system        │                     │
│   │  Istiod, Kiali, Jaeger          │                     │
│   └─────────────────────────────────┘                     │
│                                                           │
│   ┌─────────────────────────────────┐                     │
│   │  Namespace: monitoring          │                     │
│   │  Prometheus + Grafana           │                     │
│   └─────────────────────────────────┘                     │
└───────────────────────────────────────────────────────────┘
```

## Repository Structure

```
istio/
├── terraform/
│   ├── main.tf                  # VPC, subnet, NAT, GKE cluster, node pool, SA
│   ├── firewall.tf              # All firewall rules for GKE + Istio
│   ├── variables.tf             # Input variables
│   ├── outputs.tf               # Cluster name, endpoint, SA email
│   └── terraform.tfvars         # Your project-specific values
│
└── manifests/
    ├── gateways.yaml                 #  Gateways for Bookinfo 
    ├── virtualservice.yaml           # VirtualServices
    ├── cluster-issuer.yaml           # Cert-Manager ClusterIssuer (Let's Encrypt)
    └── certificates.yaml             # TLS certificates for all domains
```

## Prerequisites

| Tool | Version |
|---|---|
| gcloud CLI | latest |
| Terraform | >= 1.6 |
| Helm | >= 3.10 |
| kubectl | >= 1.28 |

## Deployment

### 1. Provision GCP Infrastructure

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars — set your project_id at minimum

terraform init
terraform apply
```

### 2. Configure kubectl

```bash
gcloud container clusters get-credentials bookinfo-istio \
  --zone us-central1-a --project YOUR_PROJECT_ID
```

### 3. Install Istio via Helm

```bash
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update

kubectl create namespace istio-system

helm install istio-base istio/base \
  -n istio-system --version 1.29.2

helm install istiod istio/istiod \
  -n istio-system --version 1.29.2 --wait

kubectl create namespace istio-ingress
kubectl label namespace istio-ingress istio-injection=enabled

helm install istio-ingressgateway istio/gateway \
  -n istio-ingress --version 1.29.2 --wait
```

### 4. Fix Ingress Gateway targetPort

Ensure the LoadBalancer service forwards to the correct ports on the gateway pod:

```bash
kubectl patch svc istio-ingressgateway -n istio-ingress --type='json' -p='[
  {"op": "replace", "path": "/spec/ports/1/targetPort", "value": 8080},
  {"op": "replace", "path": "/spec/ports/2/targetPort", "value": 8443}
]'
```

### 5. Install Cert-Manager

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.17.0 \
  --set crds.enabled=true
```

### 6. Create DNS Records

Before creating certificates, add A records in your GCP Cloud DNS zone pointing all subdomains to your Ingress Gateway external IP:

```
yourdomain.com          → INGRESS_GATEWAY_IP
grafana.yourdomain.com  → INGRESS_GATEWAY_IP
kiali.yourdomain.com    → INGRESS_GATEWAY_IP
jaeger.yourdomain.com   → INGRESS_GATEWAY_IP
```

Verify DNS is resolving before proceeding:

```bash
nslookup yourdomain.com
nslookup grafana.yourdomain.com
nslookup kiali.yourdomain.com
nslookup jaeger.yourdomain.com
```

### 7. Apply Certificates and Gateways

```bash
# ClusterIssuer + Certificates
kubectl apply -f k8s-manifests/cluster-issuer.yaml
kubectl apply -f k8s-manifests/certificates.yaml

# Wait for all certs to be ready before proceeding
kubectl get certificate -n istio-ingress -w

# Gateways and VirtualServices
kubectl apply -f k8s-manifests/bookinfo-gateway.yaml
kubectl apply -f k8s-manifests/observability-gateway.yaml
kubectl apply -f k8s-manifests/bookinfo-vs.yaml
kubectl apply -f k8s-manifests/grafana-vs.yaml
kubectl apply -f k8s-manifests/kiali-vs.yaml
kubectl apply -f k8s-manifests/jaeger-vs.yaml
```

### 8. Deploy Bookinfo

```bash
kubectl label namespace default istio-injection=enabled

kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.29/samples/bookinfo/platform/kube/bookinfo.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.29/samples/bookinfo/networking/destination-rule-all.yaml
```

### 9. Install the Observability Stack

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add kiali https://kiali.org/helm-charts
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm repo update

kubectl create namespace monitoring

helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set grafana.adminPassword=admin \
  --set "grafana.grafana\.ini.server.domain=grafana.yourdomain.com" \
  --set "grafana.grafana\.ini.server.root_url=https://grafana.yourdomain.com" \
  --wait

helm install kiali-server kiali/kiali-server \
  --namespace istio-system \
  --set auth.strategy=anonymous \
  --set external_services.prometheus.url="http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090" \
  --set external_services.grafana.url="http://kube-prometheus-stack-grafana.monitoring.svc.cluster.local:80" \
  --wait

helm install jaeger jaegertracing/jaeger \
  --namespace istio-system \
  --set provisionDataStore.cassandra=false \
  --set allInOne.enabled=true \
  --set storage.type=memory \
  --set agent.enabled=false \
  --set collector.enabled=false \
  --set query.enabled=false \
  --wait
```

### 10. Configure Istio Distributed Tracing

By default Istiod does not know where to send trace spans. We patch the `istio` configmap to point it at our Jaeger instance using the Zipkin protocol on port `9411` — Jaeger is fully compatible with Zipkin so no additional configuration is needed on the Jaeger side. The `sampling` value of `100` traces every request which is ideal for a demo environment — reduce this to `1` or `5` in production to avoid performance overhead:

```bash
kubectl patch configmap istio -n istio-system --type merge -p '{
  "data": {
    "mesh": "defaultConfig:\n  tracing:\n    zipkin:\n      address: jaeger.istio-system.svc.cluster.local:9411\n    sampling: 100\nenableTracing: true\noutboundTrafficPolicy:\n  mode: ALLOW_ANY"
  }
}'
```

After patching, restart all Bookinfo pods so their Envoy sidecars pick up the new tracing configuration:

```bash
kubectl rollout restart deployment -n default
kubectl rollout status deployment -n default
```

Generate traffic to populate traces:

```bash
for i in $(seq 1 50); do
  curl -s "https://yourdomain.com/productpage" > /dev/null
done
```

Open Jaeger at `https://jaeger.yourdomain.com`, select `productpage` from the Service dropdown and click **Find Traces** to see the full distributed trace across all Bookinfo microservices.

---

## Accessing the Stack

| Service | URL |
|---|---|
| Bookinfo App | `https://yourdomain.com/productpage` |
| Grafana | `https://grafana.yourdomain.com` |
| Kiali | `https://kiali.yourdomain.com` |
| Jaeger | `https://jaeger.yourdomain.com` |

### Grafana Istio Dashboards

Import these official Istio dashboard IDs in Grafana (`Dashboards` → `Import` → paste ID):

| Dashboard | ID |
|---|---|
| Istio Control Plane | `7645` |
| Istio Mesh | `7639` |
| Istio Service | `7636` |
| Istio Workload | `7630` |

---

## Teardown

```bash
helm uninstall istio-ingressgateway -n istio-ingress
helm uninstall istiod -n istio-system
helm uninstall istio-base -n istio-system
helm uninstall cert-manager -n cert-manager
helm uninstall kube-prometheus-stack -n monitoring
helm uninstall kiali-server -n istio-system
helm uninstall jaeger -n istio-system

cd terraform
terraform destroy
```

---

## Article

Read the full step-by-step article on Hashnode:
[Production-Ready on GKE: Istio Service Mesh with Automatic HTTPS, mTLS and Real-Time Observability](https://bablu.hashnode.dev/production-ready-on-gke-istio-service-mesh-with-automatic-https-mtls-and-real-time-observability)
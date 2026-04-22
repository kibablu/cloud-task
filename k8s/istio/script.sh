# Connecting to our gke cluster
gcloud container clusters get-credentials bookinfo-istio \
  --zone us-central1-a --project YOUR_PROJECT_ID

# Installing istio using helm

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

# Installing Cert-Manager 

helm repo add jetstack https://charts.jetstack.io
helm repo update

helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.17.0 \
  --set crds.enabled=true

# Installing Monitoring stack

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add kiali https://kiali.org/helm-charts
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm repo update

kubectl create namespace monitoring

helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set grafana.adminPassword=admin \
  --set "grafana.grafana\.ini.server.domain=grafana.klaudmazoezi.top" \
  --set "grafana.grafana\.ini.server.root_url=https://grafana.klaudmazoezi.top" \
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
  
# Enabling istio on a namespace

kubectl label namespace default istio-injection=enabled

# Installing Book Info sample application

kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.29/samples/bookinfo/platform/kube/bookinfo.yaml

kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.29/samples/bookinfo/networking/bookinfo-gateway.yaml

kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.29/samples/bookinfo/networking/destination-rule-all.yaml


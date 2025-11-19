# /bin/bash

gcloud container clusters describe gke-db-cluster \
    --zone us-central1-a \
    --project PROJECT_ID \
    --format 'value(endpoint)'

# installing argocd
VERSION=$(curl -L -s https://raw.githubusercontent.com/argoproj/argo-cd/stable/VERSION)
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/download/v$VERSION/argocd-linux-amd64
chmod +x argocd-linux-amd64
./argocd-linux-amd64
sudo mv argocd-linux-amd64 /usr/local/bin/argocd
argocd version --client

# login to argocd
argocd login IP_ADDRESS:80 --insecure

# create a firewallrule to allow vm to access argocd gke 
# to run argocd commands

gcloud compute firewall-rules create allow-argocd-cli-to-gke \
--network=PROJECT_ID-gke-vpc \
--allow=tcp:80 \
--source-ranges=10.0.1.0/28 \
--destination-ranges=10.0.40.0/24 \
--direction=INGRESS \
--priority=999
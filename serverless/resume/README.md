# Cloud Resume Challenge — GCP

A fully serverless, production-grade resume hosted on Google Cloud Platform, built as part of the [Cloud Resume Challenge](https://cloudresumechallenge.dev/docs/the-challenge/googlecloud/). Every piece of infrastructure is written as code using Terraform — zero manual console clicks.

**Live site:** `https://your-domain.com`

---

## Architecture

```
                        ┌──────────────────────────────┐
                        │         Browser               │
                        └──────────────┬───────────────┘
                                       │
                                       ▼
                        ┌──────────────────────────────┐
                        │         Cloud DNS             │
                        │   A record → Static IP        │
                        └──────────────┬───────────────┘
                                       │
                                       ▼
                        ┌──────────────────────────────┐
                        │  Global App Load Balancer     │
                        │  ┌────────────────────────┐  │
                        │  │  :80 → HTTPS redirect  │  │
                        │  └────────────────────────┘  │
                        │  ┌────────────────────────┐  │
                        │  │  :443 → SSL → URL Map  │  │
                        │  └──────────┬─────────────┘  │
                        └─────────────┼────────────────┘
                                      │
               ┌──────────────────────┴──────────────────────┐
               │                                              │
        /* (static)                               /api/counter
               │                                              │
               ▼                                              ▼
┌──────────────────────────┐              ┌──────────────────────────────┐
│       Cloud CDN           │              │   Serverless NEG             │
│  CACHE_ALL_STATIC 24h TTL │              │   (Cloud Run backend)        │
└─────────────┬────────────┘              └──────────────┬───────────────┘
              │                                          │
              ▼                                          ▼
┌──────────────────────────┐              ┌──────────────────────────────┐
│  Cloud Storage Bucket     │              │  Cloud Functions Gen 2       │
│  (private bucket,         │              │  Python 3.12                 │
│   public objects via IAM) │              │  ingress: INTERNAL_AND_GCLB  │
└──────────────────────────┘              └──────────────┬───────────────┘
                                                         │
                                                         ▼
                                          ┌──────────────────────────────┐
                                          │       Cloud Firestore         │
                                          │  visitors/counter {count: N}  │
                                          │  Atomic transaction writes    │
                                          └──────────────────────────────┘
```

### Traffic flow

| Path | Route |
|---|---|
| `GET /` | LB → CDN → Cloud Storage bucket (static HTML/CSS) |
| `GET /api/counter` | LB → Serverless NEG → Cloud Function → Firestore |
| `HTTP :80` | LB → 301 redirect to HTTPS |
| Direct function URL | ❌ 403 — blocked by ingress policy |

---

## Stack

| Layer | GCP Service | Purpose |
|---|---|---|
| Static hosting | Cloud Storage | Serves HTML, CSS, JS |
| CDN | Cloud CDN | Global edge caching — `CACHE_ALL_STATIC`, 24h TTL |
| Load balancer | Global Application LB | TLS termination, URL routing, HTTP→HTTPS redirect |
| TLS | Google-Managed SSL Cert | Auto-provisioned and auto-rotated |
| DNS | Cloud DNS | Custom domain A record |
| API | Cloud Functions Gen 2 (Python) | Visitor counter — the only thing that touches Firestore |
| Database | Cloud Firestore (Native) | Stores visitor count with atomic transactions |
| IaC | Terraform | Every resource above, zero manual console steps |

---

## Repository structure

```
cloud-resume-gcp/
├── main.tf                        # Root — wires all modules together
├── variables.tf                   # All input variables
├── outputs.tf                     # All outputs (IPs, URLs, function endpoint)
├── terraform.tfvars.example       # Copy to terraform.tfvars and fill in
│
├── site/                          # Static resume content
│   ├── index.html                 # Resume page (visitor counter JS inline)
│   └── counter.js                 # Standalone counter snippet (reference)
│
├── function_src/                  # Cloud Function source (Python)
│   ├── main.py                    # HTTP handler + Firestore logic
│   ├── requirements.txt           # Runtime deps (deployed with function)
│   ├── requirements-dev.txt       # Dev/test deps (never deployed)
│   └── tests/
│       └── test_visitor_counter.py  # 14 unit tests, no real GCP needed
│
└── modules/
    ├── storage/                   # GCS bucket + IAM
    ├── load_balancer/             # LB + CDN + SSL + static IP + serverless NEG
    ├── dns/                       # Cloud DNS records
    ├── firestore/                 # Firestore database + seed document
    └── cloud_function/            # Cloud Function + custom IAM role + build perms
```

---

## Security design

### Visitor counter API

The browser **never** communicates with Firestore directly. The only data flow is:

```
Browser JS  →  fetch("/api/counter")  →  Python Cloud Function  →  Firestore
```

JavaScript calls a relative URL `/api/counter` which routes through the load balancer. The Cloud Function URL (`*.cloudfunctions.net`) is completely unreachable from the internet due to `ingress_settings = ALLOW_INTERNAL_AND_GCLB`.

### Least-privilege IAM — custom Firestore role

Instead of the broad `roles/datastore.user`, the function's service account is bound to a **custom role** with exactly the 4 permissions it needs:

| Permission | Why |
|---|---|
| `datastore.databases.get` | Connect to the database |
| `datastore.entities.get` | Read the counter in a transaction |
| `datastore.entities.create` | Create the document if absent |
| `datastore.entities.update` | Write the incremented value |

The function **cannot** delete documents, list collections, manage indexes, or access any namespace other than the one it writes to.

### Storage bucket

The bucket uses `uniform_bucket_level_access = true` (IAM-only, no legacy ACLs). The bucket itself is private. Objects are publicly readable via a single IAM binding: `allUsers → roles/storage.objectViewer`. This is the correct pattern for a CDN-backed static site — the CDN fetches from GCS, not the public internet directly.

---

## Prerequisites

| Tool | Version |
|---|---|
| Terraform | >= 1.5 |
| gcloud CLI | latest |
| Python | 3.12 (for running tests locally) |

### Enable required GCP APIs

```bash
gcloud services enable \
  compute.googleapis.com \
  dns.googleapis.com \
  storage.googleapis.com \
  cloudfunctions.googleapis.com \
  cloudbuild.googleapis.com \
  run.googleapis.com \
  firestore.googleapis.com \
  artifactregistry.googleapis.com \
  --project YOUR-PROJECT-ID
```

### Authenticate

```bash
gcloud auth application-default login
```

---

## Deploy

```bash
# 1. Clone the repo
git clone https://github.com/YOUR-USERNAME/cloud-resume-gcp
cd cloud-resume-gcp

# 2. Configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — see Configuration section below

# 3. Initialise Terraform
terraform init

# 4. Preview what will be created (~25 resources)
terraform plan

# 5. Deploy
terraform apply
```

After apply, Terraform prints your outputs:

```
lb_ip_address       = "34.x.x.x"
resume_domain_url   = "https://resume.yourdomain.com"
function_url        = "https://us-central1-PROJECT.cloudfunctions.net/..."
```

---

## Configuration

Copy `terraform.tfvars.example` to `terraform.tfvars` and set these values:

| Variable | Required | Default | Description |
|---|---|---|---|
| `project_id` | ✅ | — | GCP project ID |
| `region` | | `us-central1` | Region for Cloud Function and NEG |
| `bucket_name` | ✅ | — | Globally unique GCS bucket name |
| `domain` | ✅ | — | Custom domain e.g. `resume.example.com` |
| `dns_zone_name` | ✅ | — | Cloud DNS zone name (not the DNS name) |
| `create_dns_zone` | | `false` | Set `true` to create the zone via Terraform |
| `name_prefix` | | `cloud-resume` | Prefix for all GCP resource names |
| `firestore_location` | | `nam5` | Firestore multi-region (`nam5` = US, `eur3` = EU) |
| `counter_collection` | | `visitors` | Firestore collection for the counter |

Example `terraform.tfvars`:

```hcl
project_id    = "my-gcp-project-123"
bucket_name   = "my-resume-bucket-abc"
domain        = "resume.example.com"
dns_zone_name = "example-com"
```

---

## DNS setup

### Option A — Zone already exists in Cloud DNS

Leave `create_dns_zone = false` (default). Terraform adds an A record to the existing zone. Make sure `dns_zone_name` is the zone's **name** field, not its DNS name.

### Option B — Create the zone via Terraform

Set `create_dns_zone = true`. After apply, point your registrar to the GCP name servers:

```bash
terraform output dns_zone_name_servers
```

### SSL certificate activation

The Google-managed certificate becomes `ACTIVE` only after DNS resolves to the load balancer IP. This takes 10–20 minutes after DNS propagation.

```bash
# Check certificate status
gcloud compute ssl-certificates describe cloud-resume-cert --global --format="value(managed.status)"
```

---

## Upload your resume

```bash
# Upload all site files
gsutil -m cp -r ./site/* gs://$(terraform output -raw bucket_name)/

# HTML should not be cached — assets should be cached forever
gsutil setmeta -h "Cache-Control:no-cache, no-store" \
  gs://$(terraform output -raw bucket_name)/index.html

# Invalidate CDN after any update
gcloud compute url-maps invalidate-cdn-cache cloud-resume-url-map \
  --path "/*" --global
```

---

## Visitor counter

The counter is a Python Cloud Function that atomically increments a Firestore document on every page visit. The function uses a Firestore transaction so concurrent requests never produce duplicate counts.

### Test the API

```bash
curl $(terraform output -raw function_url)
# {"count": 42}
```

> Note: Direct calls to the function URL work from outside the LB only if you haven't restricted ingress. Once `ALLOW_INTERNAL_AND_GCLB` is enforced, use `/api/counter` via your domain.

### Run unit tests locally

```bash
cd function_src
pip install -r requirements-dev.txt
pytest tests/ -v
```

The 14 tests cover all HTTP methods, CORS headers, atomic increment logic, error handling, and include an architecture guard test that asserts the HTTP handler contains no direct Firestore calls.

---

## Outputs

```bash
terraform output                    # show all outputs
terraform output -raw lb_ip_address # just the IP
terraform output -raw function_url  # just the function URL
```

| Output | Description |
|---|---|
| `lb_ip_address` | Global static IP — use this in your DNS A record |
| `resume_url` | `https://` URL via the load balancer IP directly |
| `resume_domain_url` | `https://` URL via your custom domain |
| `function_url` | Direct Cloud Function URL (for testing) |
| `dns_zone_name_servers` | Name servers if the zone was created by Terraform |

---

## Cost estimate

| Resource | Cost/month |
|---|---|
| Cloud Storage < 1 GB | ~$0.02 |
| Global Load Balancer (2 forwarding rules) | ~$18.00 |
| Cloud CDN < 10 GB egress | ~$0.08 |
| Cloud Functions (2M free invocations/month) | ~$0.00 |
| Cloud Firestore (free tier covers this easily) | ~$0.00 |
| Cloud DNS (1 zone, < 1M queries) | ~$0.40 |
| **Total** | **~$18.50/month** |

> The load balancer dominates the cost. It's the minimum required for HTTPS + custom domain + CDN on GCP. Cloud Functions and Firestore are effectively free at resume-traffic scale.

---

## Tear down

```bash
terraform destroy
```

This removes all provisioned resources. The Firestore database `deletion_policy = "DELETE"` ensures it is fully removed and does not block the destroy.

---

## Known issues & lessons learned

| Issue | Resolution |
|---|---|
| Cloud Build Gen 2 "missing permission" error | Grant `roles/cloudbuild.builds.builder` to the **Compute default SA** (`<number>-compute@...`), not the Cloud Build SA |
| `EXTERNAL` vs `EXTERNAL_MANAGED` scheme conflict | All resources in a URL map must use the same scheme. Use `-replace` to recreate affected resources when changing schemes |
| Firestore `(default)` database name breaks `local-exec` shell | Use `google_firestore_document` resource instead of `null_resource` + `gcloud` |
| Stale Terraform module cache after adding variables | Run `terraform init -upgrade` to force re-read of local modules |
| Serverless NEG backend service rejects `port_name` / `protocol` | These attributes are not valid for serverless NEG backends — omit them entirely |

---

## What's next

- [ ] **CI/CD** — GitHub Actions to auto-deploy site and function on push
- [ ] **Cloud Armor** — rate limiting on the load balancer to prevent counter abuse
- [ ] **Monitoring** — Cloud Monitoring alerts on function error rate and latency
- [ ] **Remote state** — GCS backend for Terraform state with state locking

---

## Resources

- [Cloud Resume Challenge — GCP edition](https://cloudresumechallenge.dev/docs/the-challenge/googlecloud/)
- [Terraform Google Provider docs](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Cloud Functions Gen 2 troubleshooting](https://cloud.google.com/functions/docs/troubleshooting)
- [Serverless NEGs with Cloud Load Balancing](https://cloud.google.com/load-balancing/docs/negs/serverless-neg-concepts)
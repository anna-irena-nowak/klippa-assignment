# Deployment notes
This is not a deployment manual, but rather a collection of notes made during dev stage.

## Local
- service listens on 8082
  `docker run -p 8082:8082 jerbob92/pdfium-webserver:v0.0.1`
  
- example render request
```
  curl -X POST http://localhost:8082 \
  -F "file=@/home/anna/Downloads/Freddie-cv.pdf" \
  -F "dpi=300"\
  -F "page=1"
```

- minikube with docker driver so service can be exposed via ingress controller
  `minikube start --driver=docker`

## GKE
- E2-medium VM type for low cost. Autopilot also uses E2 family.

## Terraform
Install gcloud CLI according to preferences. Then 
```
gcloud init
gcloud auth application-default login
```
to generate credentials that Terraform can use. Also check out `GOOGLE_APPLICATION_CREDENTIALS` var that can point to credentials json file.

### Deployment

```
cd cluster
# provide project ID via cmdline or tfvars
terraform plan (-var "project_id=<google project ID>" -out plan)
terraform apply (-var "project_id=<google project ID>")
```

## Service

### Deployment

`sudo dnf install google-cloud-sdk-gke-gcloud-auth-plugin`
for kubectl authentication.
Get credentials for a cluster:
```
gcloud container clusters get-credentials klippa-assignment --region=europe-west4
```

```
# nginx
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
# cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update
```

Get reserved IP for the load balancer:
```
gcloud compute addresses list
35.204.29.127
```
Or, better
```
terraform output reserved_ip
```

and update `values-ingress.yaml` with the IP as needed.
```
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
--namespace ingress-nginx \
--create-namespace \
-f values-ingress.yaml
```

Install `cert-manager` with workaround for GKE Autopilot, see https://cert-manager.io/docs/installation/compatibility/#gke-autopilot
```
helm upgrade --install cert-manager jetstack/cert-manager \
--namespace cert-manager \
--create-namespace \
--version v1.17.2 \
--set global.leaderElection.namespace=cert-manager \
--set crds.enabled=true
```
See also [How to uninstall cert-manager](https://cert-manager.io/docs/installation/kubectl/#uninstalling)

Great reference docs: https://cert-manager.io/docs/tutorials/acme/nginx-ingress/

Create OAuth secrets in the cluster (assuming new OAuth app is registered, in this case in GitHub)
```
kubectl create secret generic oauth2-secret \
  --from-literal=client-id=<github-client-id> \
  --from-literal=client-secret=<github-client-secret> \
  --from-literal=cookie-secret=$(openssl rand -base64 32 | tr -- '+/' '-_')
```

Install KEDA for pod scaling
```
helm repo add kedacore https://kedacore.github.io/charts
helm repo update
helm install keda kedacore/keda \
--version 2.17.0 \
--namespace keda \
--create-namespace
```

## Monitoring
For some obscure reason I couldn't enable Managed Prometheus on an Autopilot cluster, so moving to a Standard cluster instead. 

Install kube-prometheus-stack with Grafana included:
```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install prometheus-stack prometheus-community/kube-prometheus-stack \
--namespace monitoring \
--create-namespace \
--version 72.3.1
```

Install Loki:
```
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install loki grafana/loki-stack \
--namespace monitoring \
--set grafana.enabled=false \
--set promtail.enabled=true
```

## Testing
**OAuth**. Use GitHub PAT as a request token for the simplest way to get through authentication. However, it's very easy to hit GitHub rate limits like that, so the quickest dirty workaround is to expose an endpoint for testing bypassing OAuth redirect by applying `ingress-testing.yaml`. There exists probably some sensible way around that.

Start Locust webUI in the directory containing `locustfile.py`.

# Spring Boot Product Catalogue Microservice

A containerized Spring Boot CRUD microservice running three version environments concurrently on Kubernetes (Minikube) using namespace isolation, resource bounds, HPA, RBAC security, cert-manager TLS, and a GitHub Actions pipeline.

---

## 1. Quick Start (Local Run)

By default, the application runs on port `9191` and uses a standalone in-memory H2 database.

### Prerequisites
- Java JDK 8
- Maven 3

### Steps
1. Install dependencies and compile packages:
   ```bash
   mvn clean install
   ```
2. Run unit and integration tests:
   ```bash
   mvn test
   ```
3. Start the application (runs as v2.0 by default):
   ```bash
   APP_VERSION=2.0 mvn spring-boot:run
   ```
   *To change the active version behavior, adjust the `APP_VERSION` environment variable to `1.0`, `1.1`, or `2.0` accordingly.*

---

## 2. Terraform Cluster Provisioning

To declaratively provision the local Minikube cluster with all addons enabled:
1. Navigate to the terraform directory:
   ```bash
   cd terraform
   ```
2. Initialize and apply the modules:
   ```bash
   terraform init
   ```
   ```bash
   terraform apply -auto-approve
   ```

---

## 3. Deploying to Kubernetes (Minikube)

### Step 1: Install cert-manager
Install `cert-manager` for TLS certificate handling:
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
```
Wait for cert-manager pods to be ready:
```bash
kubectl wait --namespace cert-manager \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/instance=cert-manager \
  --timeout=120s
```

### Step 2: Build & Load Image
Point your shell to the Minikube Docker daemon and build the image:
```bash
eval $(minikube docker-env)
docker build -t product-catalogue:latest .
```

### Step 3: Deploy Overlays
Apply all namespace and version configurations via Kustomize:
```bash
kubectl apply -k k8s/
```

### Step 4: Verify Certificates
Verify that cert-manager has issued the TLS certificates for the versions (marked as `READY=True`):
```bash
kubectl get certificates -A
```

### Step 5: Query Endpoints (TLS / HTTPS)
Get your Minikube IP:
```bash
minikube ip
```
Query the endpoints over HTTPS using curl (resolving `catalogue.local` to your Ingress IP):

```bash
# Version 1.0 (Health & full list only)
curl -k --resolve "catalogue.local:443:$(minikube ip)" https://catalogue.local/v1/health
curl -k --resolve "catalogue.local:443:$(minikube ip)" https://catalogue.local/v1/products
curl -k --resolve "catalogue.local:443:$(minikube ip)" https://catalogue.local/v1/products/search?q=keyboard # Returns 404

# Version 1.1 (Supports keyword search)
curl -k --resolve "catalogue.local:443:$(minikube ip)" https://catalogue.local/v1.1/products/search?q=keyboard

# Version 2.0 (Supports search + pagination + maxPrice filters + exception responses)
curl -k --resolve "catalogue.local:443:$(minikube ip)" "https://catalogue.local/v2/products/search?q=Mouse&page=1&limit=2"
curl -k --resolve "catalogue.local:443:$(minikube ip)" "https://catalogue.local/v2/products/search?page=-1" # Returns 400 Bad Request
```

---

## 4. Security & RBAC Configuration

- **Least Privilege SA:** Containers run under the custom `catalogue-service-account` ServiceAccount.
- **Token Security:** Disabled mounting cluster access credentials (`automountServiceAccountToken: false`) since the pods do not call the API Server.
- **Resource Constraints:** Java memory limits requests at `256Mi` (Limits at `512Mi`) to prevent OutOfMemory (OOM) cluster terminations.

---

## 5. CI/CD Pipeline

The GitHub Actions workflow `.github/workflows/ci-cd.yml` automates the following steps:
1. **Compilation & Tests**: Runs Maven compile and Junit tests.
2. **Dockerization**: Builds the multi-stage image.
3. **Vulnerability Scanner**: Scans image using **Trivy**, blocking the build on High/Critical CVEs.
4. **Push**: Publishes versioned tags to Docker Hub.
5. **K8s Deploy**: Setup Minikube in GHA, deploys cert-manager, applies overlays, and triggers post-deployment smoke tests.

---

## 6. Logging and Monitoring Setup Guide

### 6.1 Checking Pod Logs
Since the containerized Spring Boot microservice logs directly to standard output (standard logback console appender), you can inspect runtime logs using `kubectl`:
```bash
# Retrieve logs from catalogue pods in a specific version namespace
kubectl logs -n catalogue-v2 -l app=catalogue --tail=100 -f
```

### 6.2 Monitoring Cluster and Pod Metrics
1. **Minikube Dashboard:**
   Enable and open the built-in GUI dashboard to inspect CPU, memory usage, and workloads:
   ```bash
   minikube dashboard
   ```
2. **Metrics Server:**
   The cluster is provisioned with `metrics-server` (enabled via Terraform/Minikube addon). You can view resource usage directly in the terminal:
   ```bash
   # Check resource utilization of nodes
   kubectl top node
   
   # Check resource utilization of catalogue pods across all namespaces
   kubectl top pod -A -l app=catalogue
   ```
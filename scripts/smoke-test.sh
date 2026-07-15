#!/usr/bin/env bash
set -euo pipefail

# Wait for ingress controller to be ready
echo "Waiting for NGINX Ingress controller pods to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

# Wait for our versioned deployments to be fully ready
echo "Waiting for version deployments to be ready..."
kubectl wait --namespace catalogue-v1 --for=condition=available deployment/catalogue-deployment --timeout=80s
kubectl wait --namespace catalogue-v1-1 --for=condition=available deployment/catalogue-deployment --timeout=80s
kubectl wait --namespace catalogue-v2 --for=condition=available deployment/catalogue-deployment --timeout=80s

# Wait for cert-manager certificates to be issued
echo "Waiting for cert-manager SSL certificates to be ready..."
kubectl wait --namespace catalogue-v1 --for=condition=Ready certificate/catalogue-tls-cert --timeout=60s
kubectl wait --namespace catalogue-v1-1 --for=condition=Ready certificate/catalogue-tls-cert --timeout=60s
kubectl wait --namespace catalogue-v2 --for=condition=Ready certificate/catalogue-tls-cert --timeout=60s

# Get Minikube IP
INGRESS_HOST=$(minikube ip)
echo "Ingress is available on IP: ${INGRESS_HOST}"

max_retries=15
delay=3

run_smoke_test() {
  local path=$1
  local expected_status=$2
  local expected_string=$3

  echo -n "Testing https://catalogue.local${path} ... "
  for ((i=1; i<=max_retries; i++)); do
    response=$(curl -s -k --resolve "catalogue.local:443:${INGRESS_HOST}" -w "%{http_code}" "https://catalogue.local${path}")
    http_code="${response: -3}"
    body="${response:0:${#response}-3}"

    if [ "$http_code" -eq "$expected_status" ] && [[ "$body" == *"$expected_string"* ]]; then
      echo "SUCCESS (HTTP $http_code)"
      return 0
    fi
    echo -n "."
    sleep $delay
  done

  echo "FAILED (HTTP $http_code, Body: $body)"
  return 1
}

# Run tests
echo "Starting smoke tests against Spring Boot TLS ingress..."

run_smoke_test "/v1/health" 200 '"version":"1.0"'
run_smoke_test "/v1/products" 200 '[]'
run_smoke_test "/v1/products/search?q=mouse" 404 '"error":"Not Found"'

# Seed a product in v1.1
echo "Seeding test product in v1.1..."
curl -s -k -X POST -H "Content-Type: application/json" \
  -d '{"name":"Mechanical Keyboard","quantity":5,"price":89.99}' \
  --resolve "catalogue.local:443:${INGRESS_HOST}" \
  https://catalogue.local/v1.1/addProduct > /dev/null

run_smoke_test "/v1.1/health" 200 '"version":"1.1"'
run_smoke_test "/v1.1/products/search?q=keyboard" 200 'Mechanical Keyboard'

# Seed a product in v2.0
echo "Seeding test product in v2.0..."
curl -s -k -X POST -H "Content-Type: application/json" \
  -d '{"name":"Wireless Mouse","quantity":10,"price":29.99}' \
  --resolve "catalogue.local:443:${INGRESS_HOST}" \
  https://catalogue.local/v2/addProduct > /dev/null

run_smoke_test "/v2/health" 200 '"version":"2.0"'
run_smoke_test "/v2/products/search?q=Mouse&page=1&limit=2" 200 '"total":1'

# Verify v2.0 structured error formatting
run_smoke_test "/v2/products/search?page=-1" 400 'BAD_REQUEST'

echo "All Spring Boot TLS smoke tests passed successfully!"

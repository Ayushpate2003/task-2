terraform {
  required_version = ">= 1.0.0"
  required_providers {
    minikube = {
      source  = "scott-the-programmer/minikube"
      version = "0.3.5"
    }
  }
}

provider "minikube" {
}

resource "minikube_cluster" "docker" {
  cluster_name = var.cluster_name
  driver       = var.minikube_driver
  nodes        = 1
  cpus         = 2
  memory       = "4096mb"
  addons = [
    "ingress",
    "dashboard",
    "metrics-server"
  ]
}

variable "cluster_name" {
  description = "The name of the minikube cluster"
  type        = string
  default     = "product-catalogue-cluster"
}

variable "minikube_driver" {
  description = "The driver to run the minikube cluster"
  type        = string
  default     = "docker"
}

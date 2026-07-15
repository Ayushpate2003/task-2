output "minikube_ip" {
  description = "The IP address of the provisioned minikube cluster"
  value       = minikube_cluster.docker.primary_address
}

output "cluster_name" {
  description = "The name of the provisioned minikube cluster"
  value       = minikube_cluster.docker.cluster_name
}

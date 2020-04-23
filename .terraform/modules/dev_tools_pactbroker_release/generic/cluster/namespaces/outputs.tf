output "tools_namespace_name" {
  value       = var.tools_namespace
  description = "Namespace where development tools will be deployed"
  depends_on  = [kubernetes_namespace.tools]
}

output "release_namespaces" {
  value       = var.release_namespaces
  description = "Namespaces where applications will be deployed"
  depends_on  = [kubernetes_namespace.releases]
}

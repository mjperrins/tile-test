locals {
  short_name         = "cloudant"
  name_prefix        = var.name_prefix != "" ? var.name_prefix : var.resource_group_name
  service_name       = "${replace(local.name_prefix, "/[^a-zA-Z0-9_\\-\\.]/", "")}-${local.short_name}"
  service_class      = "cloudantnosqldb"
  binding_name       = "binding-${local.short_name}"
  binding_namespaces = jsonencode(var.namespaces)
  role               = "Manager"
}

resource "null_resource" "deploy_cloudant" {
  triggers = {
    service_name      = local.service_name
    service_namespace = var.service_namespace
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/deploy-service.sh ${self.triggers.service_name} ${self.triggers.service_namespace} ${var.plan} ${local.service_class} ${local.binding_name} ${local.binding_namespaces}"

    environment={
      KUBECONFIG = var.cluster_config_file
      RESOURCE_GROUP = var.resource_group_name
      REGION         = var.resource_location
      TMP_DIR        = "${path.cwd}/.tmp"
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/scripts/destroy-service.sh ${self.triggers.service_name} ${self.triggers.service_namespace}"
  }
}

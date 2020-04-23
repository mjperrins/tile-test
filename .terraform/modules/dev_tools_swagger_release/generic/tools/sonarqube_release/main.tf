provider "null" {
}

locals {
  tmp_dir         = "${path.cwd}/.tmp"
  ingress_host    = "${var.hostname}.${var.cluster_ingress_hostname}"
  ingress_url     = "http://${local.ingress_host}"
  secret_name     = "sonarqube-access"
  config_name     = "sonarqube-config"
}

resource "null_resource" "sonarqube_release" {
  triggers = {
    kubeconfig_iks     = var.cluster_config_file
    releases_namespace = var.releases_namespace
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/deploy-sonarqube.sh ${self.triggers.releases_namespace} ${local.ingress_host} ${var.helm_version} ${var.service_account_name} ${var.volume_capacity} \"${jsonencode(var.plugins)}\""

    environment = {
      KUBECONFIG    = self.triggers.kubeconfig_iks
      TMP_DIR           = local.tmp_dir
      CLUSTER_TYPE      = var.cluster_type
      TLS_SECRET_NAME   = var.tls_secret_name
      STORAGE_CLASS     = var.storage_class
      DATABASE_HOST     = var.postgresql.hostname
      DATABASE_PORT     = var.postgresql.port
      DATABASE_NAME     = var.postgresql.database_name
      DATABASE_USERNAME = var.postgresql.username
      DATABASE_PASSWORD = var.postgresql.password
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/scripts/destroy-sonarqube.sh ${self.triggers.releases_namespace}"

    environment = {
      KUBECONFIG = self.triggers.kubeconfig_iks
    }
  }
}

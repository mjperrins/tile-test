
variable "cluster_config_file" {
  type        = string
  description = "Cluster config file for Kubernetes cluster."
}

variable "releases_namespace" {
  type        = string
  description = "Name of the existing namespace where the Helm Releases will be deployed."
}

variable "cluster_ingress_hostname" {
  type        = string
  description = "Ingress hostname of the IKS cluster."
}

variable "hostname" {
  type        = string
  description = "The hostname that will be used for the ingress/route"
  default     = "sonarqube"
}

variable "cluster_type" {
  description = "The cluster type (openshift or ocp3 or ocp4 or kubernetes)"
}

variable "helm_version" {
  description = "The version of the helm chart that should be used"
  type        = string
  default     = "4.4.0"
}

variable "service_account_name" {
  description = "The name of the service account that should be used for the deployment"
  type        = string
  default     = "default"
}

variable "plugins" {
  description = "The list of plugins that will be installed on SonarQube"
  type        = list(string)
  default     = [
    "https://binaries.sonarsource.com/Distribution/sonar-typescript-plugin/sonar-typescript-plugin-1.9.0.3766.jar",
    "https://binaries.sonarsource.com/Distribution/sonar-java-plugin/sonar-java-plugin-5.14.0.18788.jar",
    "https://github.com/checkstyle/sonar-checkstyle/releases/download/4.21/checkstyle-sonar-plugin-4.21.jar",
    "https://binaries.sonarsource.com/Distribution/sonar-javascript-plugin/sonar-javascript-plugin-5.2.1.7778.jar",
    "https://binaries.sonarsource.com/Distribution/sonar-python-plugin/sonar-python-plugin-1.14.1.3143.jar",
    "https://binaries.sonarsource.com/Distribution/sonar-go-plugin/sonar-go-plugin-1.6.0.719.jar"
  ]
}

variable "tls_secret_name" {
  type        = string
  description = "The secret containing the tls certificates"
  default = ""
}

variable "volume_capacity" {
  type        = string
  description = "The volume capacity of the persistence volume claim"
  default     = "2Gi"
}

variable "storage_class" {
  type        = string
  description = "The storage class of the persistence volume claim"
  default     = "ibmc-file-gold"
}

variable "postgresql" {
  type = object({
    username      = string
    password      = string
    hostname      = string
    port          = string
    database_name = string
  })
  description = "Properties for an existing postgresql database"
  default     = {
    username      = ""
    password      = ""
    hostname      = ""
    port          = ""
    database_name = ""
  }
}

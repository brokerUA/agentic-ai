variable "cluster_name" {
  description = "Cluster Name"
  type        = string
  default     = "andreev-agentic-ai"
}

variable "oci_registry" {
  description = "OCI registry base URL"
  type        = string
  default     = "oci://ghcr.io/brokerua/agentic-ai"
}

variable "releases_version" {
  description = "Default tag for releases OCI artifact bootstrap"
  type        = string
  default     = "0.1.0"
}

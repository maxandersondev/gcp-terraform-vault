# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These parameters must be supplied when consuming this module.
# ---------------------------------------------------------------------------------------------------------------------

variable "gcp_project_id" {
  description = "The name of the GCP Project where all resources will be launched."
  type        = string
}

variable "gcp_region" {
  description = "The region in which all GCP resources will be launched."
  type        = string
}

variable "encrypt_key" {
  description = "Consul encryption key, run: consul keygen"
  type        = string
}

variable "key_ring" {
  description = "Vault kms unseal key"
  type        = string
}
  
variable "crypto_key" {
  description = "Vault crypto unseal key"
  type        = string
}

variable "keyring_location" {
  description = "Vault crypto unseal key"
  type        = string
}

variable "service_acct_email" {
  description = "Service account email"
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "network_project_id" {
  description = "The name of the GCP Project where the network is located. Useful when using networks shared between projects. If empty, var.gcp_project_id will be used."
  type        = string
  default     = null
}

variable "consul_server_cluster_size" {
  description = "The number of nodes to have in the Consul Server cluster. We strongly recommended that you use either 3 or 5."
  type        = number
  default     = 3
}

variable "consul_version" {
  description = "Version of consul we intend on using"
  type        = string
  default     = "1.7.3"
}

variable "vault_version" {
  description = "Version of vault we intend on using"
  type        = string
  default     = "1.4.2"
}

variable "data_center" {
  description = "Datacenter declaration"
  type        = string
  default     = "dc1"
}

variable "consul_join_tag" {
  description = "Tag to dynamically join nodes"
  type        = string
  default     = "consul-cluster-node"
}

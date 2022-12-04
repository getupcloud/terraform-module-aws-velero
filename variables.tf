variable "cluster_name" {
  description = "Cluster name"
  type        = string
}

variable "customer_name" {
  description = "Customer name"
  type        = string
}

variable "cluster_oidc_issuer_url" {
  description = "URL of the OIDC Provider from the EKS cluster"
  type        = string
}

variable "service_account_namespace" {
  description = "Namespace of ServiceAccount for cert-manager"
  default     = "cert-manager"
}

variable "service_account_name" {
  description = "ServiceAccount name for cert-manager"
  default     = "cert-manager"
}

variable "tags" {
  description = "AWS tags to apply to resources"
  type        = any
  default     = {}
}

variable "bucket_name" {
  description = "Bucket name. Auto-generated if empty."
  type        = string
  default     = ""
}

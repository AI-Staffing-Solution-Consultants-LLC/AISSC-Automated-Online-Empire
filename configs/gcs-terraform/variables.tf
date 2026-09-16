# ==============================================================================
# AISSC Automated Online Empire - Terraform Variable Declarations
# ==============================================================================
# Blueprint Origin: configs/gcs-terraform/variables.tf
# ==============================================================================

variable "project_id" {
  type        = string
  description = "The target Google Cloud Project ID"
  default     = "suad-claw-nexus-hybrid-01"
}

variable "region" {
  type        = string
  description = "The target GCP Regional zone"
  default     = "us-central1"
}

variable "bucket_name" {
  type        = string
  description = "Central persistent shared memory store bucket name"
  default     = "aissc-persistent-memory-store"
}

variable "krieger_service_account" {
  type        = string
  description = "Systems Tech division service account email"
  default     = "krieger-tech-systems@suad-claw-nexus-hybrid-01.iam.gserviceaccount.com"
}

variable "sheryl_service_account" {
  type        = string
  description = "Chief Temporal Gateway division service account email"
  default     = "sheryl-gateway@suad-claw-nexus-hybrid-01.iam.gserviceaccount.com"
}

variable "malory_service_account" {
  type        = string
  description = "Business Operations division service account email"
  default     = "malory-business-ops@suad-claw-nexus-hybrid-01.iam.gserviceaccount.com"
}

variable "pam_service_account" {
  type        = string
  description = "Workforce Dispatch division service account email"
  default     = "pam-workforce@suad-claw-nexus-hybrid-01.iam.gserviceaccount.com"
}

variable "gcp_project_id" {
  type        = string
  description = "Target Google Cloud Project ID"
}

variable "gcp_region" {
  type        = string
  description = "Deployment region for Cloud Run, Cloud Tasks, and Pub/Sub"
  default     = "us-east4"
}

variable "suad_image" {
  type        = string
  description = "Container image for the SUAD stateless worker. Defaults to the project-local Artifact Registry image."
  default     = ""
}
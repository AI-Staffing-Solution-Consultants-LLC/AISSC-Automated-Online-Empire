# ==============================================================================
# AISSC Automated Online Empire - Terraform Output Declarations
# ==============================================================================
# Blueprint Origin: configs/gcs-terraform/outputs.tf
# ==============================================================================

output "bucket_name" {
  value       = google_storage_bucket.persistent_memory_store.name
  description = "Name of the created GCS persistent memory store bucket"
}

output "bucket_url" {
  value       = google_storage_bucket.persistent_memory_store.url
  description = "gs:// URL of the created storage bucket"
}

output "bucket_self_link" {
  value       = google_storage_bucket.persistent_memory_store.self_link
  description = "URI link to the storage bucket resource"
}

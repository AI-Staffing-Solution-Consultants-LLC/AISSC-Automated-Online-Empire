output "openviking_bucket" {
  description = "Name of the OpenViking RAG GCS bucket (Thought Layer persistent memory)"
  value       = google_storage_bucket.openviking_rag.name
}

output "suad_service_url" {
  description = "URL of the scale-to-zero SUAD Cloud Run service"
  value       = google_cloud_run_v2_service.suad_service.uri
}

output "command_bus_queue" {
  description = "Fully-qualified Cloud Tasks command bus queue name"
  value       = google_cloud_tasks_queue.command_bus.name
}

output "event_bus_topic" {
  description = "Pub/Sub event bus topic ID"
  value       = google_pubsub_topic.event_bus.name
}

output "krieger_sa_email" {
  description = "Krieger Tech Systems service account email (OIDC machine identity)"
  value       = google_service_account.krieger_sa.email
}
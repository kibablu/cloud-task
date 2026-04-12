resource "google_monitoring_notification_channel" "email_admin" {
  display_name = "Email Admin for n8n Alerts"
  type         = "email"
  labels = {
    email_address = "your_email@gmail.com"
  }
}

# Memory Usage Alert Policy
resource "google_monitoring_alert_policy" "sql_memory_alert" {
  display_name = "Cloud SQL Memory Utilization Alert"
  combiner     = "OR"
  conditions {
    display_name = "Memory Utilization > 90%"
    condition_threshold {
      filter     = "resource.type = \"cloudsql_database\" AND metric.type = \"cloudsql.googleapis.com/database/memory/utilization\" AND resource.labels.database_id = \"${var.project_id}:${google_sql_database_instance.n8n_db.name}\""
      duration   = "300s"
      comparison = "COMPARISON_GT"
      threshold_value = 0.9
      
      trigger {
        count = 1
      }

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email_admin.name]

  documentation {
    content   = "The n8n database (${google_sql_database_instance.n8n_db.name}) is running low on memory. Consider upgrading the tier or checking for heavy n8n workflows."
    mime_type = "text/markdown"
  }
}

# Cloud Run High Instance Count Alert (Scaling Bottleneck)
resource "google_monitoring_alert_policy" "n8n_scaling_alert" {
  display_name = "n8n Cloud Run at Max Scaling"
  combiner     = "OR"
  conditions {
    display_name = "Active Instances >= 5"
    condition_threshold {
      filter     = "resource.type = \"cloud_run_revision\" AND metric.type = \"run.googleapis.com/container/instance_count\" AND resource.labels.service_name = \"${google_cloud_run_v2_service.n8n.name}\" AND metadata.system_labels.state = \"active\""
      duration   = "120s" 
      comparison = "COMPARISON_GT"
      threshold_value = 4.9 

      trigger {
        count = 1
      }

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MAX"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email_admin.name]

  documentation {
    content   = "The n8n service is hitting its maximum scale of 5 instances. This often happens during 'Cold Start' loops or when the Database is too slow to respond, causing requests to pile up."
    mime_type = "text/markdown"
  }
}

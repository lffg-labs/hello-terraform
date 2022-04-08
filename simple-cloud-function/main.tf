variable "google_project" {}

provider "google" {
  project = var.google_project
  region  = "us-central1"
}

data "archive_file" "source" {
  type       = "zip"
  source_dir = "${path.module}/src"

  # TODO: Aviod filename conflicts here.
  output_path = "${path.module}/generated/source.zip"
}

resource "google_storage_bucket" "source" {
  name     = "my_second_fn_source"
  location = "us-central1"
}

resource "google_storage_bucket_object" "source" {
  name   = "my_second_fn_source"
  bucket = google_storage_bucket.source.name
  source = data.archive_file.source.output_path
}

resource "google_cloudfunctions_function" "my_second_fn" {
  name = "my_second_fn"

  entry_point = "myFirstFn"
  runtime     = "nodejs16"

  # TODO: Maybe add integrity check?
  #       After the bucket is created? Or after the object is created?
  source_archive_bucket = google_storage_bucket.source.name
  source_archive_object = google_storage_bucket_object.source.name

  trigger_http     = true
  ingress_settings = "ALLOW_ALL"

  available_memory_mb = 128
  timeout             = 60
}

output "fn_trigger_url" {
  value = google_cloudfunctions_function.my_second_fn.https_trigger_url
}

resource "google_cloudfunctions_function_iam_member" "my_second_fn_iam" {
  cloud_function = google_cloudfunctions_function.my_second_fn.name
  member         = "allUsers"
  role           = "roles/cloudfunctions.invoker"
}

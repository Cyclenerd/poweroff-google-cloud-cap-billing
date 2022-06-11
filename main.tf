# Copyright 2022 Nils Knieling
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

###############################################################################
# MAIN
###############################################################################

# Provider for lifecycle management of GCP resources
# https://registry.terraform.io/providers/hashicorp/google/latest
provider "google" {
  region                = var.region
  user_project_override = true
  project               = var.project_id
  billing_project       = var.project_id
}

###############################################################################
# GET DATA
###############################################################################

# Project
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project
data "google_project" "my-project" {
  project_id = var.project_id
}

# Billing account
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/billing_account
data "google_billing_account" "my-billing-account" {
  billing_account = data.google_project.my-project.billing_account
  depends_on      = [data.google_project.my-project]
}

###############################################################################
# SERVICE ACCOUNT for Cloud Function to cap the billing account
###############################################################################

# Create service account
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account
resource "google_service_account" "my-cap-billing-service-account" {
  project      = var.project_id
  account_id   = "sa-cap-billing"
  display_name = "Cap Billing"
  description  = "Service Account to unlink project from billing account"
}

# Sleep and wait for service account
# https://github.com/hashicorp/terraform/issues/17726#issuecomment-377357866
resource "null_resource" "wait-for-sa" {
  provisioner "local-exec" {
    command = "sleep 30"
  }
  depends_on = [google_service_account.my-cap-billing-service-account]
}

# Create custom role
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_iam_custom_role
# https://cloud.google.com/billing/docs/how-to/modify-project#disable_billing_for_a_project
resource "google_project_iam_custom_role" "my-cap-billing-role" {
  project = var.project_id
  # Camel case role id to use for this role. Cannot contain - character.
  role_id     = "myCapBilling"
  title       = "Cap Billing Custom Role"
  description = "Custom role to unlink project from billing account"
  stage       = "GA"
  permissions = [
    "resourcemanager.projects.deleteBillingAssignment"
  ]
}

# Updates the IAM policy to grant a role to service account. Other members for the role for the project are preserved.
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_iam
resource "google_project_iam_member" "my-cap-billing-role-binding" {
  project    = var.project_id
  role       = google_project_iam_custom_role.my-cap-billing-role.name #roles/billing.projectManager
  member     = "serviceAccount:${google_service_account.my-cap-billing-service-account.email}"
  depends_on = [google_project_iam_custom_role.my-cap-billing-role, null_resource.wait-for-sa]
}

###############################################################################
# PUB/SUB TOPIC for BUDGET ALERT
###############################################################################

# Create Pub/Sub topic
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic
resource "google_pubsub_topic" "my-cap-billing-pubsub" {
  project = var.project_id
  name    = var.pubsub_topic
  message_storage_policy {
    allowed_persistence_regions = ["${var.region}"]
  }
  labels = {
    "terraform" = "true"
  }
}

# Create Pub/Sub subscription to have the possibility to read (pull) the messages via the console (dashboard)
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_subscription
resource "google_pubsub_subscription" "my-cap-billing-pubsub-pull" {
  project    = var.project_id
  name       = "${var.pubsub_topic}-pull"
  topic      = google_pubsub_topic.my-cap-billing-pubsub.name
  depends_on = [google_pubsub_topic.my-cap-billing-pubsub]
}

###############################################################################
# BUDGET ALERT for BILLING ACCOUNT
###############################################################################

# Create budget alert
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/billing_budget
resource "google_billing_budget" "my-cap-billing-budget" {
  billing_account = data.google_billing_account.my-billing-account.id
  display_name    = "Unlink ${var.project_id} from billing account"

  amount {
    specified_amount {
      units = var.target_amount
    }
  }

  threshold_rules {
    spend_basis       = "CURRENT_SPEND"
    threshold_percent = 1.0
  }

  budget_filter {
    projects               = ["projects/${data.google_project.my-project.number}"]
    credit_types_treatment = "INCLUDE_ALL_CREDITS"
  }

  all_updates_rule {
    # Budget alert acts as 'billing-budget-alert@system.gserviceaccount.com' and is automatically added to pub/sub topic
    pubsub_topic = google_pubsub_topic.my-cap-billing-pubsub.id
    # Must be false, otherwise it does not work
    disable_default_iam_recipients = false
  }

  depends_on = [google_pubsub_topic.my-cap-billing-pubsub]
}

###############################################################################
# BUCKET and SOURCE CODE for CLOUD FUNCTION
###############################################################################

# Generate random UUID for bucket
resource "random_uuid" "my-cap-billing-bucket" {
}

# Create bucket for Cloud Function source code
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket
resource "google_storage_bucket" "my-cap-billing-bucket" {
  name                        = random_uuid.my-cap-billing-bucket.id
  project                     = var.project_id
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true
  labels = {
    "terraform" = "true"
  }
}

# Create ZIP with source code for GCF
# https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/archive_file
data "archive_file" "my-cap-billing-source" {
  type = "zip"
  source {
    content  = file("${path.module}/function-source/main.py")
    filename = "main.py"
  }
  source {
    content  = file("${path.module}/function-source/requirements.txt")
    filename = "requirements.txt"
  }
  output_path = "${path.module}/function-source.zip"
}

# Copy source code as ZIP into bucket
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_object
resource "google_storage_bucket_object" "my-cap-billing-archive" {
  name   = "function-source-${data.archive_file.my-cap-billing-source.output_md5}.zip"
  bucket = google_storage_bucket.my-cap-billing-bucket.name
  source = data.archive_file.my-cap-billing-source.output_path
  depends_on = [
    google_storage_bucket.my-cap-billing-bucket,
    data.archive_file.my-cap-billing-source
  ]
}

###############################################################################
# CLOUD FUNCTION
###############################################################################

# Sleep and wait for service account
# https://github.com/hashicorp/terraform/issues/17726#issuecomment-377357866
resource "null_resource" "wait-for-archive" {
  provisioner "local-exec" {
    command = "sleep 30"
  }
  depends_on = [google_storage_bucket_object.my-cap-billing-archive]
}

# Generate random id for GCF name
resource "random_id" "my-cap-billing-function" {
  byte_length = 8
}

# Create Cloud Function with Pub/Sub event trigger
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloudfunctions_function
resource "google_cloudfunctions_function" "my-cap-billing-function" {
  name        = "cap-billing-${random_id.my-cap-billing-function.hex}"
  description = "Function to unlink project from billing account"
  project     = var.project_id
  region      = var.region
  # Runtime ID
  # https://cloud.google.com/functions/docs/concepts/exec#runtimes
  runtime = "python39"
  # Service account to run the function with
  service_account_email = google_service_account.my-cap-billing-service-account.email
  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.my-cap-billing-bucket.name
  source_archive_object = google_storage_bucket_object.my-cap-billing-archive.name
  entry_point           = "stop_billing"
  timeout               = 120
  min_instances         = 0
  max_instances         = 1
  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.my-cap-billing-pubsub.name
    failure_policy {
      retry = false
    }
  }
  labels = {
    terraform = "true"
  }
  environment_variables = {
    MY_BUDGET_ALERT_ID = "${google_billing_budget.my-cap-billing-budget.id}"
  }
  depends_on = [
    google_pubsub_topic.my-cap-billing-pubsub,
    null_resource.wait-for-archive
  ]
}
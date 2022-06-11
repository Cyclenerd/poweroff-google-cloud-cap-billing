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
# VARIABLES
###############################################################################

variable "project_id" {
  type        = string
  nullable    = false
  description = "The project ID for the resources"
  # https://cloud.google.com/resource-manager/docs/creating-managing-projects#before_you_begin
  validation {
    # Must be 6 to 30 characters in length.
    # Can only contain lowercase letters, numbers, and hyphens.
    # Must start with a letter.
    # Cannot end with a hyphen.
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "Invalid project ID!"
  }
}

variable "pubsub_topic" {
  type        = string
  nullable    = false
  description = "Name of the Pub/Sub topic"
  default     = "cap-billing-alert"
}

variable "target_amount" {
  type        = number
  nullable    = false
  description = "Set maximum monthly budget amount (currency as in billing account)"
  default     = "1000"
  validation {
    # https://cloud.google.com/billing/docs/reference/budget/rest/v1/billingAccounts.budgets#BudgetAmount
    condition     = can(regex("^[0-9]+$", var.target_amount))
    error_message = "Specify amount as 64-bit signed integer (1 - 10000000..)!"
  }
}

variable "region" {
  type     = string
  nullable = false
  description = "Region for the resources"
  default  = "us-central1"
}
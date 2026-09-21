# Copyright 2022-2026 Nils Knieling
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
# VERSIONS
###############################################################################

terraform {
  required_version = ">= 1.12.2"
  required_providers {
    google = {
      # https://registry.terraform.io/providers/hashicorp/google/latest/docs
      source  = "hashicorp/google"
      version = ">= 8.3.0"
    }
    null = {
      # https://registry.terraform.io/providers/hashicorp/null/latest
      source  = "hashicorp/null"
      version = ">= 3.3.2"
    }
    random = {
      # https://registry.terraform.io/providers/hashicorp/random/latest
      source  = "hashicorp/random"
      version = ">= 3.9.1"
    }
    archive = {
      # https://registry.terraform.io/providers/hashicorp/archive/latest
      source  = "hashicorp/archive"
      version = ">= 2.8.1"
    }
  }
}
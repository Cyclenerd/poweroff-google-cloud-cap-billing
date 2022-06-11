#!/usr/bin/env bash

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
# CHECK PROJECT
###############################################################################

MY_GOOGLE_CLOUD_PROJECT=$(gcloud config list --format 'value(core.project)' 2>/dev/null)
if [[ "$MY_GOOGLE_CLOUD_PROJECT" =~ ^[a-z][a-z0-9-]{4,28}[a-z0-9]$ ]]; then
    echo "Project ID: $MY_GOOGLE_CLOUD_PROJECT"
    echo
else
    echo "Default project ID '$MY_GOOGLE_CLOUD_PROJECT' not set or invalid!"
    echo "Run: gcloud config set project YOUR_GOOGLE_CLOUD_PROJECT"
    exit 9
fi

###############################################################################
# ENABLE APIs
###############################################################################

MY_GCP_SERVICES=(
	# Service Usage API
    "serviceusage.googleapis.com"
    # Cloud Resource Manager API
    "cloudresourcemanager.googleapis.com"
    # Identity and Access Management (IAM) API
    "iam.googleapis.com"
    # Cloud Billing API
    "cloudbilling.googleapis.com"
    # Cloud Billing Budget API
    "billingbudgets.googleapis.com"
    # Cloud Pub/Sub API
    "pubsub.googleapis.com"
    # Cloud Storage API
    "storage.googleapis.com"
    # Cloud Logging API
    "logging.googleapis.com"
    # Cloud Build API
    "cloudbuild.googleapis.com"
    # Cloud Function API
    "cloudfunctions.googleapis.com"
)

# Enable API
for MY_GCP_SERVICE in "${MY_GCP_SERVICES[@]}"; do
    echo "» Enable service '$MY_GCP_SERVICE'"
    if gcloud services enable "$MY_GCP_SERVICE"; then
        echo "  [x] Successfully activated"
    else
        echo "  [_] Could not activate service"
    fi
done

# Sleep and wait for APIs
MY_SLEEP=0
MY_SLEEP_SEC=30
echo
echo "Sleeping for $MY_SLEEP_SEC seconds…"
echo "Sometimes the last step takes until everything is activated properly."
echo "Therefore, we better wait $MY_SLEEP_SEC seconds to be on the safe side."
while [ "$MY_SLEEP" -le "$MY_SLEEP_SEC" ]
do
    sleep 1
    echo -n "."
    MY_SLEEP=$((MY_SLEEP+1))
done
echo
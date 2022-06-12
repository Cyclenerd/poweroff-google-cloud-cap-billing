# Copyright 2021 Google LLC
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
#

###############################################################################
# This function will remove the billing account associated
# with the project if the cost amount is higher than the budget amount.
#
# Source:
# https://github.com/GoogleCloudPlatform/python-docs-samples
###############################################################################

import base64
import json
import google.auth
from google.cloud import billing

PROJECT_ID = google.auth.default()[1]
cloud_billing_client = billing.CloudBillingClient()


def stop_billing(data: dict, context):
    pubsub_data = base64.b64decode(data["data"]).decode("utf-8")
    print(f"Data: {pubsub_data}")

    pubsub_json = json.loads(pubsub_data)
    cost_amount = pubsub_json["costAmount"]
    budget_amount = pubsub_json["budgetAmount"]

    if cost_amount <= budget_amount:
        print(f"No action necessary. (Current cost: {cost_amount})")
        return

    project_name = cloud_billing_client.common_project_path(PROJECT_ID)
    request = billing.UpdateProjectBillingInfoRequest(
        name=project_name,
        project_billing_info=billing.ProjectBillingInfo(
            billing_account_name=""  # Disable billing
        ),
    )
    project_biling_info = cloud_billing_client.update_project_billing_info(request)
    print(f"Billing disabled: {project_biling_info}")

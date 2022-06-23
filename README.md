# Automatic cost control by capping Google Cloud billing

[![CI](https://github.com/Cyclenerd/poweroff-google-cloud-cap-billing/actions/workflows/ci.yml/badge.svg)](https://github.com/Cyclenerd/poweroff-google-cloud-cap-billing/actions/workflows/ci.yml)
[![GitHub](https://img.shields.io/github/license/cyclenerd/poweroff-google-cloud-cap-billing)](https://github.com/Cyclenerd/poweroff-google-cloud-cap-billing/blob/master/LICENSE)
[![Terraform](https://img.shields.io/badge/IaC-Terraform-blue)](https://cloud.google.com/docs/terraform)
[![Subreddit subscribers](https://img.shields.io/reddit/subreddit-subscribers/googlecloud?label=Google%20Cloud%20Platform&style=social)](https://www.reddit.com/r/googlecloud/comments/va0cc0/automating_cost_control_by_capping_google_cloud/)

With this repo you can cap costs and stop usage for a Google Cloud project by disabling Cloud Billing automatically.
Removing the billing account from a project will cause all Google Cloud services in the project to terminate, including free-tier services.

![Image: Architecture](https://raw.githubusercontent.com/Cyclenerd/poweroff-google-cloud-cap-billing/master/img/stop-billing.jpg)

You might want cap costs because you have a hard limit on how much money you can spend on Google Cloud. This is typical for students, researchers, or developers working in sandbox environments. In these cases you want to stop the spending and might be willing to shutdown all your Google Cloud services and usage when your budget limit is reached.

| ⚠️ Warning |
|-------------|
| When you remove Cloud Billing from your project, all resources are shut down. The resources may not shut down gracefully and be irretrievably deleted. There is no gracefully recovery if you disable Cloud Billing. You can re-enable Cloud Billing, but there is no guarantee that the service will be restored and manual configuration is required. |

Everything is based on the original [Google Cloud documentation](https://cloud.google.com/billing/docs/how-to/notify#cap_disable_billing_to_stop_usage).

This repo has the advantage that everything is deployed automatically thanks to Terraform.
You don't have to set up all the steps each time for additional projects.

It also creates a separate custom role that can only unlink the billing account from the project, but not enable it.
This has the advantage that only a billing administrator can enable the billing back and not the project itself.

**Recommendation:** If you have a hard funds limit, set your maximum budget below your available funds to account for billing delays.

## 🏃 Deploying

Run all tasks in the free Google Cloud Shell.
All necessary tools (`gcloud` and `terraform`) are already installed.

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.png)](https://shell.cloud.google.com/cloudshell/open?shellonly=true&ephemeral=false&cloudshell_git_repo=https://github.com/Cyclenerd/poweroff-google-cloud-cap-billing&cloudshell_git_branch=master&cloudshell_tutorial=cloud-shell-tutorial.md)

Trust repo:

![Screenshot: Cloud Shell trust repo](https://raw.githubusercontent.com/Cyclenerd/poweroff-google-cloud-cap-billing/master/img/trust-repo.jpg)

You need to be the Owner and Billing Account Administrator of the project.

### 1️⃣ Clone

Clone this repo and initial setup:
```bash
git clone https://github.com/Cyclenerd/poweroff-google-cloud-cap-billing.git
cd poweroff-google-cloud-cap-billing
terraform init
```

### 2️⃣ Set Project

Set the project that should be stopped when a certain amount is exceeded:
```bash
gcloud auth login
gcloud config set project YOUR-GOOGLE-CLOUD-PROJECT
```

### 3️⃣ Enable APIs

Enable required APIs and services:
```bash
bash enable-services.sh
```

### 4️⃣ Deploy

Now you can create a budget alert and Cloud Function for this project:
```bash
# Stop billing if 1000 USD are exceeded
terraform apply \
  -var="project_id=$GOOGLE_CLOUD_PROJECT" \
  -var="target_amount=1000"
```

In detail the following is added to the project:

1. Service account : `sa-cap-billing@...`
1. Custom role : `myCapBilling`
1. Pub/Sub topic : `cap-billing-alert`
1. Pub/Sub subscription : `cap-billing-alert-pull`
1. Budget alert : `Unlink YOUR-GOOGLE-CLOUD-PROJECT from billing account`
1. Storage bucket for Cloud Function source code : `RANDOM-UUID`
1. Cloud Function with Pub/Sub event trigger : `cap-billing-RANDOM-HEX`

#### Variables

You can customize the setup with the following Terraform input variables:

| Variable        | Description                                                        | Default           |
|-----------------|--------------------------------------------------------------------|-------------------|
| `project_id`    | The project ID for the resources and budget alert                  |                   |
| `pubsub_topic`  | Name of the Pub/Sub topic                                          | cap-billing-alert |
| `target_amount` | Set maximum monthly budget amount (currency as in billing account) | 1000              |
| `region`        | Region for the resources                                           | us-central1       |

**Examples**

Via command:
```bash
# Stop billing if 5 USD are exceeded and deploy everything in europe-west4
terraform apply \
  -var="project_id=$GOOGLE_CLOUD_PROJECT" \
  -var="target_amount=5" \
  -var="region=europe-west4"
```

Or via config file `terraform.tfvars`:
```text
# Project ID
project_id=bla-fa-123
# Target amount
target_amount=10
# Pub/Sub topic
pubsub_topic=stop-billing-alert
```
Apply with config file:
```bash
terraform apply
```

» [Terraform Help](https://www.terraform.io/language/values/variables)


### 💥 Test

You can perform a test.
The billing account will be removed.
Do it only if you are sure and the project is not important.

Check active billing account:
```bash
gcloud beta billing projects describe "$GOOGLE_CLOUD_PROJECT" | grep billingAccountName
```

Send a message that triggers the Cloud Function and disables billing:
```bash
gcloud pubsub topics publish "cap-billing-alert" --message='{ "costAmount" : 2, "budgetAmount": 1 }'
```

Wait a while... Billing should then be disabled.
```bash
gcloud beta billing projects describe "$GOOGLE_CLOUD_PROJECT" | grep billingAccountName
```

## 💸 Enable Billing

Enable billing for an existing project:

![Screenshot: Enable billing](https://raw.githubusercontent.com/Cyclenerd/poweroff-google-cloud-cap-billing/master/img/enable-billing.jpg?v1)

» [Google documentation](https://cloud.google.com/billing/docs/how-to/modify-project#enable_billing_for_an_existing_project)

## 📎 Prerequisites

To run the commands described in this repo, you need the following:

1. Install the [Google Cloud SDK](https://cloud.google.com/sdk/install) version 319.0.0 or later
1. Install [Terraform](https://www.terraform.io/downloads.html) version 1.1.9 or later.
1. Set up a Google Cloud
   [billing account](https://cloud.google.com/billing/docs/how-to/manage-billing-account) and project.

## ❤️ Contributing

Have a patch that will benefit this project?
Awesome! Follow these steps to have it accepted.

1. Please read [how to contribute](CONTRIBUTING.md).
1. Fork this Git repository and make your changes.
1. Create a Pull Request.
1. Incorporate review feedback to your changes.
1. Accepted!


## 📜 License

All files in this repository are under the [Apache License, Version 2.0](LICENSE) unless noted otherwise.

Please note:

* No warranty
* No official Google product
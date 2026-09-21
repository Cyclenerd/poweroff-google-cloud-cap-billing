# Cap Billing

## Welcome 👋!

In this tutorial, you are going to set up a [automatic cost control by capping Google Cloud billing](https://github.com/Cyclenerd/poweroff-google-cloud-cap-billing).

<walkthrough-tutorial-duration duration="5"></walkthrough-tutorial-duration>

| ⚠️ Warning |
|-------------|
| When you remove Cloud Billing from your project, all resources are shut down. The resources may not shut down gracefully and be irretrievably deleted. There is no gracefully recovery if you disable Cloud Billing. You can re-enable Cloud Billing, but there is no guarantee that the service will be restored and manual configuration is required. |

Click the **Start** button to move to the next step.

## Project Setup

Select or create a project:

<walkthrough-project-setup billing=true></walkthrough-project-setup>

Enable the required APIs:

<walkthrough-enable-apis apis="serviceusage.googleapis.com,cloudresourcemanager.googleapis.com,iam.googleapis.com,cloudbilling.googleapis.com,billingbudgets.googleapis.com,pubsub.googleapis.com,storage.googleapis.com,logging.googleapis.com,cloudbuild.googleapis.com,cloudfunctions.googleapis.com"></walkthrough-enable-apis>

## Configure Cloud Shell Environment

Set Google Cloud project ID. Replace with your current Google Cloud project ID:

```bash
export GOOGLE_CLOUD_PROJECT="<walkthrough-project-id/>"
gcloud config set project "$GOOGLE_CLOUD_PROJECT"
```

## Init

Initial setup:
```bash
terraform init
```

## Deploy

Now you can create a budget alert and Cloud Function.
The required Google Cloud APIs and services are enabled automatically by Terraform
before any other resources are created:
```bash
terraform apply \
  -var="project_id=$GOOGLE_CLOUD_PROJECT" \
  -var="target_amount=1000"
```

## Done

You can now perform a test.
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
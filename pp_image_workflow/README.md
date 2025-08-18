# A4-High (B200) Slurm Cluster Deployment with Custom Image

Derived from https://github.com/GoogleCloudPlatform/cluster-toolkit/tree/main/examples/machine-learning/a4-highgpu-8g.

This repository contains three separate deployments:

 * Create Custom Slurm Image
   * slurm-custom-image-blueprint.yml
   * slurm-custom-image-deploy.yml
 * Launch Slurm Cluster
   * slurm-custom-image-transfer-blueprint.yml
   * slurm-custom-image-transfer-deploy.yml
 * Create Custom Slurm Image and Launch in the Same Project
   * slurm-custom-img-cluster-blueprint.yml
   * slurm-custom-img-cluster-deploy.yml

The deployments can be easily updated to leverage an A4 reservation or other provisioning approach.

*Note*: The custom packages will need to be updated directly in blueprint files; requirements.txt is for reference only.

## Process for Creating Image in Project A and Launching Cluster in Project B

*Note:* You will need to manually update the deploy files to specify the correct project, etc.

Step 1: Create Custom Image in Project A using slurm-custom-image-blueprint.yml and slurm-custom-image-deploy.yml.
```shell
./gcluster deploy -d pp_image_workflow/slurm-custom-image-deploy.yml pp_image_workflow/slurm-custom-image-blueprint.yml --auto-approve
```

Step 2: gcloud command to transfer to Project B
```shell
gcloud compute images create IMAGE_NAME --project=PROJECT_B --family=COPIED_IMAGE_FAMILY_NAME  --source-image=IMAGE_NAME_IN_PROJECT_A --source-image-project=PROJECT_A
```

Step 3: Deploy in Project B using slurm-custom-img-cluster-blueprint.yml and slurm-custom-img-cluster-deploy.yml.
```shell
./gcluster deploy -d pp_image_workflow/slurm-custom-image-transfer-deploy.yml pp_image_workflow/slurm-custom-image-transfer-blueprint.yml --auto-approve
```

## Example Deployment Process in a Single Project
**Reference:**
 * Set up Cluster Toolkit: https://cloud.google.com/cluster-toolkit/docs/setup/configure-environment
  * Ensure you have all necessary packages for Cluster Toolkit
 * Create an AI-optimized Slurm Cluster with A4: https://cloud.google.com/cluster-toolkit/docs/quickstarts/create-a-slurm-cluster-with-a4

**Deployment Steps:**
```shell
export PROJECT_ID=northam-ce-mlai-tpu
export PROJECT_NUMBER=xxx
export REGION=us-central1
export ZONE=us-central1-b
export BUCKET_ID=xxx

# Configuration
gcloud config set project $PROJECT_ID

gcloud iam service-accounts enable \
   --project $PROJECT_ID \
   $PROJECT_NUMBER-compute@developer.gserviceaccount.com

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
    --role=roles/editor

gcloud auth application-default login

gcloud compute project-info add-metadata \
     --metadata enable-oslogin=TRUE

# Create and configure bucket - note this is not required for image deployment only.
gcloud storage buckets create gs://${BUCKET_ID} \
    --project=${PROJECT_ID} \
    --default-storage-class=STANDARD \
    --location=${REGION} \
    --uniform-bucket-level-access

gcloud storage buckets update gs://${BUCKET_ID} --versioning

# Clone forked cluster-toolkit repository and build gcluster
git clone https://github.com/ericehanley/pp2025-b200-cluster-toolkit.git
cd pp2025-b200-cluster-toolkit
make

# Manually update parameters in deployment file and packages in blueprint file as required before deploying.
# Make sure you're using the correct blueprint and deployment files.
./gcluster deploy -d pp_image_workflow/slurm-custom-img-cluster-deploy.yml pp_image_workflow/slurm-custom-img-cluster-blueprint.yml --auto-approve
```

## Cleanup

Slurm filestore cluster will need to have deletion protection disabled for deletion.

```shell
# Remove deletion protection if necessary.
gcloud filestore instances update $FILESTORE_INSTANCE_NAME \
    --no-deletion-protection

# Delete deployment
./gcluster destroy DEPLOYMENT_FOLDER --auto-approve

# Delete bucket if necessary
gcloud storage buckets delete gs://${BUCKET_ID}
```
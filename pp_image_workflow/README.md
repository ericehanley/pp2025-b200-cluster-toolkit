# A4-High Cluster Toolkit with Custom Image
This repository contains two separate deployments:

 * Slurm Custom Image - create custom image with specified packages.
   * slurm-custom-image-blueprint.yml
   * slurm-custom-image-deploy.yml
 * Slurm Custom Image with A4 Cluster - create custom image with specified packages and deploy on single SPOT node a4-highgpu-8g cluster.
   * slurm-custom-img-cluster-blueprint.yml
   * slurm-custom-img-cluster-deploy.yml

The deployments can be easily updated to leverage an A4 reservation or other provisioning approach.

Note - the custom packages will need to be updated directly in blueprint files; requirements.txt is for reference only.

## Example Deployment Process
**Reference:**
 * Set up Cluster Toolkit: https://cloud.google.com/cluster-toolkit/docs/setup/configure-environment
 * Create an AI-optimized Slurm Cluster with A4: https://cloud.google.com/cluster-toolkit/docs/quickstarts/create-a-slurm-cluster-with-a4

**Deployment:**
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


slurm-final-custom-image-please-7e712925

# Delete deployment
./gcluster destroy DEPLOYMENT_FOLDER --auto-approve

# Delete bucket if necessary
gcloud storage buckets delete gs://${BUCKET_ID}
```
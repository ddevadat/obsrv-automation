remote_state {
  backend = "s3"
  config = {
    bucket  = get_env("OCI_TERRAFORM_BACKEND_BUCKET_NAME")
    region  = get_env("OCI_TERRAFORM_BACKEND_BUCKET_REGION")
    endpoint = get_env("OCI_TERRAFORM_BACKEND_BUCKET_ENDPOINT")
    key     = "${path_relative_to_include()}/terraform.tfstate"
    # shared_credentials_file     = "~/.aws/credentials"
        # All S3-specific validations are skipped:
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    force_path_style            = true
  }
}

# inputs = {
#   region                         = "us-east-2"
#   env                            = "dev"
#   building_block                 = "obsrv"
#   kubernetes_storage_class       = "gp2"
#   druid_deepstorage_type         = "s3"
#   flink_checkpoint_store_type    = "s3"
#   dataset_api_container_registry = "sunbird"
#   dataset_api_image_tag          = "1.0.0"
#   flink_container_registry       = "sunbird"
#   flink_image_tag                = "1.0.0"
# }
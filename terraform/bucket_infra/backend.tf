terraform {
  backend "s3" {
    bucket       = "cloud-platform-analytics-backend"
    key          = "bucket_state_key/terraform.tfstate"
    use_lockfile = true
    region       = "us-east-1"
  }
}


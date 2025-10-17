terraform {
  backend "s3" {
    bucket       = "cloud-platform-analytics-backend"
    key          = "main_infra_state_key/terraform.tfstate"
    use_lockfile = true
    region       = "us-east-1"
  }
}


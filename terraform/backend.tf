terraform {
  backend "s3" {
    bucket       = "capstone-tfstate-320408143639"
    key          = "capstone/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

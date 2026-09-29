terraform {
  backend "s3" {
    bucket       = "innovatech-cs1-terraform-state-tc5194202"
    key          = "cs1/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}
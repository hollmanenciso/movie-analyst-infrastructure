terraform {
  backend "s3" {
    bucket = "hollmanrampupstate"
    key    = "ramp-up/terraform.tfstate"
    region = "us-east-1"
  }
}

terraform {
  backend "s3" {
    bucket = "hollmanrampupstate"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

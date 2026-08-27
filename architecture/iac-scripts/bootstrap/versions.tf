terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Deliberately no backend block here: this config creates the S3
  # bucket + DynamoDB table that everything else uses as its remote
  # backend, so it can't depend on that backend existing yet. Its own
  # state stays local — see the bootstrap README for details.
}

provider "aws" {
  region = "ap-southeast-4"
}

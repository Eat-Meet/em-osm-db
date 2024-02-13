terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.36.0"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "1.21.0"
    }
  }

  backend "s3" {
    bucket         = "em-osm-tf-state"
    key            = "state/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "em-osm-tf-state-lock"
    encrypt        = true
  }
}


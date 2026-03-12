terraform {
  backend "s3" {
    bucket         = "freelight-tofu-state"
    key            = "aws/freelight.tfstate"
    region         = "us-west-1"
    dynamodb_table = "freelight-tofu-lock"
    encrypt        = true
  }
}

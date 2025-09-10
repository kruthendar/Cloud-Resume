terraform {
  backend "s3" {
    bucket         = "cloud-resume-tfstate-kruthendar"  # match STATE_BUCKET
    key            = "infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
terraform {
  backend "s3" {
    bucket         = "cloud-resume-tfstate-kruthendar"
    key            = "infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type    = string
  default = "cloud-resume"
}

variable "table_name" {
  type    = string
  default = "cloud-resume-counter"
}

variable "partition_key" {
  type    = string
  default = "pk"
}

variable "partition_value" {
  type    = string
  default = "visitors"
}

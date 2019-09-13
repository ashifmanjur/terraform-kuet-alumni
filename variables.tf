variable "project" {
  type = string
}

variable "credentials_file" {
  type = string
}

variable "region" {
  type = string
  default = "us-central1"
}

variable "zone" {
  type = string
  default = "us-central1-b"
}

variable "environment" {
  type = string
  default = "dev"
}

variable "machine_types" {
  type = "map"
  default = {
    "dev" = "f1-micro"
    "test" = "n1-highcpu-32"
    "prod" = "n1-highcpu-32"
  }
}
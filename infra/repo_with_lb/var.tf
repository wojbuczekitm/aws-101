variable "resource_prefix" {
  default = "wb"
  type    = string
}

variable "instance_type" {
  default = "t2.micro"
}

variable "amis" {
  default = {
    eu-central-1 = "ami-029c5088a566b385e"
  }
}

variable "bucket" {
  default = "wb-code-bucket"
  type    = string
}

variable "bucket_key" {
  default = "tf/terraform.tfstate"
  type    = string
}

variable "region" {
  default = "eu-central-1"
  type    = string
}

variable "ASPNETCORE_ENVIRONMENT" {
  default = "Production"
  type    = string
}

variable "ASPNETCORE_URLS" {
  default = "http://+:80"
  # default = "https://+:443;http://+:80"
  type = string
}

variable "cert_arn" {
  default = "arn:aws:acm:eu-central-1:836906079004:certificate/db49f142-bfe8-4713-a74a-4ef22a5dda72"
}

variable "http_host_port" {
  default = 80
  type    = number
}

variable "http_container_port" {
  default = 80
  type    = number
}

variable "https_host_port" {
  default = 443
  type    = number
}

variable "https_container_port" {
  default = 443
  type    = number
}

variable "vpc_id" {
  default = "vpc-0fead40e24304ce5f"
  type    = string
}

variable "subnets" {
  default = ["subnet-0c5ab4a1499db9f85", "subnet-02340f0b7f49f6ea8", "subnet-020c346673e0afe4f"]
  type    = list(string)
}

variable "app_count" {
  default = 1
}

variable "health_check_path" {
  default = "/"
}

variable "cpu" {
  default = 256
}

variable "memory" {
  default = 512
}

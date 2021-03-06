variable "resource_prefix" {
  default = "wb"
  type    = string
}

variable "repository_url" {
  default = "836906079004.dkr.ecr.eu-central-1.amazonaws.com/wb-repository"
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

variable "region" {
  default = "eu-central-1"
  type    = string
}

variable "ASPNETCORE_ENVIRONMENT" {
  default = "Development"
  type    = string
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


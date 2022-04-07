variable "resource_prefix" {
  default = "wb"
  type    = string
}

variable "repository_url" {
  default = "836906079004.dkr.ecr.eu-central-1.amazonaws.com/wb-repository"
  type    = string
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

variable "subnets" {
  default = ["subnet-0c5ab4a1499db9f85"]
  type    = list(string)
}

variable "execution_role_arn" {
  default = "arn:aws:iam::836906079004:role/ecsTaskExecutionRole"
  type    = string
}
variable "vpc_id" {
  default = "vpc-0fead40e24304ce5f"
  type    = string
}

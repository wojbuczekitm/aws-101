terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.8.0"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = var.region
}

data "aws_vpc" "vpc" {
  id = var.vpc_id
}

resource "aws_ecs_cluster" "single_cluster" {
  name = "${var.resource_prefix}-cluster"
}

resource "aws_ecs_cluster_capacity_providers" "single_cluster_capacity_provider" {
  cluster_name = aws_ecs_cluster.single_cluster.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 10
    capacity_provider = "FARGATE"
  }
}

resource "aws_ecs_task_definition" "single_task_definition" {
  family                   = "${var.resource_prefix}-task-definition"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.execution_role_arn
  container_definitions    = <<DEFINITION
[
    {
        "image": "${var.repository_url}",
        "name": "${var.resource_prefix}-container",
        "cpu": 256,
        "memory" : 512,
        "essential": true,
        "networkMode": "awsvpc",
        "environment": [
            {
            "name": "ASPNETCORE_ENVIRONMENT",
            "value": "${var.ASPNETCORE_ENVIRONMENT}"
            }
        ],
        "portMappings": [
            {
            "hostPort": ${var.http_host_port},
            "containerPort": ${var.http_container_port}
            },
            {
            "hostPort": ${var.https_host_port},
            "containerPort": ${var.https_container_port}
            }
        ]

    }
]
                DEFINITION

}

resource "aws_ecs_service" "service" {
  name            = "${var.resource_prefix}-service"
  cluster         = aws_ecs_cluster.single_cluster.id
  task_definition = aws_ecs_task_definition.single_task_definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"
}


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

resource "aws_ecs_cluster" "cluster" {
  name = "${var.resource_prefix}-cluster"
}


resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "${var.resource_prefix}-execution-task-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "container_instance" {
  name = aws_iam_role.ecsTaskExecutionRole.name
  role = aws_iam_role.ecsTaskExecutionRole.name
}



data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ecs_service_role" {
  name               = "${var.resource_prefix}EcsServiceRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_service_role" {
  role       = aws_iam_role.ecs_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

data "aws_iam_policy_document" "ecs_autoscale_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["application-autoscaling.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ecs_autoscale_role" {
  name               = "${var.resource_prefix}EcsAutoscaleRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_autoscale_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_service_autoscaling_role" {
  role       = aws_iam_role.ecs_autoscale_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
}



resource "aws_security_group" "service_sg" {
  name   = "${var.resource_prefix}-service-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "-1"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_launch_configuration" "ecs" {
  image_id             = lookup(var.amis, var.region)
  instance_type        = var.instance_type
  security_groups      = [aws_security_group.ecs.id]
  iam_instance_profile = aws_iam_instance_profile.container_instance.name

  name_prefix = "${var.resource_prefix}-instance-"

  user_data = "#!/bin/bash\necho ECS_CLUSTER='${var.resource_prefix}-cluster' >> /etc/ecs/ecs.config"
}

# resource "aws_instance" "instance" {
#   ami                    = lookup(var.amis, var.region)
#   vpc_security_group_ids = [aws_security_group.ecs.id]
#   instance_type          = var.instance_type
#   user_data              = "#!/bin/bash\necho ECS_CLUSTER='${var.resource_prefix}-cluster' > /etc/ecs/ecs.config"

# }

resource "aws_autoscaling_group" "autoscaling_group" {
  name_prefix          = "${var.resource_prefix}-autoscaling_group-"
  vpc_zone_identifier  = var.subnets
  launch_configuration = aws_launch_configuration.ecs.name

  desired_capacity          = 1
  min_size                  = 1
  max_size                  = 2
  health_check_type         = "EC2"
  health_check_grace_period = 300

}

resource "aws_ecs_service" "service" {
  name                 = "${var.resource_prefix}-service"
  cluster              = aws_ecs_cluster.cluster.id
  task_definition      = aws_ecs_task_definition.task_definition.arn
  scheduling_strategy  = "REPLICA"
  desired_count        = 1
  force_new_deployment = true
  launch_type          = "EC2"
  count                = 1

  # network_configuration {
  #   subnets          = var.subnets
  #   assign_public_ip = false
  #   security_groups  = [aws_security_group.service_sg.id]
  # }
}

resource "aws_ecs_task_definition" "task_definition" {
  family = "${var.resource_prefix}-task-definition"

  execution_role_arn    = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn         = aws_iam_role.ecsTaskExecutionRole.arn
  container_definitions = <<EOF
[
  {
    "name": "${var.resource_prefix}-container",
    "image": "${var.repository_url}:latest",
    "memory": 256,
    "cpu": 256,
    "essential": true,
    "entryPoint": [],
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      }
    ]
  }
]
EOF
}

resource "aws_security_group" "ecs" {
  name   = "${var.resource_prefix}-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



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

resource "aws_ecs_cluster" "single_cluster" {
  name = "${var.resource_prefix}-cluster"
}

resource "aws_security_group" "load_balancer" {
  name   = "${var.resource_prefix}-lb-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs" {
  name   = "${var.resource_prefix}-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.load_balancer.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "alb" {
  name               = "${var.resource_prefix}-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.load_balancer.id]
  subnets            = var.subnets
}

# Target group
resource "aws_alb_target_group" "default_target_group" {
  name     = "${var.resource_prefix}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

resource "aws_alb_listener" "alb_http_listener" {
  load_balancer_arn = aws_lb.alb.id
  port              = "80"
  protocol          = "HTTP"
  depends_on        = [aws_alb_target_group.default_target_group]

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.default_target_group.arn
  }
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
      identifiers = ["ecs-tasks.amazonaws.com", "ecs.amazonaws.com", "ec2.amazonaws.com"]
    }
    effect = "Allow"
  }
}

resource "aws_iam_instance_profile" "ecs" {
  name = "${var.resource_prefix}-instance-profile"
  path = "/"
  role = aws_iam_role.ecsTaskExecutionRole.name
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}




resource "aws_iam_role" "ecs_service_role" {
  name               = "${var.resource_prefix}-ecs-service-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}


resource "aws_iam_role_policy" "service_role_policy" {
  name = "${var.resource_prefix}-service-role-policy"
  role = aws_iam_role.ecs_service_role.id
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "ecs:*",
            "ec2:*",
            "elasticloadbalancing:*",
            "ecr:*",
            "cloudwatch:*",
            "s3:*",
            "rds:*",
            "logs:*"
          ],
          "Resource" : [
            "*"
          ]
        }
      ]
  })
}


resource "aws_ecs_task_definition" "single_task_definition" {
  family                   = "${var.resource_prefix}-task-definition"
  container_definitions    = <<DEFINITION
[
    {
        "image": "${var.repository_url}",
        "name": "${var.resource_prefix}-container",
        "essential": true,
        "portMappings": [
          {
            "containerPort": 80,
            "hostPort": 80
          }
        ],
        "cpu": 10,
        "memory": 512,
        "networkMode": "awsvpc"

    }
]
                DEFINITION
  requires_compatibilities = ["EC2"]
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ecsTaskExecutionRole.arn

}

resource "aws_ecs_service" "service" {
  name            = "${var.resource_prefix}-service"
  cluster         = aws_ecs_cluster.single_cluster.id
  task_definition = aws_ecs_task_definition.single_task_definition.arn
  iam_role        = aws_iam_role.ecs_service_role.arn
  desired_count   = 1
  depends_on      = [aws_alb_listener.alb_http_listener, aws_iam_role_policy.service_role_policy]

  load_balancer {
    container_name   = "${var.resource_prefix}-container"
    container_port   = 80
    target_group_arn = aws_alb_target_group.default_target_group.arn
  }

}

resource "aws_launch_configuration" "ecs" {
  name                 = aws_ecs_cluster.single_cluster.name
  image_id             = "ami-029c5088a566b385e" #lookup(var.amis, var.region)
  instance_type        = var.instance_type
  security_groups      = [aws_security_group.ecs.id]
  iam_instance_profile = aws_iam_instance_profile.ecs.name

  user_data = "#!/bin/bash\necho ECS_CLUSTER='${var.resource_prefix}-cluster' > /etc/ecs/ecs.config"
}

output "alb_hostname" {
  value = aws_lb.alb.dns_name
}

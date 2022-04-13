resource "aws_ecs_cluster" "cluster" {
  name = "${var.resource_prefix}-cluster"
}


resource "aws_launch_configuration" "ecs_launch_config" {
  image_id                    = var.amis
  iam_instance_profile        = aws_iam_instance_profile.ecs_agent.name
  security_groups             = [aws_security_group.ecs_sg.id]
  user_data                   = "#!/bin/bash\n echo ECS_CLUSTER=${aws_ecs_cluster.cluster.name} >> /etc/ecs/ecs.config"
  instance_type               = var.instance_type
  associate_public_ip_address = true
}

resource "aws_autoscaling_group" "asg" {
  name                 = "${var.resource_prefix}-asg"
  vpc_zone_identifier  = var.subnets
  launch_configuration = aws_launch_configuration.ecs_launch_config.name

  desired_capacity          = 1
  min_size                  = 1
  max_size                  = 10
  health_check_grace_period = 300
  health_check_type         = "EC2"
}

resource "aws_ecs_task_definition" "service" {
  family             = "${var.resource_prefix}-definition"
  cpu                = "1vcpu"
  memory             = "512"
  execution_role_arn = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn      = aws_iam_role.ecsTaskExecutionRole.arn

  container_definitions = jsonencode([
    {
      name      = "${var.resource_prefix}-container"
      image     = "${aws_ecr_repository.repository.repository_url}:latest"
      cpu       = 1
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = "${var.http_container_port}"
          hostPort      = "${var.http_host_port}"
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "service" {
  name                    = "${var.resource_prefix}-service"
  cluster                 = aws_ecs_cluster.cluster.id
  task_definition         = aws_ecs_task_definition.service.arn
  desired_count           = 1
  enable_ecs_managed_tags = true
  launch_type             = "EC2"
}

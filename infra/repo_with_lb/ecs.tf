resource "aws_ecs_cluster" "cluster" {
  name = "${var.resource_prefix}-cluster"
}

data "template_file" "app" {
  template = file("./templates/image.json")

  vars = {
    app_image              = "${aws_ecr_repository.repository.repository_url}:latest"
    container_name         = "${var.resource_prefix}-container"
    containerPort          = "${var.https_container_port}"
    hostPort               = "${var.https_host_port}"
    cpu                    = "${var.cpu}"
    memory                 = "${var.memory}"
    region                 = var.region,
    ASPNETCORE_ENVIRONMENT = var.ASPNETCORE_ENVIRONMENT,
    ASPNETCORE_URLS        = var.ASPNETCORE_URLS
  }
}

resource "aws_ecs_task_definition" "task-def" {
  family                   = "${var.resource_prefix}-task-definition"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  container_definitions    = data.template_file.app.rendered
  #task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
}

resource "aws_ecs_service" "service" {
  name            = "${var.resource_prefix}-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task-def.arn
  desired_count   = var.app_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_sg.id]
    subnets          = var.subnets
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.alb-tg-https.arn
    container_name   = "${var.resource_prefix}-container"
    container_port   = var.https_host_port
  }

  depends_on = [aws_alb_listener.alb_listener_https, aws_alb_listener.redirect_to_https, aws_iam_role_policy_attachment.ecs_task_execution_role]
}

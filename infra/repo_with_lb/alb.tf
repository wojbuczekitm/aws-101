#in this template we are creating aws application laadbalancer and target group and alb http listener

resource "aws_alb" "alb" {
  name            = "${var.resource_prefix}-load-balancer"
  subnets         = var.subnets
  security_groups = [aws_security_group.alb-sg.id]
}

# resource "aws_alb_listener" "redirect_to_https" {
#   load_balancer_arn = aws_alb.alb.arn
#   port              = "80"
#   protocol          = "HTTP"

#   default_action {
#     type = "redirect"

#     redirect {
#       port        = "443"
#       protocol    = "HTTPS"
#       status_code = "HTTP_301"
#     }
#   }
# }

resource "aws_alb_target_group" "alb-tg-http" {
  name        = "${var.resource_prefix}-tg-http"
  port        = var.http_host_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    protocol            = "HTTP"
    matcher             = "200"
    path                = var.health_check_path
    interval            = 30
  }
}

resource "aws_alb_listener" "alb_listener_http" {
  load_balancer_arn = aws_alb.alb.id
  port              = var.http_host_port
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.alb-tg-http.arn
  }
}
# resource "aws_alb_target_group" "alb-tg-https" {
#   name        = "${var.resource_prefix}-tg-https"
#   port        = var.https_host_port
#   protocol    = "HTTPS"
#   target_type = "ip"
#   vpc_id      = var.vpc_id

#   health_check {
#     healthy_threshold   = 2
#     unhealthy_threshold = 2
#     timeout             = 3
#     protocol            = "HTTPS"
#     matcher             = "200"
#     path                = var.health_check_path
#     interval            = 30
#   }
# }

# resource "aws_alb_listener" "alb_listener_https" {
#   load_balancer_arn = aws_alb.alb.id
#   port              = var.https_host_port
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = var.cert_arn
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_alb_target_group.alb-tg-https.arn
#   }
# }

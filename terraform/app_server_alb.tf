data "aws_elb_service_account" "main" {}

# create a bucket for logs, backup of sql and
# raw data.

resource "aws_s3_bucket" "aws_logs" {
  bucket        = "${local.prefix}-logs"
  force_destroy = true
  tags = {
    Name = "${local.prefix}-logs-bucket"
  }
}

data "aws_iam_policy_document" "s3_lb_write" {
  policy_id = "s3_lb_write"

  statement {
    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.main.arn]
    }

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]

    resources = [aws_s3_bucket.aws_logs.arn, "${aws_s3_bucket.aws_logs.arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "allow_alb_logs" {
  bucket = aws_s3_bucket.aws_logs.id
  policy = data.aws_iam_policy_document.s3_lb_write.json
}


## create an application load balancer
resource "aws_lb" "app_server_lb" {
  name               = "${local.prefix}-appserver-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = module.networking.public_subnet_id
  depends_on = [
    aws_instance.app_server,
    aws_s3_bucket.aws_logs,
    aws_security_group.appserver_sg
  ]
  security_groups = [aws_security_group.appserver_sg.id]

  access_logs {
    bucket  = aws_s3_bucket.aws_logs.id
    prefix  = "${local.prefix}-appserver-lb-access-logs"
    enabled = true
  }

  tags = {
    Name = "${local.prefix}-appserver-lb"
  }
}

resource "aws_lb_target_group" "app_server_tg" {
  name     = "${local.prefix}-appserver-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.networking.vpc_id

  tags = {
    Name = "${local.prefix}-appserver-tg"
  }

  health_check {
    enabled  = true
    interval = 60
    matcher  = 200
    path     = "/"
    protocol = "HTTP"
    timeout  = 5
  }
}

resource "aws_lb_listener" "app_server_listener" {
  certificate_arn   = aws_acm_certificate.oi_portal_region_local.arn
  load_balancer_arn = aws_lb.app_server_lb.arn
  port              = 443
  protocol          = "HTTPS"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_server_tg.arn
  }

  tags = {
    Name = "${local.prefix}-appserver-listner"
  }
}

resource "aws_route53_record" "appserver_record" {
  zone_id = aws_route53_zone.oi_portal.zone_id
  name    = "app.oi-portal.com"
  type    = "CNAME"
  ttl     = "60"
  records = [aws_lb.app_server_lb.dns_name]
}

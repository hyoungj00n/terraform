resource "aws_launch_configuration" "asg_terraform" {
  image_id = "ami-0f3a440bbcff3d043" 
  instance_type = "t2.micro"
  security_groups = [aws_security_group.instance.id]

  user_data = <<-EOF
    #!/bin/bash
    echo "Hello, World" > index.html
    nohup busybox httpd -f -p ${var.server_port} &
  EOF

  lifecycle {
   create_before_destroy = true
 } 
}

resource "aws_security_group" "alb" {
  name = "terraform-alb"
 
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_autoscaling_group" "terraform" {
  launch_configuration = aws_launch_configuration.asg_terraform.name
  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"
  min_size = 2
  max_size = 3
  tag {
    key = "Name"
    value = "terraform-asg"
    propagate_at_launch = true
  }
}

resource "aws_lb" "terraform" {
  name = "terraform-asg"
  load_balancer_type = "application"
  subnets = data.aws_subnets.default.ids
  security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.terraform.arn
  port = 80
  protocol = "HTTP"
  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"
    fixed_response {
    content_type = "text/plain"
    message_body = "404: page not found"
    status_code = 404
    }
 }
}

resource "aws_lb_target_group" "asg" {
  name = "terraform-asg"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id
  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg" {
 listener_arn = aws_lb_listener.http.arn
 priority = 100
 condition {
  path_pattern {
   values = ["*"]
  }
 }
 action {
  type = "forward"
  target_group_arn = aws_lb_target_group.asg.arn
 }
}

output "alb_dns_name" {
 value = aws_lb.terraform.dns_name
 description = "load balancer"
}
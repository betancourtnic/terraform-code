# defines the cloud provider
provider "aws" {
    region = "us-east-1"
}

# ASG configs
resource "aws_launch_configuration" "example" {
    image_id    = "ami-020cba7c55df1f615"
    instance_type = "t2.micro"
    security_groups = [aws_security_group.instance.id]

    user_data = <<-EOF
            #!/bin/bash
            echo "Hello, World" > index.html
            nohup busybox httpd -f -p ${var.server_port} &
            EOF

    #this is required for using a launch config with an AGS
    lifecycle {
        create_before_destroy = true
    }
}

#defines ASG
resource "aws_autoscaling_group" "example" {
    launch_configuration = aws_launch_configuration.example.name
    vpc_zone_identifier = data.aws_subnet_ids.default.ids

    min_size = 2
    max_size = 10

    tag {
        key = "Name"
        value   = "terraform-asg-example"
        propagate_at_launch = true
    }
}

# creates security group
resource "aws_security_group" "instance" {
    name = "terraform-example-instance"

    ingress {
        from_port = var.server_port
        to_port = var.server_port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# look up data for default VPC
data "aws_vpc" "default" {
    default = true
}

# look up subnet within VPC
data "aws_subnet_ids" "default" {
    vpc_id = data.aws_vpc.default.id
}

#creates Application load balancer
resource "aws_lb" "example" {
    name    = "terraform-asg-example"
    load_balancer_type = "application"
    subnets = data.aws_subnet_ids.default.ids
}

#configure the ALB listener
resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.example.arn
    port = 80
    protocol = "HTTP"
    
    #by default, return 404 page
    default_action {
        type = "fixed-response"

        fixed_response {
            content_type = "text/plain"
            message_body = "404: page not found"
            status_code = 404
        }
    }
}
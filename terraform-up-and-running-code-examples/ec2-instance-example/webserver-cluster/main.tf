# defines the cloud provider
provider "aws" {
    region = "us-east-1"
}

# defines the resource
resource "aws_instance" "example" {
    ami = "ami-020cba7c55df1f615"
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.instance.id]

# allows instance to run script
    user_data = <<-EOF
            #!/bin/bash
            echo "Hello, World" > index.html
            nohup busybox httpd -f -p ${var.server_port} &
            EOF

# Names the instance
    tags = {
        Name = "ec2-instance-example"
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

# ASG configs
resource "aws_launch_configuration" "example" {
    image_id    = "ami-020cba7c55df1f615"
    instance_type = "t2.micro"
    aws_security_groups = [aws_security_group.instance.id]

    user_data = <<-EOF
            #!/bin/bash
            echo "Hello, World" > index.html
            nohup busybox httpd -f -p ${var.server_port} &
            EOF
}

#defines ASG
resource "aws_autoscaling_group" "example" {
    launch_configuration = aws_launch_configuration.example.name

    min_size = 2
    max_size = 10

    tag {
        key = "Name"
        value   = "terraform-asg-example"
        propagate_at_launch = true
    }
}
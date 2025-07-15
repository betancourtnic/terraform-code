output "public_ip" {
    value = aws_instance.example.public_ip
    description = "The public IP address of the web server"
}

output "instance_id" {
    value = aws_instance.example.id
    description = "The public id running instance"
}
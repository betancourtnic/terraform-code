# variable for port 8080
variable "server_port" {
    description = "The port the server will use for HTTP requests"
    type = number
    default = 8080
}
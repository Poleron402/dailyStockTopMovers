variable "massive_api_key" {
    description = "The API key for Massive API service"
    type= string
    sensitive   = true
}

variable "aws_region" {
    description = "The AWS region of the application's user"
    type= string
}
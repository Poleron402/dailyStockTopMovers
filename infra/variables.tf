variable "massive_api_key" {
    description = "The API key for Massive API service"
    type= string
    sensitive   = true
}

variable "aws_region" {
    description = "The AWS region of the application's user"
    type= string
}

variable "bucket_name" {
    description = "Name of the S3 bucket (needs to be unique across all AWS)"
    type = string
}

variable "database_name" {
    description = "Name of the DynamoDB database"
    type = string
}
variable "massive_api_key" {
    description = "The API key for Massive API service"
    type= string
    sensitive   = true
}

variable "stock_table_arn" {
  type = string
}
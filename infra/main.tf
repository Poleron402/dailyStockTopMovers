
provider "aws" {
  region = var.aws_region
}

module "database" {
  source = "./modules/database"
  database_name=var.database_name
}
module "lambdas" {
  source = "./modules/lambdas"
  massive_api_key = var.massive_api_key
  stock_table_arn = module.database.stock_table_arn
  database_name=var.database_name
}
module "gateway" {
  source = "./modules/gateway"
  invoke_arn = module.lambdas.invoke_arn
  api_lambda_name = module.lambdas.api_lambda_name
}
module "frontend" {
  source = "./modules/frontend"
  bucket_name = var.bucket_name
}
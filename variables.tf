#
#

##
variable "default_region" {
  type        = string
  default     = "eu-west-1"
  description = "The default region for aws services"
}

#
# Module variables
#
variable "tenant" {
  type        = string
  default     = "abc"
  description = "Top level tenant used in namespacing"
}

variable "product" {
  type        = string
  default     = "lambda"
  description = "name of the deployed product infra"
}

#
# Stack variables
#

variable "lambda_builder_folder_path" {
  type        = string
  default     = ""
  description = "The path to the Lambda builder folder (can't use path.module if running within a container)"
}

variable "log_retention" {
  type        = number
  default     = 30
  description = "number of days to store logs"
}

variable "lambda_timeout" {
  type        = number
  default     = 29
  description = "timeout for the lambda"
}

variable "lambda_memory" {
  type        = number
  default     = 256
  description = "memory allocation of the lambda"
}

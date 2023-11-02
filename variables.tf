variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}

variable "client_id" {
  type        = string
  description = "Azure Client ID"
}

variable "client_secret" {
  type        = string
  description = "Azure Client Secret"
  sensitive = true
}

variable "tenant_id" {
  type        = string
  description = "Azure Tenant ID"
}

variable "envName" {
  type        = string
  description = "Name of the environment where resources are to be deployed"
  default = "dev"
}

variable "uniqueString" {
    type        = string
    description = "Unique string to ensure uniqueness of resource names"
    default = "marm4"
}

variable "sql_administrator_login" {
    type        = string
    description = "SQL Administrator Login"
    default = "sqladmin"
}

variable "sql_administrator_password" {
    type        = string
    description = "SQL Administrator Password"
    sensitive = true
}
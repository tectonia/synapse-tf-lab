# Specifiy the provider and version (configuration details for Terraform)
terraform {
    required_providers {
        azurerm = {
        source  = "hashicorp/azurerm"
        version = "=2.46.0"
        }
    }
    backend "azurerm" {
        resource_group_name   = "tfstate"
        storage_account_name  = "synapsestatestorage"
        container_name        = "tfstate"
        key                   = "terraform.tfstate"
    }
}

# Configure the Microsoft Azure Provider (this is something that is needed for Azure specifically even if you don't need any features)
provider "azurerm" {
    features {}
    subscription_id = var.subscription_id
    client_id       = var.client_id
    client_secret   = var.client_secret
    tenant_id       = var.tenant_id
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
    name = "synapse-${var.envName}-rg"
    location = "uksouth"
    tags = {
        environment = var.envName
        source = "Terraform"
    }
}

# Create a storage account
resource "azurerm_storage_account" "storage" {
    name                     = "${var.uniqueString}storage${var.envName}"
    resource_group_name      = azurerm_resource_group.rg.name
    location                 = azurerm_resource_group.rg.location
    account_tier             = "Standard"
    account_replication_type = "LRS"
    tags = {
        environment = var.envName
        source = "Terraform"
    }
}

# Create a storage container
resource "azurerm_storage_container" "container" {
    name                  = "${azurerm_storage_account.storage.name}/default/${var.uniqueString}filesys${var.envName}}"
    storage_account_name  = azurerm_storage_account.storage.name
    container_access_type = "private"
}

# Create the filesystem
resource "azurerm_storage_data_lake_gen2_filesystem" "filesystem" {
  name               = "${var.uniqueString}filesys${var.envName}"
  storage_account_id = azurerm_storage_account.storage.id
}

# Create a synapse workspace
resource "azurerm_synapse_workspace" "synapse" {
    name                = "${var.uniqueString}-synapse-${var.envName}"
    resource_group_name = azurerm_resource_group.rg.name
    location            = azurerm_resource_group.rg.location
    sql_administrator_login          = var.sql_administrator_login
    sql_administrator_login_password = var.sql_administrator_login
    storage_data_lake_gen2_filesystem_id = storage_data_lake_gen2_filesystem.filesystem.id
    tags = {
        environment = var.envName
        source = "Terraform"
    }
}
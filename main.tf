# Specifiy the provider and version (configuration details for Terraform)
terraform {
    required_providers {
        azurerm = {
        source  = "hashicorp/azurerm"
        version = "=3.78.0"
        }
    }
    backend "azurerm" {
        # resource_group_name   = "tfstate"
        # storage_account_name  = "synapsestatestorage"
        # container_name        = "tfstate"
        # key                   = "terraform.tfstate"
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
    sql_administrator_login_password = var.sql_administrator_password
    storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.filesystem.id
    tags = {
        environment = var.envName
        source = "Terraform"
    }
    identity {
        type = "SystemAssigned"
    }
}

# Create firewall rules for the workspace
resource "azurerm_synapse_firewall_rule" "firewall" {
    name                = "AllowAll"
    synapse_workspace_id = azurerm_synapse_workspace.synapse.id
    start_ip_address    = "0.0.0.0"
    end_ip_address      = "255.255.255.255"
}

# Give the workspace access to the storage account
resource "azurerm_role_assignment" "workspacestorageaccess" {
    scope                = azurerm_storage_account.storage.id
    role_definition_name = "Storage Blob Data Contributor"
    principal_id         = azurerm_synapse_workspace.synapse.identity[0].principal_id
}

# Give the user access to the storage account
resource "azurerm_role_assignment" "userstorageaccess" {
    scope                = azurerm_storage_account.storage.id
    role_definition_name = "Storage Blob Data Contributor"
    principal_id         = var.user_object_id
}

# Create a dedicated SQL pool
resource "azurerm_synapse_sql_pool" "sqlpool" {
  name                 = "${var.uniqueString}sqlpool${var.envName}"
  synapse_workspace_id = azurerm_synapse_workspace.synapse.id
  sku_name             = "DW100c"
  create_mode          = "Default"
}

# Create an Apache Spark pool
resource "azurerm_synapse_spark_pool" "sparkpool" {
  name                 = "${var.uniqueString}spark${var.envName}"
  synapse_workspace_id = azurerm_synapse_workspace.synapse.id
  node_size_family     = "MemoryOptimized"
  node_size            = "Medium"
  cache_size           = 100
  auto_scale {
    max_node_count = 40
    min_node_count = 3
  }
  auto_pause {
    delay_in_minutes = 15
  }
  tags = {
    environment = var.envName
    source = "Terraform"
  }
}
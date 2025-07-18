# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.0"
    }
  }
  required_version = ">= 0.14.9"
  backend "azurerm" {
    resource_group_name  = "rg-terraform"
    storage_account_name = "stterrafstate"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}
provider "azurerm" {
  features {}
}

# Create the resource group
resource "azurerm_resource_group" "rg" {
  name     = "rg-mlops"
  location = "eastus"
}

# ACR
resource "azurerm_container_registry" "registry" {
  name                = "containerrmlops"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  admin_enabled       = true
}

# Create the Linux App Service Plan
resource "azurerm_service_plan" "appserviceplan" {
  name                = "asp-webapp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "B1"
}

# Create the web app, pass in the App Service Plan ID
resource "azurerm_linux_web_app" "webapp-mlflow" {
  name                  = "diabetes-mlflow"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  service_plan_id       = azurerm_service_plan.appserviceplan.id
  https_only            = true

  app_settings = {
    DOCKER_REGISTRY_SERVER_URL          = azurerm_container_registry.registry.login_server
    DOCKER_REGISTRY_SERVER_USERNAME     = azurerm_container_registry.registry.admin_username
    DOCKER_REGISTRY_SERVER_PASSWORD     = azurerm_container_registry.registry.admin_password
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = false
    WEBSITES_PORT                       = 5000
    AZURE_STORAGE_ACCESS_KEY            = azurerm_storage_account.mlflowstorage.primary_access_key
  }

  site_config { 
    minimum_tls_version = "1.2"

    application_stack {
       docker_image     = "${azurerm_container_registry.registry.login_server}/mlflow"
       docker_image_tag = "latest"
    }

  }
}

# Create the web app, pass in the App Service Plan ID
resource "azurerm_linux_web_app" "webapp-prefect" {
  name                  = "diabetes-prefect"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  service_plan_id       = azurerm_service_plan.appserviceplan.id
  https_only            = true

  app_settings = {
    DOCKER_REGISTRY_SERVER_URL          = azurerm_container_registry.registry.login_server
    DOCKER_REGISTRY_SERVER_USERNAME     = azurerm_container_registry.registry.admin_username
    DOCKER_REGISTRY_SERVER_PASSWORD     = azurerm_container_registry.registry.admin_password
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = false
    WEBSITES_PORT                       = 4200
    PREFECT_API_URL                     = "https://diabetes-prefect.azurewebsites.net/api"
  }

  site_config { 
    minimum_tls_version = "1.2"

    application_stack {
       docker_image     = "${azurerm_container_registry.registry.login_server}/prefect"
       docker_image_tag = "latest"
    }

  }
}

resource "azurerm_linux_web_app" "webapp-app" {
  name                  = "diabetes-app"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  service_plan_id       = azurerm_service_plan.appserviceplan.id
  https_only            = true

  app_settings = {
    DOCKER_REGISTRY_SERVER_URL          = azurerm_container_registry.registry.login_server
    DOCKER_REGISTRY_SERVER_USERNAME     = azurerm_container_registry.registry.admin_username
    DOCKER_REGISTRY_SERVER_PASSWORD     = azurerm_container_registry.registry.admin_password
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = false
    AZURE_STORAGE_ACCESS_KEY = azurerm_storage_account.mlflowstorage.primary_access_key
  }

  site_config { 
    minimum_tls_version = "1.2"

    application_stack {
       docker_image     = "${azurerm_container_registry.registry.login_server}/diabetes-app"
       docker_image_tag = "latest"
    }

  }
}

resource "azurerm_storage_account" "mlflowstorage" {
  name                     = "storageaccmflow"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "mlflowstoragecontainer" {
  name                  = "storagecontmflow"
  storage_account_name  = azurerm_storage_account.mlflowstorage.name
  container_access_type = "private"
}

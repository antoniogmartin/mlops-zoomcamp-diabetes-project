#!/bin/sh

az group create --name rg-terraform --location eastus
az storage account create --name stterrafstate --resource-group rg-terraform --location eastus --sku Standard_LRS --encryption-services blob
az storage container create --name tfstate --account-name stterrafstate --account-key $(az storage account keys list --resource-group rg-terraform --account-name stterrafstate --query '[0].value' --output tsv)
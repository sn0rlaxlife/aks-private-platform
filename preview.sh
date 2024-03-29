#!/bin/bash

# This script is used to preview the output of the script
az extension add --name aks-preview

# Update to the latest version of the extension
az extension update --name aks-preview

# Register EnableAPIServerVnetIntegration feature
az feature register --namespace "Microsoft.ContainerService" --name "EnableAPIServerVnetIntegrationPreview"



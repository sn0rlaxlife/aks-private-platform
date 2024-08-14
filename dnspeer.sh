#!/bin/bash

# Variables
RESOURCE_GROUP="aks-platform-private-rg-aks"
DNS_ZONE_NAME="privatelink.<region>.azmk8s.io" # Replace <region> with the region of your AKS cluster when created
BASTION_VNET_NAME="your-bastion-vnet" # Replace with the name of the VNet where the Bastion is deployed
BASTION_VNET_RESOURCE_GROUP="your-bastion-vnet-resource-group" # Replace with the resource group of the VNet where the Bastion is deployed

# Fetch the DNS Zone ID
echo "Fetching DNS Zone ID..."
DNS_ZONE_ID=$(az network private-dns zone show --name $DNS_ZONE_NAME --resource-group $RESOURCE_GROUP --query "id" --output tsv)

# Fetch the Bastion VNet ID
echo "Fetching Bastion VNet ID..."
BASTION_VNET_ID=$(az network vnet show --name $BASTION_VNET_NAME --resource-group $BASTION_VNET_RESOURCE_GROUP --query "id" --output tsv)

# Link the DNS Zone to the Bastion VNet
echo "Linking DNS Zone to Bastion VNet..."
az network private-dns link vnet create \
  --resource-group $RESOURCE_GROUP \
  --zone-name $DNS_ZONE_NAME \
  --name "bastion-vnet-link" \
  --virtual-network $BASTION_VNET_ID \
  --registration-enabled false

echo "DNS Zone linked to Bastion VNet successfully."

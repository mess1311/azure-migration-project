# shellcheck shell=bash
# Copy to vars.sh and edit. vars.sh is git-ignored.
export RG="rg-smarthotel-migrated"
export LOCATION="westeurope"

# From the Bicep deployment output (script 01 prints it)
export VNET="vnet-smarthotel"
export SUBNET="snet-onprem-mirror"
export STORAGE_ACCOUNT="<storageAccountName output>"
export CONTAINER="vhds"

# Replace with your real on-premises IPs (must match infra/bicep parameters)
export WAF_IP="192.168.0.8"
export WEB1_IP="192.168.0.4"
export WEB2_IP="192.168.0.5"
export SQL_IP="192.168.0.6"

# Starting sizes only: replace with the Azure Migrate assessment recommendation
export WAF_SIZE="Standard_B2s"
export WEB1_SIZE="Standard_B2s"
export WEB2_SIZE="Standard_B2s"
export SQL_SIZE="Standard_B2ms"

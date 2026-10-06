#!/usr/bin/env bash
# Creates the resource group and deploys the VNet, NSG, public IP and VHD storage.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/vars.sh"

az group create --name "$RG" --location "$LOCATION" --output none

az deployment group create \
  --resource-group "$RG" \
  --template-file "$SCRIPT_DIR/../../infra/bicep/main.bicep" \
  --parameters wafIp="$WAF_IP" web1Ip="$WEB1_IP" web2Ip="$WEB2_IP" sqlIp="$SQL_IP" \
  --query "properties.outputs" --output json

echo
echo "Copy the storageAccountName output into STORAGE_ACCOUNT in scripts/azure/vars.sh"

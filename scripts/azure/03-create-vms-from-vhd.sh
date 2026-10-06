#!/usr/bin/env bash
# Creates managed disks from the uploaded VHDs and boots the four VMs
# with the same private IPs they had on-premises. Order: back to front.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/vars.sh"

SA_ID="$(az storage account show -g "$RG" -n "$STORAGE_ACCOUNT" --query id -o tsv)"

# name | os | size | private IP | public IP resource ("" = none)
VMS=(
  "SmartHotelSQL1|Windows|$SQL_SIZE|$SQL_IP|"
  "SmartHotelWeb2|Windows|$WEB2_SIZE|$WEB2_IP|"
  "SmartHotelWeb1|Windows|$WEB1_SIZE|$WEB1_IP|"
  "UbuntuWAF|Linux|$WAF_SIZE|$WAF_IP|pip-waf"
)

for entry in "${VMS[@]}"; do
  IFS='|' read -r name os size ip pip <<< "$entry"
  disk="${name}-osdisk"

  echo "== $name: creating managed disk"
  az disk create \
    --resource-group "$RG" --name "$disk" --location "$LOCATION" \
    --os-type "$os" --hyper-v-generation V1 --sku StandardSSD_LRS \
    --source "https://${STORAGE_ACCOUNT}.blob.core.windows.net/${CONTAINER}/${name}.vhd" \
    --source-storage-account-id "$SA_ID" \
    --output none

  echo "== $name: creating VM ($size, $ip)"
  az vm create \
    --resource-group "$RG" --name "$name" --location "$LOCATION" \
    --attach-os-disk "$disk" --os-type "$os" --size "$size" \
    --vnet-name "$VNET" --subnet "$SUBNET" \
    --private-ip-address "$ip" \
    --public-ip-address "$pip" \
    --nsg "" \
    --output none
done

echo "Done. Next: docs/05-validation-and-cutover.md"

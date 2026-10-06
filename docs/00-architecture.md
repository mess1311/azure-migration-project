# 0. Architecture

## Before and after

```mermaid
flowchart LR
  subgraph ONPREM["On-premises: Hyper-V host (SmartHotelHost)"]
    direction LR
    U[UbuntuWAF<br/>Nginx / Ubuntu 18.04] --> W1[SmartHotelWeb1<br/>IIS / WS 2012 R2]
    W1 --> W2[SmartHotelWeb2<br/>IIS / WS 2012 R2]
    W2 --> S[(SmartHotelSQL1<br/>SQL 2017 / WS 2016)]
  end

  subgraph AZURE["Azure: vnet-smarthotel"]
    direction LR
    PIP([Public IP]) --> AU[UbuntuWAF]
    subgraph SUBNET["snet-onprem-mirror (NSG)"]
      AU --> AW1[SmartHotelWeb1]
      AW1 --> AW2[SmartHotelWeb2]
      AW2 --> AS[(SmartHotelSQL1)]
    end
    BAS[Azure Bastion<br/>optional] -. RDP/SSH .-> SUBNET
  end

  ONPREM ==>|migrate| AZURE
```

## Design decisions

| Decision | Reason |
|---|---|
| Keep on-prem IPs in Azure | App and proxy configs reference IPs, so nothing needs editing at cutover |
| One subnet + NSG rules per flow | Reproduces the flat LAN while still restricting each tier |
| Only the WAF has a public IP | Same exposure as on-premises |
| Bastion instead of public RDP | No management ports on the internet. Enable it only while administering |
| Storage account for VHDs | Landing area for the manual path. Delete it after migration |

## Traffic rules (NSG)

| Priority | Rule | Source | Destination | Ports |
|---|---|---|---|---|
| 100 | Internet to WAF | Internet | UbuntuWAF | 80, 443 |
| 110 | Bastion admin | Bastion subnet | Workload subnet | 22, 3389 |
| 130 | WAF to Web1 | UbuntuWAF | Web1 | 80, 443 |
| 140 | Web1 to Web2 | Web1 | Web2 | 80, 443 |
| 150 | Web2 to SQL | Web2 | SQL1 | 1433 |
| 4000 | Deny other intra-subnet | Subnet | Subnet | any |

Adjust these to match what dependency analysis (guide 01) shows.

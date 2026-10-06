# SmartHotel: on-premises to Azure migration

Migration playbook, infrastructure code and scripts for moving the four-VM SmartHotel application from Hyper-V to Azure.

![status](https://img.shields.io/badge/status-lab-orange) ![license](https://img.shields.io/badge/license-MIT-blue)

## Source environment (Stage 1: on-premises, Hyper-V)

| VM | Tier | OS / software |
|---|---|---|
| `UbuntuWAF` | Web proxy | Ubuntu 18.04 LTS, Nginx |
| `SmartHotelWeb1` | Web tier | Windows Server 2012 R2, IIS |
| `SmartHotelWeb2` | Application tier | Windows Server 2012 R2, IIS |
| `SmartHotelSQL1` | Database tier | Windows Server 2016, SQL Server 2017 |

```
Internet -> UbuntuWAF -> SmartHotelWeb1 -> SmartHotelWeb2 -> SmartHotelSQL1
```

## Target environment (Stage 2: Azure)

The same four VMs run in an Azure VNet that keeps the on-premises IP addresses, so application configuration does not change. Only the WAF has a public IP, and NSG rules allow only the traffic each tier needs. See [docs/00-architecture.md](docs/00-architecture.md).

## Choose a migration path

| Path | When to use | Guide |
|---|---|---|
| **A. Azure Migrate (Hyper-V replication)** | Windows Server Hyper-V host, enough RAM for the appliance (about 16 GB) | [02](docs/02-azure-migrate.md) |
| **B. Manual VHD upload** | Small lab host (for example 8 GB), VirtualBox, or Windows 10/11 host | [03](docs/03-manual-vhd-migration.md) |
| **C. Modernize afterwards** | After lift-and-shift: SQL to Azure SQL MI, web to App Service, WAF to Application Gateway | [06](docs/06-modernization.md) |

## Guides

| # | Guide |
|---|---|
| 0 | [Architecture](docs/00-architecture.md) |
| 1 | [Assessment and planning](docs/01-assessment.md) |
| 2 | [Path A: Azure Migrate](docs/02-azure-migrate.md) |
| 3 | [Path B: manual VHD migration](docs/03-manual-vhd-migration.md) |
| 4 | [Network and security](docs/04-network-and-security.md) |
| 5 | [Validation and cutover](docs/05-validation-and-cutover.md) |
| 6 | [Modernization](docs/06-modernization.md) |
| 7 | [Troubleshooting](docs/07-troubleshooting.md) |

## Repository layout

```
docs/                     step-by-step guides (start with 01)
infra/bicep/main.bicep    landing zone: VNet, NSG, WAF public IP, VHD storage, optional Bastion
scripts/onprem/           VM preparation (Windows and Ubuntu)
scripts/azure/            deploy landing zone, upload VHDs, create VMs from disks
config/nginx/             reference Nginx reverse-proxy config for UbuntuWAF
.github/workflows/        CI: Bicep build, ShellCheck, PSScriptAnalyzer
```

## Quick start (path B)

```bash
# 1. Configure
cp scripts/azure/vars.example.sh scripts/azure/vars.sh   # edit values
az login

# 2. Landing zone
./scripts/azure/01-deploy-landing-zone.sh                # note the storage account name

# 3. On each VM (console): scripts/onprem/Prepare-WindowsVM.ps1 or prepare-ubuntu.sh, then shut down

# 4. On the host
.\scripts\azure\02-upload-vhds.ps1 -StorageAccount <name> -SasToken "<sas>"

# 5. Back in Azure
./scripts/azure/03-create-vms-from-vhd.sh
```

Then follow [docs/05-validation-and-cutover.md](docs/05-validation-and-cutover.md).

## Read this first

- **IP addresses in this repo are examples.** Replace them with your real on-premises IPs in `vars.sh` and the Bicep parameters.
- **NSG rules assume the typical flow** (WAF to Web1 to Web2 to SQL). Confirm the real flows with dependency analysis before cutover, and adjust `infra/bicep/main.bicep`.
- **Licensing:** Windows Server evaluation editions are for testing only and cannot use Azure Hybrid Benefit. Server 2012 R2 is out of support (Azure offers Extended Security Updates for it) and Ubuntu 18.04 is past standard support. Plan upgrades after migration.
- **Scripts are not production-hardened.** Test in a lab and review each before running.

## License

MIT, see [LICENSE](LICENSE).

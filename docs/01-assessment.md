# 1. Assessment and planning

Do this before moving anything.

## Inventory (fill in)

| VM | vCPU | RAM | Disk(s) | Generation | OS | Static IP | Notes |
|---|---|---|---|---|---|---|---|
| UbuntuWAF | | | | | Ubuntu 18.04 | | Nginx |
| SmartHotelWeb1 | | | | | WS 2012 R2 | | IIS |
| SmartHotelWeb2 | | | | | WS 2012 R2 | | IIS |
| SmartHotelSQL1 | | | | | WS 2016 | | SQL 2017 |

Get the data with:

```powershell
Get-VM | Select Name, ProcessorCount, @{n='RAM(GB)';e={$_.MemoryStartup/1GB}}, Generation, State
Get-VM | Get-VMHardDiskDrive | Get-VHD | Select Path, VhdFormat, VhdType, @{n='Size(GB)';e={$_.Size/1GB}}
```

## Dependencies

Confirm which VM talks to which (and on which ports) so the NSG rules are right.

- **Azure Migrate dependency analysis** (for Hyper-V this is agent-based): shows connections between servers.
- Or on each Windows VM: `netstat -ano | findstr ESTABLISHED`, and on UbuntuWAF `ss -tnp`.
- Record connection strings, service accounts, scheduled tasks, hard-coded IPs and hostnames, DNS names and certificates.

## Compatibility checks

| Item | Check |
|---|---|
| Windows Server 2012 R2 | Supported in Azure. It is out of support, so use Extended Security Updates and plan an upgrade |
| Windows Server 2016 evaluation | Test only. A licensed edition is needed for production, and Hybrid Benefit cannot apply to eval media |
| Ubuntu 18.04 | Supported for migration but past standard support, so plan 22.04/24.04 |
| SQL Server 2017 | Runs on an Azure VM as is. Azure SQL MI is the modernization target |
| Hyper-V generation | Gen 2 works with Azure Migrate. The manual VHD path needs Gen 1 or a Gen 2 conversion |
| Disks | Manual path needs fixed VHD, with a virtual size that is a whole number of MiB |

## Sizing

Start with these and replace them with the assessment recommendation.

| VM | Starting size |
|---|---|
| UbuntuWAF | Standard_B2s |
| SmartHotelWeb1 / Web2 | Standard_B2s (D2s_v5 for production) |
| SmartHotelSQL1 | Standard_B2ms (E2s_v5 for production) |

## Pre-migration checklist

- [ ] Azure subscription and permissions (Contributor on the target resource group)
- [ ] Region chosen, with VM size quotas checked (`az vm list-usage -l <region>`)
- [ ] Backups of all four VMs (export or checkpoint) and a SQL backup
- [ ] Maintenance window and rollback plan agreed
- [ ] Real IPs recorded and placed in `vars.sh` and the Bicep parameters
- [ ] Certificates, licences and DNS records inventoried

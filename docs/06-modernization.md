# 6. Path C: modernize after lift-and-shift

Optional second wave once the VMs are stable in Azure.

| Today (VM) | Azure service | Tool | Benefit |
|---|---|---|---|
| SmartHotelSQL1 (SQL 2017) | **Azure SQL Managed Instance** or Azure SQL Database | Azure Database Migration Service, Data Migration Assistant | No OS or SQL patching, built-in backups and HA |
| SmartHotelWeb1 / Web2 (IIS) | **Azure App Service** | App Service Migration Assistant | No Windows patching, autoscale |
| UbuntuWAF (Nginx) | **Azure Application Gateway WAF v2** or Front Door WAF | Portal / Bicep | Managed WAF with OWASP rules, TLS offload |

## Suggested order

1. **Database**: run the Data Migration Assistant against SQL1 to find blockers, then migrate with DMS (online migration for minimal downtime). Update the application connection string.
2. **Web/app tiers**: run the readiness check from the App Service Migration Assistant, deploy to App Service, test, switch traffic.
3. **WAF**: create an Application Gateway WAF v2 in front of App Service, validate rules in Detection mode, then switch to Prevention.
4. Remove the old VMs and the `snet-onprem-mirror` subnet rules.

Each step is independent, so you can stop after any of them. Cost and effort rise with the number of services replaced, so decide per tier.

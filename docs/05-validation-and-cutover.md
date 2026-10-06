# 5. Validation and cutover

## Validate in Azure (before changing DNS)

Work from the back of the stack to the front.

**SmartHotelSQL1**
```powershell
Get-Service MSSQLSERVER, 'MSSQL$*' -ErrorAction SilentlyContinue   # Running?
sqlcmd -S localhost -E -Q "SELECT name, state_desc FROM sys.databases"
```
Start the SQL service if it is stopped, and confirm all databases are `ONLINE`.

**SmartHotelWeb2 (application tier)**
```powershell
ipconfig                                  # expected on-prem IP
Test-NetConnection <SQL_IP> -Port 1433    # TcpTestSucceeded : True
```
Open the application endpoint locally (`http://localhost/...`) and check that data loads.

**SmartHotelWeb1 (web tier)**
```powershell
Test-NetConnection <WEB2_IP> -Port 80
```
Browse `http://localhost` and verify pages load with live data.

**UbuntuWAF**
```bash
curl -I http://<WEB1_IP>          # 200 from web tier
sudo nginx -t && systemctl status nginx
```

**End to end**
```bash
curl -I http://<WAF public IP>
```
Then test the site from a browser: sign in, search, make a booking or whichever transaction the app supports.

## Cutover plan

| Step | Action | Owner |
|---|---|---|
| T-1 day | Lower DNS TTL, final backup, notify users | |
| T-0 | Stop the app on-premises (web tiers first, then SQL) | |
| T+0:10 | (Path A) Run final migration / (Path B) take final disk copies if data changed | |
| T+0:40 | Start Azure VMs, run the validation above | |
| T+1:00 | Change DNS to the Azure WAF IP | |
| T+2:00 | Monitor logs and performance, confirm with users | |
| T+7 days | Decommission on-premises VMs, delete VHD storage, stop Bastion | |

## Rollback

- Keep the on-premises VMs stopped but intact until sign-off.
- To roll back: point DNS back at the on-premises WAF and start the on-premises VMs in order (SQL, Web2, Web1, WAF).
- Data written in Azure after cutover would need to be exported and merged. Decide this before cutover.

## Post-migration tasks

- Enable **Azure Backup** and **Update Management**.
- Right-size VMs after a week of metrics.
- Switch Standard SSD to a cheaper or faster tier as needed, and set auto-shutdown for non-production.
- Plan upgrades: Ubuntu 22.04/24.04, Windows Server 2019/2022, SQL Server 2019/2022.

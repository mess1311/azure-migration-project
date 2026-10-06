<#
 Run INSIDE each Windows VM (SmartHotelWeb1, SmartHotelWeb2 on Server 2012 R2,
 SmartHotelSQL1 on Server 2016) in an elevated PowerShell, from the VM console.
 It prepares the OS for Azure. The DHCP switch is LAST because it removes the
 static IP. Then shut the VM down.

 Not needed when Azure Migrate (Hyper-V replication) performs the migration:
 it handles most of this itself. Needed for the manual VHD path.
#>
$ErrorActionPreference = "Stop"

# Remote Desktop on
Set-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# Azure-recommended settings
netsh winhttp reset proxy
reg add HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation /v RealTimeIsUniversal /t REG_DWORD /d 1 /f
Set-Service w32time -StartupType Automatic
powercfg /setactive SCHEME_MIN
"san policy=onlineall" | diskpart

# SQL Server VM: stop the service cleanly before shutdown
Get-Service -Name 'MSSQLSERVER','MSSQL$*' -ErrorAction SilentlyContinue |
    Where-Object Status -eq 'Running' | Stop-Service -Force

Write-Host "Install the Azure VM Agent (https://aka.ms/vmagentwin) before continuing."
Read-Host "Press Enter once the agent is installed to switch NICs to DHCP"

# FINAL STEP: let Azure assign the (reserved) IP
Get-NetAdapter | Where-Object Status -eq "Up" | ForEach-Object {
    netsh interface ip set address $_.Name dhcp
    netsh interface ip set dns $_.Name dhcp
}
Write-Host "Prepared. Run: Stop-Computer"

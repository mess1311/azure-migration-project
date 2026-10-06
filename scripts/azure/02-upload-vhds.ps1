<#
 Run on the HOST. Converts the VM disks to fixed VHD and uploads them as page blobs.
 Manual migration path: use this when you cannot run the Azure Migrate appliance
 (it needs about 16 GB RAM) or your host is not Windows Server.

 Requirements: AzCopy, a container SAS token (Read, Create, Write, Add), VMs shut down.
 Azure needs FIXED VHD, Generation 1 (see docs/03-manual-vhd-migration.md).
#>
param(
    [Parameter(Mandatory)][string]$StorageAccount,
    [Parameter(Mandatory)][string]$SasToken,     # without the leading '?'
    [string]$Container = "vhds",
    [string]$ExportDir = "D:\export",
    [string]$AzCopy    = ".\azcopy.exe",
    # Map: VM name -> source disk path (edit to match your host)
    [hashtable]$Disks = @{
        "UbuntuWAF"      = "D:\VMs\UbuntuWAF.vhdx"
        "SmartHotelWeb1" = "D:\VMs\SmartHotelWeb1.vhdx"
        "SmartHotelWeb2" = "D:\VMs\SmartHotelWeb2.vhdx"
        "SmartHotelSQL1" = "D:\VMs\SmartHotelSQL1.vhdx"
    }
)

$ErrorActionPreference = "Stop"
New-Item -ItemType Directory -Path $ExportDir -Force | Out-Null

foreach ($vm in $Disks.Keys) {
    $src = $Disks[$vm]
    $dst = Join-Path $ExportDir "$vm.vhd"

    if ((Get-VM -Name $vm -ErrorAction SilentlyContinue).State -eq "Running") {
        throw "$vm is running. Shut it down first."
    }

    Write-Host "Converting $src -> $dst (fixed VHD)"
    Convert-VHD -Path $src -DestinationPath $dst -VHDType Fixed

    # Virtual size must be a whole number of MiB
    $size = (Get-VHD -Path $dst).Size
    if ($size % 1MB -ne 0) {
        $newSize = [math]::Ceiling($size / 1MB) * 1MB
        Resize-VHD -Path $dst -SizeBytes $newSize
    }

    Write-Host "Uploading $dst"
    & $AzCopy copy $dst "https://$StorageAccount.blob.core.windows.net/$Container/$vm.vhd?$SasToken" --blob-type PageBlob
}
Write-Host "All disks uploaded."

# 3. Path B: manual VHD upload

Use this when the Azure Migrate appliance does not fit (for example an 8 GB lab host), the host is VirtualBox or Windows 10/11, or you want full control. You upload the actual disks and create VMs from them. This is a true lift-and-shift.

## Overview

```
Prepare VMs -> Shut down -> Convert to fixed VHD -> Upload (page blob) -> Managed disk -> VM
```

## 1. Landing zone

```bash
cp scripts/azure/vars.example.sh scripts/azure/vars.sh   # edit
./scripts/azure/01-deploy-landing-zone.sh
```

Copy the `storageAccountName` output into `STORAGE_ACCOUNT` in `vars.sh`.

## 2. Prepare each VM (console, not remote session)

| VM | Script |
|---|---|
| SmartHotelWeb1, SmartHotelWeb2, SmartHotelSQL1 | `scripts/onprem/Prepare-WindowsVM.ps1` |
| UbuntuWAF | `sudo scripts/onprem/prepare-ubuntu.sh` |

Also:

- Uninstall VirtualBox Guest Additions if the VMs came from VirtualBox.
- Install the Azure VM Agent in Windows VMs (`https://aka.ms/vmagentwin`).
- On SQL1, make sure SQL Server shut down cleanly. A fresh full backup is a good safety net.
- **Shut the VMs down** (not saved state).

## 3. Convert and upload

Create a container SAS token in the portal: storage account > `vhds` container > **Shared access tokens**, with Read, Create, Write and Add permissions and a short expiry.

```powershell
.\scripts\azure\02-upload-vhds.ps1 -StorageAccount <name> -SasToken "<token without ?>"
```

The script converts each disk to a **fixed VHD**, rounds the size to a whole MiB, and uploads it as a **page blob**. Edit the `Disks` map first to match your disk paths. For VirtualBox (`.vdi`) disks use:

```powershell
VBoxManage clonemedium disk "<source>.vdi" "D:\export\<vm>.vhd" --format VHD --variant Fixed
```

and upload with AzCopy using `--blob-type PageBlob`.

> **Generation 2 VMs:** the script path produces Generation 1 compatible VHDs. If your Hyper-V VMs are Generation 2 (UEFI), either convert them to Generation 1 first, or change `--hyper-v-generation` to `V2` in script 03 and test. Azure Migrate (guide 02) handles Gen 2 more simply.

## 4. Create disks and VMs

```bash
./scripts/azure/03-create-vms-from-vhd.sh
```

This creates one managed disk per VM, then the four VMs (SQL, Web2, Web1, WAF) with their original private IPs. Only the WAF gets a public IP.

## 5. Sign in

- Use the **original VM credentials** (the disks keep local accounts). If you forgot a password, use **Reset password** on the VM (requires the VM agent).
- The VMs have no public IPs except the WAF. Enable Bastion (`deployBastion=true` in the Bicep deployment) or use **Run command**/serial console.

Continue with [05-validation-and-cutover.md](05-validation-and-cutover.md).

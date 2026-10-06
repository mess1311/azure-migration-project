# 7. Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Windows VM stuck at boot / blue screen | Wrong generation, non-fixed disk, missing prep | Recreate the disk with the correct `--hyper-v-generation`, check **Boot diagnostics > Screenshot** |
| Linux VM does not boot or no SSH | Static netplan config kept, no agent, fstab uses device names | Re-run `prepare-ubuntu.sh` before migrating, or fix via serial console |
| Cannot RDP/SSH | No public IP by design | Deploy Bastion (`deployBastion=true`) or use **Run command** / serial console |
| IP is not the expected one | NIC still configured statically in the OS | Set NIC to DHCP (via Run command), confirm the private IP in the portal |
| Web page loads, data missing | SQL service stopped or firewall | Start the SQL service, check Windows firewall and NSG rule `Allow-Web2-to-SQL` |
| Web1 cannot reach Web2 | NSG rule or Windows firewall | Check rule `Allow-Web1-to-Web2` and the actual ports used |
| An app hop fails but is not in the NSG | Real traffic flow differs from the assumed one | Check dependency analysis, add a rule in `main.bicep`, redeploy |
| `az disk create` import fails | Blob is not a page blob, size not whole MiB, wrong account ID | Re-upload with `--blob-type PageBlob`, resize the VHD to whole MiB |
| AzCopy 403 | SAS expired or missing permissions | Generate a new SAS with Read/Create/Write/Add |
| Replication not progressing (Azure Migrate) | Provider cannot reach Azure, low bandwidth | Check outbound HTTPS and proxy settings on the host |
| Evaluation watermark / shutdowns | Windows eval edition | Expected. Use licensed media for anything beyond a lab |

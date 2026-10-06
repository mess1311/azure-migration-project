# 4. Network and security in Azure

## Access model

| Need | Method |
|---|---|
| Users reach the site | Internet to the WAF public IP (`pip-waf`) on 80/443 |
| Administrators reach VMs | Azure Bastion (`deployBastion=true`), or **Run command** / serial console |
| VM-to-VM traffic | Allowed only by the NSG rules in `infra/bicep/main.bicep` |

Enable Bastion only while you need it:

```bash
az deployment group create -g "$RG" -f infra/bicep/main.bicep \
  -p wafIp="$WAF_IP" web1Ip="$WEB1_IP" web2Ip="$WEB2_IP" sqlIp="$SQL_IP" deployBastion=true
```

Bastion Basic is billed per hour. Deploy it with `deployBastion=false` again (or delete `bas-smarthotel` and `pip-bastion`) when done. Note that a complete-mode redeploy is not used here, so deleting those resources manually is the way to remove them.

## UbuntuWAF

The VM keeps its on-premises IP, so the Nginx upstream normally needs no change. A reference config is in `config/nginx/smarthotel.conf`.

```bash
sudo nginx -t && sudo systemctl reload nginx
```

Nginx here is a reverse proxy. If you installed ModSecurity on-premises, it migrates with the VM.

## HTTPS

1. Put a certificate on UbuntuWAF (Let's Encrypt works once DNS points at the public IP).
2. Add a `listen 443 ssl;` server block and redirect port 80 to 443.
3. The NSG already allows 443.

## DNS cutover

1. Lower the TTL of the site's DNS record a day before cutover.
2. After validation, point the A record at the output `wafPublicIpAddress` (`az network public-ip show -g "$RG" -n pip-waf --query ipAddress -o tsv`).
3. Keep the on-premises VMs (stopped) until sign-off.

## Hardening checklist

- [ ] No public IP on Web1, Web2 or SQL1
- [ ] Windows Update / ESU enabled on 2012 R2, patch the 2016 VM
- [ ] SQL `sa` password rotated, application uses a least-privilege login
- [ ] Backup enabled (Recovery Services vault) for all four VMs
- [ ] Microsoft Defender for Cloud enabled on the subscription
- [ ] Delete the VHD storage account and SAS tokens once migration is signed off

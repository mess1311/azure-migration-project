# 2. Path A: Azure Migrate (Hyper-V replication)

Microsoft's tool for moving Hyper-V VMs to Azure. Check the current Azure Migrate documentation as portal labels and requirements change.

## Requirements

- A **Windows Server** Hyper-V host. The replication provider is not for Windows 10/11 hosts.
- Outbound HTTPS from the host to Azure.
- For discovery/assessment, an **Azure Migrate appliance** VM (about 16 GB RAM, 8 vCPU). On a smaller host, skip assessment and use the manual path in guide 03.
- Contributor rights on the subscription.

## Steps

### 1. Landing zone

```bash
cp scripts/azure/vars.example.sh scripts/azure/vars.sh   # edit
./scripts/azure/01-deploy-landing-zone.sh
```

### 2. Create the Azure Migrate project

Portal: **Azure Migrate > Servers, databases and web apps > Create project**. Choose the resource group and a geography.

### 3. Discover and assess (optional but recommended)

1. **Discover > Using appliance > Hyper-V**. Download the appliance and import it to the Hyper-V host.
2. Start the appliance, open its web UI, paste the project key to register it, and add the Hyper-V host credentials.
3. Wait for the four VMs to appear, then create an **Azure VM assessment**. Review readiness, recommended size and monthly cost.

### 4. Set up replication

1. In **Migration tools**, open **Discover > Hyper-V**. Download the **Hyper-V replication provider** and the registration key.
2. Install the provider on the Hyper-V host and register it with the key.
3. **Replicate**: select the four VMs, target subscription/resource group, the VNet `vnet-smarthotel`, subnet `snet-onprem-mirror`, and disk type (Standard SSD).
4. For each VM, open **Compute and Network** settings and set the **target private IP** to the on-premises IP (static), and the size from the assessment.
5. Wait until each VM shows **Protected** with replication healthy.

### 5. Test migration

1. Create an isolated test VNet (same address space, no peering) and run **Test migration** into it.
2. Validate each VM (guide 05), then **Clean up test migration**.

### 6. Cutover

1. Notify users and stop writes (stop the app on SQL clients first, then the web tiers).
2. Run **Migrate** on the VMs, choosing to shut down the source VMs. This performs a final delta sync.
3. Start validation (guide 05), then DNS/public endpoint changes.
4. After sign-off, **Stop replication** to clean up.

## Notes

- Agent installation: Azure Migrate installs the Azure VM Agent for supported Windows VMs. For Linux, ensure `walinuxagent` is present (`scripts/onprem/prepare-ubuntu.sh` installs it).
- If a VM fails to boot after migration, check **Boot diagnostics** in the portal and see guide 07.

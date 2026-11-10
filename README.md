# PikeHex Cloud Migration — Reusable Bicep Template

This repository uses subscription-scope orchestration with reusable modules. Resource configuration lives in `environments/*.bicepparam`; resource modules consume parameters and do not own environment-specific names, locations, SKUs, CIDRs, tags, or resource counts.

## Included dev resources

`environments/dev.bicepparam` contains one configured instance of each requested resource type:

- Resource group
- Virtual network
- Subnet (separate module)
- Network security group
- Route table
- Windows virtual machine and NIC
- Key Vault
- Storage account and blob container
- Azure SQL logical server and database

The arrays in `landingZones` are the configuration feed. To create more resources, add more objects to the corresponding array and ensure references such as VM-to-subnet and subnet-to-NSG/route-table use the intended names. The same modules are reused for each array item.

## Before deployment

1. Review `config/subscriptions.json`; it identifies the subscription used for each environment. The workflow currently selects the single `dev` entry.
2. Confirm resource names are available and unique:
   - Storage account names are globally unique, lowercase, and 3–24 characters.
   - Key Vault and SQL server names must also be globally unique.
3. Confirm the selected subscription has resource providers registered and sufficient permissions.
4. Configure `VM_ADMIN_PASSWORD` and `SQL_ADMIN_PASSWORD` as secure environment variables or GitHub Actions secrets. Do not commit passwords.
5. The sample Windows VM has no public IP and the NSG starts with no inbound rules. Add approved access paths before expecting remote administration.
6. The SQL server public network access is disabled in the sample configuration. Add private connectivity/firewall configuration if an application needs access.

## Local validation — PowerShell

Run from the repository root in PowerShell. These commands do not deploy resources until the deployment command is run.

```powershell
$ErrorActionPreference = 'Stop'

# Sign in and select the dev subscription from config/subscriptions.json.
az login
$dev = Get-Content 'config/subscriptions.json' -Raw |
  ConvertFrom-Json |
  Where-Object { $_.environment -eq 'dev' }

if (@($dev).Count -ne 1) {
  throw "Expected exactly one dev subscription entry."
}

az account set --subscription $dev.sub_id
if ($LASTEXITCODE -ne 0) { throw "Could not select dev subscription." }

# Prompt securely; passwords are not echoed to the terminal.
$vmSecure = Read-Host 'Windows VM admin password' -AsSecureString
$sqlSecure = Read-Host 'SQL admin password' -AsSecureString
$env:VM_ADMIN_PASSWORD = [System.Net.NetworkCredential]::new('', $vmSecure).Password
$env:SQL_ADMIN_PASSWORD = [System.Net.NetworkCredential]::new('', $sqlSecure).Password

# Build, lint, and validate parameter file.
az bicep build --file modules/main.bicep
if ($LASTEXITCODE -ne 0) { throw "Bicep build failed." }

az bicep lint --file modules/main.bicep
if ($LASTEXITCODE -ne 0) { throw "Bicep lint failed." }

az bicep build-params --file environments/dev.bicepparam
if ($LASTEXITCODE -ne 0) { throw "Parameter-file validation failed." }
```

## Preview before deployment

```powershell
az deployment sub what-if `
  --name 'pikehex-dev-whatif' `
  --location eastus `
  --template-file modules/main.bicep `
  --parameters environments/dev.bicepparam `
  --result-format FullResourcePayloads

if ($LASTEXITCODE -ne 0) { throw "What-If failed." }
```

Review the complete What-If output before continuing.

## Deploy

Only run after reviewing the preview and confirming that resource names, region, subscription, SKUs, and costs are acceptable.

```powershell
az deployment sub create `
  --name "pikehex-dev-$(Get-Date -Format yyyyMMddHHmmss)" `
  --location eastus `
  --template-file modules/main.bicep `
  --parameters environments/dev.bicepparam `
  --output table

if ($LASTEXITCODE -ne 0) { throw "Deployment failed." }
```

Clear local password variables after use:

```powershell
Remove-Item Env:VM_ADMIN_PASSWORD -ErrorAction SilentlyContinue
Remove-Item Env:SQL_ADMIN_PASSWORD -ErrorAction SilentlyContinue
```

## Git commands

From the repository root:

```powershell
git status
git add .
git commit -m "Refactor Bicep into reusable parameter-driven modules"
git push origin Dev
```

Change `Dev` if your working branch has a different name. Review `git status` before committing so generated ARM JSON or secrets are not accidentally committed.

## Subscription configuration

`config/subscriptions.json` is kept as the source for environment-to-subscription and environment-to-parameter-file mapping. The workflow currently deploys only the `dev` entry. Add other environments only after their parameter files are populated and reviewed.

## GitHub Actions secrets required

Configure these repository or `dev` environment secrets before running the workflow:

- `AZURE_CLIENT_ID` — Microsoft Entra application/service principal client ID used for OIDC.
- `AZURE_TENANT_ID` — Microsoft Entra tenant ID.
- `AZURE_SUBSCRIPTION_ID` — Azure subscription GUID (not the subscription name).
- `VM_ADMIN_PASSWORD` — local administrator password for the VM.
- `SQL_ADMIN_PASSWORD` — SQL administrator password.

The workflow reads the subscription ID from `secrets.AZURE_SUBSCRIPTION_ID`; it does not read `config/subscriptions.json` or the `subscriptionId` placeholder in `input.json`. The secret name must be spelled exactly `AZURE_SUBSCRIPTION_ID`.

The workflow is manually triggered using `workflow_dispatch` and runs on a Windows self-hosted runner with Azure CLI installed at `C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd`. Azure OIDC federation must also be configured for the repository/environment subject in Microsoft Entra ID.


## Stable globally unique resource naming

The following fixed candidate names are configured in `input.json` and are passed by `deploy.yml` to the Bicep modules. They are stable across repeated runs; they are not generated from the GitHub Actions run ID.

- Key Vault: `kv-pikehex-dev-9m4x7`
- Storage account: `stpikehexdev9m4x7`
- Azure OpenAI account: `oai-pikehex-dev-9m4x7`
- Azure OpenAI custom subdomain: `oai-pikehex-dev-9m4x7`

Before deployment, check Key Vault and Storage Account availability:

```bash
az keyvault check-name --name kv-pikehex-dev-9m4x7 -o json
az storage account check-name --name stpikehexdev9m4x7 -o json
```

Azure OpenAI account-name availability is also subject to Azure Cognitive Services name and regional availability checks. These candidate names have not been reserved or verified by this repository update. If Azure reports a name is unavailable, select another fixed suffix once, update `input.json`, and keep it unchanged for later runs.

The workflow prints the configured Key Vault, Storage Account, and Azure OpenAI names in the corresponding deployment job logs to make it easier to confirm which `input.json` version was checked out.

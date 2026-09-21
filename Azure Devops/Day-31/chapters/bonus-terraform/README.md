# Bonus: Infrastructure as Code with Terraform

> Replace manual VM setup with code. Write it once, deploy it anywhere.

**Prerequisites**: Chapters 1-9 completed. Azure account with active subscription. Azure CLI installed.

> **Cost warning**: VMs cost money. We'll use the cheapest size (`Standard_B1s`, free-tier eligible). Always run `terraform destroy` when done.

---

## What is Infrastructure as Code?

In Chapter 7, you created a VM by clicking through the Azure Portal. That works, but it's:
- Not reproducible (can you remember every click?)
- Not version-controlled (no history of changes)
- Not reviewable (can't PR a series of portal clicks)
- Slow to scale (need 10 VMs? Click 10 times?)

**Infrastructure as Code (IaC)** = Describe your infrastructure in text files, store them in Git, and use a tool to create/update/destroy the real resources.

---

## What is Terraform?

[Terraform](https://www.hashicorp.com/products/terraform) is an open-source IaC tool by HashiCorp. It works with Azure, AWS, GCP, and 3000+ providers.

The workflow:

```
Write (.tf files) → Plan (preview) → Apply (create) → Destroy (cleanup)
```

Terraform uses **HCL** (HashiCorp Configuration Language) — reads almost like English. It tracks what it created in a **state file**, so it knows what to change next time.

---

## Install Terraform

```bash
# macOS
brew tap hashicorp/tap && brew install hashicorp/tap/terraform

# Windows
choco install terraform

# Linux
sudo apt update && sudo apt install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

Verify: `terraform -version`

[Screenshot: terraform -version output]

---

## Writing Terraform for SkillPulse

Files live in `bonus/terraform/`:

```
bonus/terraform/
├── main.tf          # Resource definitions
├── variables.tf     # Input variables
└── outputs.tf       # Output values
```

### Provider Config (main.tf)

```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}

provider "azurerm" {
  features {}
}
```

Terraform authenticates using your Azure CLI login (`az login`).

### Resources

The full `main.tf` creates:

1. **Resource Group** — Container for all resources
2. **Virtual Network + Subnet** — Private networking
3. **Public IP** — So the world can reach your VM
4. **Network Security Group** — Firewall rules (SSH port 22, HTTP port 80, HTTPS port 443)
5. **Network Interface** — Connects VM to the network
6. **Linux VM** — Ubuntu 22.04 with a startup script that installs Docker automatically

Each resource references others — Terraform figures out the creation order automatically.

### Variables (variables.tf)

```hcl
variable "location" {
  description = "Azure region"
  type        = string
  default     = "Central India"
}

variable "vm_size" {
  description = "VM size"
  type        = string
  default     = "Standard_B1s"
}
```

Override at runtime: `terraform apply -var="location=East US"`

### Outputs (outputs.tf)

```hcl
output "vm_public_ip" {
  description = "Public IP of the SkillPulse VM"
  value       = azurerm_public_ip.skillpulse.ip_address
}
```

After `terraform apply`, you'll see the IP address to access your app.

> Browse the full files in [`bonus/terraform/`](../../bonus/terraform/).

---

## Running Terraform

### Step 1: Login and Navigate

```bash
az login
cd bonus/terraform/
```

### Step 2: Init

Downloads provider plugins:

```bash
terraform init
```

### Step 3: Plan

Preview what will be created (dry run):

```bash
terraform plan
```

You'll see `Plan: 8 to add, 0 to change, 0 to destroy.`

[Screenshot: terraform plan output]

### Step 4: Apply

Create the infrastructure:

```bash
terraform apply
```

Type `yes` when prompted. Takes 2-5 minutes.

```
Apply complete! Resources: 8 added, 0 changed, 0 destroyed.

Outputs:
vm_public_ip = "20.198.xx.xx"
```

[Screenshot: terraform apply output]

### Step 5: Verify

Check in the Azure Portal — your resource group has all the resources. SSH into the VM:

```bash
ssh azureuser@<vm_public_ip>
```

---

## Terraform via Azure Pipelines

For team environments, run Terraform inside a pipeline so infrastructure changes go through PRs.

Two-stage approach:
1. **Plan stage** — `terraform init`, `validate`, `plan` (anyone can trigger)
2. **Apply stage** — `terraform apply` (requires manual approval)

This needs:
- The [Terraform extension](https://marketplace.visualstudio.com/items?itemName=ms-devlabs.custom-terraform-tasks) installed from the marketplace
- An Azure Resource Manager service connection
- An environment with an approval gate (like we did for production deployments)

---

## State Management

By default, Terraform stores state locally in `terraform.tfstate`. For teams, store it in **Azure Storage**:

```bash
# Create storage for state
az group create --name rg-terraform-state --location centralindia
az storage account create --name stskillpulsetfstate --resource-group rg-terraform-state --sku Standard_LRS
az storage container create --name tfstate --account-name stskillpulsetfstate
```

Add the backend to `main.tf`:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stskillpulsetfstate"
    container_name       = "tfstate"
    key                  = "skillpulse.terraform.tfstate"
  }
}
```

Run `terraform init` to migrate. Now state is shared, locked, and encrypted.

**Never commit** `terraform.tfstate` to Git.

---

## Cleanup

```bash
terraform destroy
```

Type `yes`. Terraform deletes everything in the correct order.

Also clean up the state storage if you don't need it:

```bash
az group delete --name rg-terraform-state --yes --no-wait
```

---

## Tips

- **Use variables** for anything that might change
- **Pin provider versions** (`~> 3.80`, not latest)
- **Tag every resource** with project, environment, managed_by
- **Run `terraform plan` before every `apply`** — no surprises
- **Use remote state** for team projects
- **Separate state** per environment (dev, staging, prod)

Add to `.gitignore`:

```
*.tfstate
*.tfstate.backup
.terraform/
.terraform.lock.hcl
*.tfvars
```

---

## What You Learned

| Manual (Chapter 7) | Terraform (This Chapter) |
|--------------------|--------------------------|
| Click through Azure Portal | Write `.tf` files |
| Can't reproduce reliably | Run `terraform apply`, same result every time |
| No version control | Infrastructure in Git, reviewed via PRs |
| Manual setup script via SSH | Startup script as `custom_data` (runs on boot) |

That's the course complete! You've gone from zero to a full Azure DevOps setup with CI/CD, self-hosted agents, and now Infrastructure as Code.

---

**[<< Back to Chapter 9](../09-complete-workflow/) | [Back to Course Home](../../)**

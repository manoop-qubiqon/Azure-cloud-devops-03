# Azure Networking – Detailed Study Notes


---

## Table of Contents
1. [Virtual Networks (VNet) & Subnets](#1-virtual-networks-vnet--subnets)
2. [Network Security Groups (NSG)](#2-network-security-groups-nsg)
3. [Azure Load Balancer & Application Gateway](#3-azure-load-balancer--application-gateway)
4. [Azure DNS & Traffic Manager](#4-azure-dns--traffic-manager)

---

## 1. Virtual Networks (VNet) & Subnets

### What is a VNet?
A **Virtual Network (VNet)** is the fundamental building block of Azure networking. It is a logically isolated network in Azure where you place and connect resources securely.

```
┌──────────────────────────────────────────────┐
│          Azure Region (e.g., East US)         │
│                                              │
│   ┌──────────────────────────────────┐       │
│   │    VNet: 10.0.0.0/16             │       │
│   │                                  │       │
│   │  ┌────────────┐ ┌─────────────┐  │       │
│   │  │ Subnet-Web │ │ Subnet-DB   │  │       │
│   │  │ 10.0.1.0/24│ │ 10.0.2.0/24 │  │       │
│   │  │  [VM-Web1] │ │  [VM-DB1]   │  │       │
│   │  └────────────┘ └─────────────┘  │       │
│   │                                  │       │
│   │  ┌─────────────────────────────┐ │       │
│   │  │ GatewaySubnet 10.0.255.0/27 │ │       │
│   │  └─────────────────────────────┘ │       │
│   └──────────────────────────────────┘       │
└──────────────────────────────────────────────┘
```

### Key Concepts
| Concept | Details |
|---|---|
| Address Space | CIDR block e.g. `10.0.0.0/16` (up to 65,536 IPs) |
| Subnets | Subdivisions of VNet CIDR, e.g. `10.0.1.0/24` |
| Reserved IPs | First 4 + last 1 in each subnet are reserved by Azure |
| VNet Peering | Connect VNets within same or different regions |
| DNS | Custom DNS servers or Azure-provided (`168.63.129.16`) |

> 💡 **Exam Tip:** Azure reserves 5 IPs per subnet: `.0` (network), `.1` (default gateway), `.2-.3` (Azure DNS), `.255` (broadcast).

---

### CLI Commands – VNet & Subnets

#### Create a Resource Group
```bash
az group create \
  --name rg-networking \
  --location eastus
```

#### Create a VNet with Address Space
```bash
az network vnet create \
  --resource-group rg-networking \
  --name vnet-prod \
  --address-prefix 10.0.0.0/16 \
  --location eastus
```

#### Add Subnets to the VNet
```bash
# Web Tier Subnet
az network vnet subnet create \
  --resource-group rg-networking \
  --vnet-name vnet-prod \
  --name subnet-web \
  --address-prefix 10.0.1.0/24

# Database Tier Subnet
az network vnet subnet create \
  --resource-group rg-networking \
  --vnet-name vnet-prod \
  --name subnet-db \
  --address-prefix 10.0.2.0/24

# Gateway Subnet (required for VPN/ExpressRoute)
az network vnet subnet create \
  --resource-group rg-networking \
  --vnet-name vnet-prod \
  --name GatewaySubnet \
  --address-prefix 10.0.255.0/27
```

#### List VNets and Subnets
```bash
# List all VNets
az network vnet list --resource-group rg-networking --output table

# List subnets in a VNet
az network vnet subnet list \
  --resource-group rg-networking \
  --vnet-name vnet-prod \
  --output table

# Show VNet details
az network vnet show \
  --resource-group rg-networking \
  --name vnet-prod
```

#### Update VNet Address Space
```bash
az network vnet update \
  --resource-group rg-networking \
  --name vnet-prod \
  --add addressSpace.addressPrefixes "10.1.0.0/16"
```

---

### VNet Peering

```
┌───────────────────┐       Peering       ┌───────────────────┐
│  vnet-hub         │◄───────────────────►│  vnet-spoke       │
│  10.0.0.0/16      │                     │  10.1.0.0/16      │
│  (East US)        │                     │  (East US)        │
└───────────────────┘                     └───────────────────┘
```

```bash
# Peer vnet-hub → vnet-spoke
az network vnet peering create \
  --resource-group rg-networking \
  --name hub-to-spoke \
  --vnet-name vnet-hub \
  --remote-vnet vnet-spoke \
  --allow-vnet-access

# Peer vnet-spoke → vnet-hub (required; peering is NOT bi-directional automatically)
az network vnet peering create \
  --resource-group rg-networking \
  --name spoke-to-hub \
  --vnet-name vnet-spoke \
  --remote-vnet vnet-hub \
  --allow-vnet-access
```

> ⚠️ **Exam Tip:** VNet Peering is **non-transitive**. If A ↔ B and B ↔ C, A cannot talk to C unless you also peer A ↔ C.

---

### Service Endpoints vs Private Endpoints

| Feature | Service Endpoint | Private Endpoint |
|---|---|---|
| Traffic path | Public IP of service, via Azure backbone | Private IP in VNet |
| DNS | Public FQDN resolves to public IP | Private FQDN resolves to private IP |
| Cost | Free | Per-hour + data charge |
| Use case | Restrict access to Azure services | Full private access |

```bash
# Enable Service Endpoint for Azure Storage on a subnet
az network vnet subnet update \
  --resource-group rg-networking \
  --vnet-name vnet-prod \
  --name subnet-web \
  --service-endpoints Microsoft.Storage
```

---

## 2. Network Security Groups (NSG)

### What is an NSG?
An **NSG** is a stateful firewall that filters inbound and outbound traffic using security rules. It can be associated with a **subnet** or a **NIC (Network Interface Card)**.

```
Internet
   │
   ▼
┌─────────────────────────────────────┐
│         NSG (Subnet Level)          │
│  Rule 100: Allow HTTPS (443) Inbound│
│  Rule 200: Allow SSH (22)  Inbound  │
│  Rule 65500: Deny All               │
└─────────────────┬───────────────────┘
                  │
          ┌───────▼──────┐
          │  Subnet-Web  │
          │              │
          │  ┌─────────┐ │
          │  │  VM-1   │◄├──── NIC-level NSG (optional extra layer)
          │  └─────────┘ │
          └──────────────┘
```

### NSG Rule Properties
| Property | Description |
|---|---|
| Priority | 100–4096 (lower = higher priority) |
| Source/Destination | IP, CIDR, Service Tag, or ASG |
| Port | Single port, range, or `*` |
| Protocol | TCP, UDP, ICMP, or `*` |
| Action | Allow or Deny |
| Direction | Inbound or Outbound |

### Default NSG Rules (Always Present)
| Priority | Name | Direction | Action | Description |
|---|---|---|---|---|
| 65000 | AllowVnetInBound | Inbound | Allow | All traffic within VNet |
| 65001 | AllowAzureLoadBalancerInBound | Inbound | Allow | LB health probes |
| 65500 | DenyAllInBound | Inbound | Deny | Block everything else |
| 65000 | AllowVnetOutBound | Outbound | Allow | All traffic within VNet |
| 65001 | AllowInternetOutBound | Outbound | Allow | Outbound to Internet |
| 65500 | DenyAllOutBound | Outbound | Deny | Block everything else |

---

### CLI Commands – NSG

#### Create an NSG
```bash
az network nsg create \
  --resource-group rg-networking \
  --name nsg-web \
  --location eastus
```

#### Add Inbound Rules
```bash
# Allow HTTPS (443)
az network nsg rule create \
  --resource-group rg-networking \
  --nsg-name nsg-web \
  --name Allow-HTTPS \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes '*' \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges 443

# Allow SSH (22) from specific IP only
az network nsg rule create \
  --resource-group rg-networking \
  --nsg-name nsg-web \
  --name Allow-SSH-AdminOnly \
  --priority 110 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes '203.0.113.10/32' \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges 22

# Allow HTTP (80)
az network nsg rule create \
  --resource-group rg-networking \
  --nsg-name nsg-web \
  --name Allow-HTTP \
  --priority 120 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes '*' \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges 80

# Deny all other inbound (explicit, lower priority)
az network nsg rule create \
  --resource-group rg-networking \
  --nsg-name nsg-web \
  --name Deny-All-Inbound \
  --priority 4000 \
  --direction Inbound \
  --access Deny \
  --protocol '*' \
  --source-address-prefixes '*' \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges '*'
```

#### Associate NSG with Subnet
```bash
az network vnet subnet update \
  --resource-group rg-networking \
  --vnet-name vnet-prod \
  --name subnet-web \
  --network-security-group nsg-web
```

#### Associate NSG with NIC
```bash
az network nic update \
  --resource-group rg-networking \
  --name nic-vm1 \
  --network-security-group nsg-web
```

#### List and View Rules
```bash
# List NSGs
az network nsg list --resource-group rg-networking --output table

# List rules in NSG
az network nsg rule list \
  --resource-group rg-networking \
  --nsg-name nsg-web \
  --output table

# Show effective security rules on a NIC
az network nic list-effective-nsg \
  --resource-group rg-networking \
  --name nic-vm1
```

#### Update or Delete a Rule
```bash
# Update rule priority
az network nsg rule update \
  --resource-group rg-networking \
  --nsg-name nsg-web \
  --name Allow-HTTPS \
  --priority 200

# Delete rule
az network nsg rule delete \
  --resource-group rg-networking \
  --nsg-name nsg-web \
  --name Allow-HTTP
```

---

### Application Security Groups (ASG)

ASGs let you group VMs logically and use group names in NSG rules instead of IPs.

```
NSG Rule: Allow DB-Tier (ASG) ← Web-Tier (ASG) on port 1433

Instead of:
  Source: 10.0.1.4, 10.0.1.5, 10.0.1.6 ...

Use:
  Source: asg-web (Application Security Group)
```

```bash
# Create ASGs
az network asg create --resource-group rg-networking --name asg-web --location eastus
az network asg create --resource-group rg-networking --name asg-db --location eastus

# Assign ASG to NIC
az network nic ip-config update \
  --resource-group rg-networking \
  --nic-name nic-vm-web1 \
  --name ipconfig1 \
  --application-security-groups asg-web

# NSG rule using ASGs as source/destination
az network nsg rule create \
  --resource-group rg-networking \
  --nsg-name nsg-db \
  --name Allow-Web-to-DB \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-asgs asg-web \
  --source-port-ranges '*' \
  --destination-asgs asg-db \
  --destination-port-ranges 1433
```

> 💡 **Exam Tip:** NSG rules are **stateful** — if inbound traffic is allowed, the return outbound traffic is automatically allowed.

---

## 3. Azure Load Balancer & Application Gateway

### Azure Load Balancer (Layer 4)

Operates at **Transport Layer (TCP/UDP)**. Distributes traffic to VMs in a backend pool.

```
Internet
    │
    ▼
┌───────────────────────────┐
│   Azure Load Balancer     │
│   Frontend IP: 20.x.x.x  │
│   Port 80 / 443           │
└──────────┬────────────────┘
           │ Load Balancing Rules
    ┌──────┴────────┐
    ▼               ▼
┌─────────┐    ┌─────────┐
│  VM-1   │    │  VM-2   │
│ 10.0.1.4│    │ 10.0.1.5│
└─────────┘    └─────────┘
     ▲               ▲
     └───── Health Probe (TCP:80 every 5s)
```

#### SKU Comparison
| Feature | Basic | Standard |
|---|---|---|
| Backend pool size | Up to 300 | Up to 1000 |
| Health probes | HTTP, TCP | HTTP, HTTPS, TCP |
| Zone redundancy | No | Yes |
| SLA | None | 99.99% |
| NSG required | No | Yes (explicit allow) |
| Outbound rules | No | Yes |
| Cost | Free | Paid |

> ⚠️ **Exam Tip:** Standard LB requires **NSG** on backend VMs to allow traffic. Basic LB does not.

---

#### CLI Commands – Azure Load Balancer

```bash
# 1. Create a Public IP for LB frontend
az network public-ip create \
  --resource-group rg-networking \
  --name pip-lb-prod \
  --sku Standard \
  --allocation-method Static \
  --zone 1 2 3

# 2. Create Standard Load Balancer
az network lb create \
  --resource-group rg-networking \
  --name lb-prod \
  --sku Standard \
  --frontend-ip-name fe-config \
  --public-ip-address pip-lb-prod \
  --backend-pool-name backend-pool

# 3. Create Health Probe
az network lb probe create \
  --resource-group rg-networking \
  --lb-name lb-prod \
  --name probe-http \
  --protocol Http \
  --port 80 \
  --path /healthcheck \
  --interval 5 \
  --threshold 2

# 4. Create Load Balancing Rule
az network lb rule create \
  --resource-group rg-networking \
  --lb-name lb-prod \
  --name rule-http \
  --protocol Tcp \
  --frontend-port 80 \
  --backend-port 80 \
  --frontend-ip-name fe-config \
  --backend-pool-name backend-pool \
  --probe-name probe-http \
  --idle-timeout 4 \
  --enable-tcp-reset true

# 5. Add VMs to backend pool (via NIC IP config)
az network nic ip-config update \
  --resource-group rg-networking \
  --nic-name nic-vm1 \
  --name ipconfig1 \
  --lb-name lb-prod \
  --lb-address-pools backend-pool

az network nic ip-config update \
  --resource-group rg-networking \
  --nic-name nic-vm2 \
  --name ipconfig1 \
  --lb-name lb-prod \
  --lb-address-pools backend-pool
```

#### Inbound NAT Rules (for direct VM access via LB)
```bash
# Map port 50001 on LB → port 22 on VM-1 (for SSH)
az network lb inbound-nat-rule create \
  --resource-group rg-networking \
  --lb-name lb-prod \
  --name nat-ssh-vm1 \
  --protocol Tcp \
  --frontend-port 50001 \
  --backend-port 22 \
  --frontend-ip-name fe-config
```

---

### Application Gateway (Layer 7)

Operates at **Application Layer (HTTP/HTTPS)**. Offers URL-based routing, SSL termination, WAF, and cookie-based session affinity.

```
                         ┌─────────────────────────────────────────────┐
                         │          Application Gateway                  │
Internet ──────────────► │  Listener (HTTPS:443)                        │
                         │       │                                       │
                         │  SSL Termination                              │
                         │       │                                       │
                         │  WAF (Optional) ──► Block malicious requests │
                         │       │                                       │
                         │  URL Routing Rules:                           │
                         │    /api/*   ──────────────────────────────┐  │
                         │    /images/* ────────────────────────┐    │  │
                         │    /*        ──────────────────┐     │    │  │
                         └────────────────────────────────┼─────┼────┼──┘
                                                          ▼     ▼    ▼
                                                       BE-Web BE-Img BE-API
                                                        Pool   Pool   Pool
```

#### App Gateway vs Load Balancer
| Feature | App Gateway | Load Balancer |
|---|---|---|
| Layer | 7 (HTTP/HTTPS) | 4 (TCP/UDP) |
| URL Routing | Yes | No |
| SSL Termination | Yes | No |
| WAF | Yes (WAF SKU) | No |
| Protocols | HTTP, HTTPS, HTTP/2, WebSocket | TCP, UDP |
| Cookie Affinity | Yes | No |
| Redirects | HTTP → HTTPS | No |

---

#### CLI Commands – Application Gateway

```bash
# 1. Create a dedicated subnet for App Gateway (required)
az network vnet subnet create \
  --resource-group rg-networking \
  --vnet-name vnet-prod \
  --name subnet-appgw \
  --address-prefix 10.0.3.0/27

# 2. Create Public IP for App Gateway
az network public-ip create \
  --resource-group rg-networking \
  --name pip-appgw \
  --sku Standard \
  --allocation-method Static

# 3. Create Application Gateway (Standard_v2)
az network application-gateway create \
  --resource-group rg-networking \
  --name appgw-prod \
  --location eastus \
  --sku Standard_v2 \
  --capacity 2 \
  --vnet-name vnet-prod \
  --subnet subnet-appgw \
  --public-ip-address pip-appgw \
  --frontend-port 80 \
  --http-settings-port 80 \
  --http-settings-protocol Http \
  --routing-rule-type Basic \
  --priority 1

# 4. Add backend pool with VM IPs
az network application-gateway address-pool create \
  --resource-group rg-networking \
  --gateway-name appgw-prod \
  --name backend-web \
  --servers 10.0.1.4 10.0.1.5

# 5. Add HTTP settings
az network application-gateway http-settings create \
  --resource-group rg-networking \
  --gateway-name appgw-prod \
  --name settings-web \
  --port 80 \
  --protocol Http \
  --cookie-based-affinity Enabled \
  --timeout 30

# 6. Add HTTP listener
az network application-gateway http-listener create \
  --resource-group rg-networking \
  --gateway-name appgw-prod \
  --name listener-http \
  --frontend-ip appGatewayFrontendIP \
  --frontend-port appGatewayFrontendPort

# 7. URL Path-based routing
az network application-gateway url-path-map create \
  --resource-group rg-networking \
  --gateway-name appgw-prod \
  --name urlmap-prod \
  --paths /api/* \
  --address-pool backend-api \
  --http-settings settings-api \
  --default-address-pool backend-web \
  --default-http-settings settings-web

# 8. Enable WAF (for WAF_v2 SKU)
az network application-gateway waf-config set \
  --resource-group rg-networking \
  --gateway-name appgw-prod \
  --enabled true \
  --firewall-mode Prevention \
  --rule-set-type OWASP \
  --rule-set-version 3.2
```

> 💡 **Exam Tip:** App Gateway requires its **own dedicated subnet**. No other resources can be in that subnet.

---

## 4. Azure DNS & Traffic Manager

### Azure DNS

Azure DNS hosts your DNS zones using Azure's global infrastructure. It does **not** register domain names — you still need a domain registrar.

```
User types: www.contoso.com
       │
       ▼
  Registrar NS records point to:
  ns1-01.azure-dns.com
  ns2-01.azure-dns.net
  ns3-01.azure-dns.org
  ns4-01.azure-dns.info
       │
       ▼
  Azure DNS Zone: contoso.com
  ┌─────────────────────────────────────┐
  │  A     www      → 20.50.1.100       │
  │  CNAME api      → app.azurefd.net   │
  │  MX    @        → mail.contoso.com  │
  │  TXT   @        → v=spf1 ...        │
  └─────────────────────────────────────┘
```

#### DNS Record Types
| Type | Purpose | Example |
|---|---|---|
| A | IPv4 address | `www → 20.50.1.100` |
| AAAA | IPv6 address | `www → 2001:db8::1` |
| CNAME | Alias to another name | `api → app.azurefd.net` |
| MX | Mail exchange | `@ → mail.contoso.com` |
| TXT | Text record (SPF, DKIM) | `v=spf1 include:...` |
| NS | Name servers | (auto-created with zone) |
| SOA | Start of authority | (auto-created with zone) |
| SRV | Service locator | `_sip._tcp → sipserver` |
| PTR | Reverse DNS | `100.1.50.20.in-addr.arpa → www` |
| CAA | Cert authority authorization | `issue "letsencrypt.org"` |

---

#### CLI Commands – Azure DNS

```bash
# 1. Create a DNS Zone
az network dns zone create \
  --resource-group rg-networking \
  --name contoso.com

# 2. List zone name servers (point your registrar to these)
az network dns zone show \
  --resource-group rg-networking \
  --name contoso.com \
  --query nameServers \
  --output table

# 3. Create A Record (www → public IP)
az network dns record-set a add-record \
  --resource-group rg-networking \
  --zone-name contoso.com \
  --record-set-name www \
  --ipv4-address 20.50.1.100

# 4. Create CNAME Record
az network dns record-set cname set-record \
  --resource-group rg-networking \
  --zone-name contoso.com \
  --record-set-name api \
  --cname app.azurefd.net

# 5. Create MX Record
az network dns record-set mx add-record \
  --resource-group rg-networking \
  --zone-name contoso.com \
  --record-set-name "@" \
  --exchange mail.contoso.com \
  --preference 10

# 6. Create TXT Record (SPF)
az network dns record-set txt add-record \
  --resource-group rg-networking \
  --zone-name contoso.com \
  --record-set-name "@" \
  --value "v=spf1 include:spf.protection.outlook.com -all"

# 7. Set TTL on a record set
az network dns record-set a update \
  --resource-group rg-networking \
  --zone-name contoso.com \
  --name www \
  --set ttl=300

# 8. List all record sets in a zone
az network dns record-set list \
  --resource-group rg-networking \
  --zone-name contoso.com \
  --output table

# 9. Delete a record
az network dns record-set a remove-record \
  --resource-group rg-networking \
  --zone-name contoso.com \
  --record-set-name www \
  --ipv4-address 20.50.1.100
```

#### Private DNS Zones
Used for name resolution within VNets (no public exposure).

```bash
# Create private DNS zone
az network private-dns zone create \
  --resource-group rg-networking \
  --name privatelink.blob.core.windows.net

# Link to VNet
az network private-dns link vnet create \
  --resource-group rg-networking \
  --zone-name privatelink.blob.core.windows.net \
  --name link-to-vnet-prod \
  --virtual-network vnet-prod \
  --registration-enabled false

# Add A record in private zone
az network private-dns record-set a add-record \
  --resource-group rg-networking \
  --zone-name privatelink.blob.core.windows.net \
  --record-set-name mystorageaccount \
  --ipv4-address 10.0.0.5
```

> 💡 **Exam Tip:** For **auto-registration** of VM DNS names in a private zone, set `--registration-enabled true` when linking the VNet.

---

### Azure Traffic Manager

Traffic Manager is a **DNS-based global load balancer**. It does NOT proxy traffic — it returns DNS responses pointing users to the best endpoint.

```
              User in Asia             User in Europe
                   │                        │
                   ▼                        ▼
           ┌────────────────────────────────────────┐
           │         Azure Traffic Manager           │
           │         contoso.trafficmanager.net      │
           │                                        │
           │  Routing Method: Performance            │
           └───────────┬───────────────┬────────────┘
                       │               │
              DNS: East Asia      DNS: West Europe
                       │               │
                       ▼               ▼
             ┌──────────────┐  ┌──────────────┐
             │ App (SE Asia)│  │ App (W Europe)│
             │  app-sea     │  │  app-weu      │
             └──────────────┘  └──────────────┘
```

#### Traffic Manager Routing Methods
| Method | How It Works | Use Case |
|---|---|---|
| **Performance** | Routes to lowest-latency endpoint | Global users, geo-distributed apps |
| **Priority** | Always routes to primary; failover to secondary | Active/Passive DR |
| **Weighted** | Distributes by weight (0-1000) | A/B testing, gradual rollout |
| **Geographic** | Routes by user's geographic region | Data sovereignty, localization |
| **Multivalue** | Returns multiple healthy endpoints | Redundancy in DNS response |
| **Subnet** | Routes by source IP subnet | Internal routing policies |

---

#### CLI Commands – Traffic Manager

```bash
# 1. Create Traffic Manager Profile
az network traffic-manager profile create \
  --resource-group rg-networking \
  --name tm-contoso \
  --routing-method Performance \
  --unique-dns-name contoso-tm-prod \
  --ttl 30 \
  --protocol HTTPS \
  --port 443 \
  --path /health

# 2. Add endpoint – Azure App Service (East Asia)
az network traffic-manager endpoint create \
  --resource-group rg-networking \
  --profile-name tm-contoso \
  --name ep-sea \
  --type azureEndpoints \
  --target-resource-id /subscriptions/<sub-id>/resourceGroups/rg-app/providers/Microsoft.Web/sites/app-sea \
  --endpoint-status Enabled

# 3. Add endpoint – Azure App Service (West Europe)
az network traffic-manager endpoint create \
  --resource-group rg-networking \
  --profile-name tm-contoso \
  --name ep-weu \
  --type azureEndpoints \
  --target-resource-id /subscriptions/<sub-id>/resourceGroups/rg-app/providers/Microsoft.Web/sites/app-weu \
  --endpoint-status Enabled

# 4. Add External Endpoint (non-Azure resource)
az network traffic-manager endpoint create \
  --resource-group rg-networking \
  --profile-name tm-contoso \
  --name ep-onprem \
  --type externalEndpoints \
  --target on-premise-app.contoso.com \
  --endpoint-location "East US" \
  --endpoint-status Enabled

# 5. Update endpoint weight (for Weighted routing)
az network traffic-manager endpoint update \
  --resource-group rg-networking \
  --profile-name tm-contoso \
  --name ep-sea \
  --type azureEndpoints \
  --weight 80

# 6. Update endpoint priority (for Priority routing)
az network traffic-manager endpoint update \
  --resource-group rg-networking \
  --profile-name tm-contoso \
  --name ep-sea \
  --type azureEndpoints \
  --priority 1

# 7. View profile details
az network traffic-manager profile show \
  --resource-group rg-networking \
  --name tm-contoso

# 8. Disable/Enable an endpoint
az network traffic-manager endpoint update \
  --resource-group rg-networking \
  --profile-name tm-contoso \
  --name ep-weu \
  --type azureEndpoints \
  --endpoint-status Disabled

# 9. Delete Traffic Manager profile
az network traffic-manager profile delete \
  --resource-group rg-networking \
  --name tm-contoso
```

> 💡 **Exam Tip:** Traffic Manager only routes DNS — it does **not terminate connections**. Users connect directly to the endpoint returned. This means it cannot do SSL offloading or URL inspection.

---

### Traffic Manager vs Application Gateway vs Load Balancer

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Decision Tree                                     │
│                                                                     │
│  Global traffic routing across regions?                             │
│       YES → Traffic Manager (DNS-based)                             │
│       NO  ↓                                                         │
│                                                                     │
│  Need Layer 7 features? (URL routing, WAF, SSL termination)         │
│       YES → Application Gateway                                     │
│       NO  → Azure Load Balancer (Layer 4)                           │
│                                                                     │
│  ┌────────────────┬──────────────────┬─────────────────┐           │
│  │ Traffic Manager│  App Gateway     │  Load Balancer  │           │
│  ├────────────────┼──────────────────┼─────────────────┤           │
│  │ DNS-based      │ HTTP/S, Layer 7  │ TCP/UDP, Layer 4│           │
│  │ Global         │ Regional         │ Regional        │           │
│  │ No WAF         │ WAF supported    │ No WAF          │           │
│  │ Any endpoint   │ Azure backends   │ Azure backends  │           │
│  └────────────────┴──────────────────┴─────────────────┘           │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Quick Reference – Key Ports & Protocols

| Service | Port | Protocol |
|---|---|---|
| HTTP | 80 | TCP |
| HTTPS | 443 | TCP |
| SSH | 22 | TCP |
| RDP | 3389 | TCP |
| SQL Server | 1433 | TCP |
| MySQL | 3306 | TCP |
| PostgreSQL | 5432 | TCP |
| DNS | 53 | UDP/TCP |
| SMTP | 25 | TCP |

---

## Exam Tips Summary

| Topic | Key Point |
|---|---|
| VNet Peering | Non-transitive; requires both directions |
| Reserved IPs | 5 IPs reserved per subnet (first 4 + last) |
| NSG | Stateful; evaluated by priority (lower = first) |
| NSG + Standard LB | Standard LB requires explicit NSG allow rules |
| App Gateway Subnet | Must be dedicated; no other resources allowed |
| Azure DNS | Hosts zones; does NOT register domains |
| Private DNS | Auto-register VM names with `--registration-enabled true` |
| Traffic Manager | DNS-based only; no traffic proxying or SSL offload |
| TM vs App GW | TM = global routing; App GW = regional L7 features |
| NSG + ASG | Use ASGs to group VMs; reference by name in rules |
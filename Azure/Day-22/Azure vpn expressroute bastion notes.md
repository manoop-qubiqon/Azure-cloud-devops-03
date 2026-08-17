# Azure VPN Gateway, ExpressRoute & Bastion – Detailed Study Notes


---

## Table of Contents
1. [VPN Gateway](#1-vpn-gateway)
2. [ExpressRoute](#2-expressroute)
3. [VPN Gateway vs ExpressRoute](#3-vpn-gateway-vs-expressroute)
4. [Azure Bastion](#4-azure-bastion)
5. [Exam Tips Summary](#5-exam-tips-summary)

---

## 1. VPN Gateway

### What is a VPN Gateway?
An **Azure VPN Gateway** sends encrypted traffic between an Azure VNet and an on-premises network (or another VNet) over the **public Internet** using IPsec/IKE tunnels.

```
On-Premises Network                          Azure VNet
10.1.0.0/16                                  10.0.0.0/16
                                             
┌──────────────────────┐                  ┌──────────────────────┐
│  Corporate Office     │                  │  Azure Region        │
│                       │                  │                      │
│  ┌────────────────┐   │  IPsec/IKE       │  ┌────────────────┐ │
│  │  On-Prem VPN   │   │  Tunnel over     │  │  VPN Gateway   │ │
│  │  Device        │◄──┼──Public Internet─┼─►│  (GatewaySubnet│ │
│  │  (Cisco/Juniper│   │  (Encrypted)     │  │   10.0.255.0/27│ │
│  └────────────────┘   │                  │  └────────────────┘ │
│  Private: 10.1.0.0/16 │                  │  Subnet-Web        │ │
└──────────────────────┘                  │  10.0.1.0/24        │ │
                                          └──────────────────────┘
```

---

### VPN Gateway Types

| Type | Description | Use Case |
|---|---|---|
| **Route-Based** | Uses routing table to direct packets; supports IKEv2 | Recommended; supports P2S, S2S, VNet-to-VNet |
| **Policy-Based** | Uses static policies; IKEv1 only | Legacy; only 1 S2S tunnel; no P2S support |

> ⚠️ **Exam Tip:** Always use **Route-Based** unless forced by legacy device. Policy-Based supports only **1 tunnel** and **no P2S**.

---

### VPN Gateway SKUs

| SKU | Max S2S Tunnels | Max P2S Connections | Throughput | Zone Redundant |
|---|---|---|---|---|
| Basic | 10 | 128 | 100 Mbps | No |
| VpnGw1 | 30 | 250 | 650 Mbps | No |
| VpnGw2 | 30 | 500 | 1 Gbps | No |
| VpnGw3 | 30 | 1000 | 1.25 Gbps | No |
| VpnGw1AZ | 30 | 250 | 650 Mbps | Yes |
| VpnGw2AZ | 30 | 500 | 1 Gbps | Yes |
| VpnGw3AZ | 30 | 1000 | 1.25 Gbps | Yes |

> ⚠️ **Exam Tip:** **Basic SKU** does NOT support VNet-to-VNet, IKEv2, or BGP. Avoid in production.

---

### VPN Connection Types

```
┌──────────────────────────────────────────────────────┐
│              VPN Connection Types                     │
│                                                      │
│  S2S (Site-to-Site)                                  │
│  ──────────────────                                  │
│  On-Prem VPN Device ◄──── IPsec Tunnel ────► Azure  │
│  Fixed public IP required on on-prem device          │
│                                                      │
│  P2S (Point-to-Site)                                 │
│  ──────────────────                                  │
│  Individual Client ◄──── VPN Client App ────► Azure │
│  Works from anywhere; no fixed public IP needed      │
│  Protocols: OpenVPN, IKEv2, SSTP                     │
│                                                      │
│  VNet-to-VNet                                        │
│  ─────────────                                       │
│  Azure VNet ◄──── IPsec Tunnel ────► Azure VNet     │
│  Alternative to peering; cross-subscription/region  │
└──────────────────────────────────────────────────────┘
```

#### P2S Protocol Comparison
| Protocol | OS Support | Notes |
|---|---|---|
| OpenVPN (SSL/TLS) | Windows, macOS, Linux, iOS, Android | Most flexible; uses port 443 |
| IKEv2 | Windows, macOS, Linux | Fast reconnect; native macOS support |
| SSTP | Windows only | Uses port 443; good for firewalls |

---

### CLI Commands – VPN Gateway (Site-to-Site)

#### Step 1: Create GatewaySubnet (mandatory name)
```bash
az network vnet subnet create \
  --resource-group rg-networking \
  --vnet-name vnet-prod \
  --name GatewaySubnet \
  --address-prefix 10.0.255.0/27
```

> ⚠️ The subnet MUST be named exactly **GatewaySubnet**. No other resources can be in it.

#### Step 2: Create Public IP for VPN Gateway
```bash
az network public-ip create \
  --resource-group rg-networking \
  --name pip-vpngw \
  --sku Standard \
  --allocation-method Static \
  --zone 1 2 3
```

#### Step 3: Create VPN Gateway (takes 30–45 minutes)
```bash
az network vnet-gateway create \
  --resource-group rg-networking \
  --name vpngw-prod \
  --location eastus \
  --public-ip-address pip-vpngw \
  --vnet vnet-prod \
  --gateway-type Vpn \
  --vpn-type RouteBased \
  --sku VpnGw2 \
  --no-wait
```

```bash
# Check provisioning status
az network vnet-gateway show \
  --resource-group rg-networking \
  --name vpngw-prod \
  --query "provisioningState" \
  --output tsv
```

#### Step 4: Create Local Network Gateway (represents on-premises)
```bash
az network local-gateway create \
  --resource-group rg-networking \
  --name lgw-onprem \
  --location eastus \
  --gateway-ip-address 203.0.113.50 \
  --local-address-prefixes 10.1.0.0/16 10.2.0.0/16
```

> `--gateway-ip-address` = public IP of your on-premises VPN device
> `--local-address-prefixes` = on-premises subnets to route through the tunnel

#### Step 5: Create the VPN Connection (S2S)
```bash
az network vpn-connection create \
  --resource-group rg-networking \
  --name conn-onprem-s2s \
  --vnet-gateway1 vpngw-prod \
  --local-gateway2 lgw-onprem \
  --shared-key "Str0ngPSK!2024" \
  --connection-type IPSec \
  --enable-bgp false
```

#### Step 6: Verify Connection
```bash
# Show connection status
az network vpn-connection show \
  --resource-group rg-networking \
  --name conn-onprem-s2s \
  --query "connectionStatus" \
  --output tsv

# List all VPN connections
az network vpn-connection list \
  --resource-group rg-networking \
  --output table

# Get shared key
az network vpn-connection shared-key show \
  --resource-group rg-networking \
  --connection-name conn-onprem-s2s
```

---

### CLI Commands – Point-to-Site (P2S) VPN

```bash
# 1. Generate root certificate (Linux/openssl)
openssl genrsa -out P2SRootKey.pem 2048
openssl req -new -x509 -days 3650 -key P2SRootKey.pem \
  -out P2SRootCert.pem \
  -subj "/C=IN/ST=Kerala/O=Contoso/CN=P2SRootCert"

# Extract base64-encoded public cert data (no header/footer lines)
CERT_DATA=$(openssl x509 -in P2SRootCert.pem -outform DER | base64 | tr -d '\n')

# 2. Configure P2S on existing VPN Gateway
az network vnet-gateway update \
  --resource-group rg-networking \
  --name vpngw-prod \
  --address-prefixes 172.16.0.0/24 \
  --client-protocol OpenVPN \
  --root-cert-name P2SRootCert \
  --root-cert-data "$CERT_DATA"

# 3. Download VPN client configuration package
az network vnet-gateway vpn-client generate \
  --resource-group rg-networking \
  --name vpngw-prod \
  --processor-architecture Amd64
```

---

### CLI Commands – VNet-to-VNet VPN

```bash
# Assumes vpngw-prod (vnet-prod, East US) and vpngw-dr (vnet-dr, West US) exist

# Connection: East US → West US
az network vpn-connection create \
  --resource-group rg-networking \
  --name conn-vnet-eastus-to-westus \
  --vnet-gateway1 vpngw-prod \
  --vnet-gateway2 vpngw-dr \
  --shared-key "VNet2VNetPSK2024!" \
  --connection-type Vnet2Vnet

# Connection: West US → East US (reverse direction required)
az network vpn-connection create \
  --resource-group rg-dr \
  --name conn-vnet-westus-to-eastus \
  --vnet-gateway1 vpngw-dr \
  --vnet-gateway2 vpngw-prod \
  --shared-key "VNet2VNetPSK2024!" \
  --connection-type Vnet2Vnet
```

---

### Active-Active vs Active-Passive VPN Gateway

```
Active-Passive (Default)
─────────────────────────
On-Prem ◄──── Tunnel 1 (Active) ────► GW Instance 0 ┐
                                                      │ Azure VNet
               Tunnel 2 (Standby) ──► GW Instance 1 ┘
               (takes over on failover ~10-15s)

Active-Active (High Availability)
──────────────────────────────────
               Tunnel 1 ────► GW Instance 0 ┐
On-Prem ◄────                               │ Azure VNet
               Tunnel 2 ────► GW Instance 1 ┘
               (both tunnels carry traffic simultaneously)
```

```bash
# Enable Active-Active mode (requires 2 public IPs)
az network public-ip create \
  --resource-group rg-networking \
  --name pip-vpngw-2 \
  --sku Standard \
  --allocation-method Static

az network vnet-gateway update \
  --resource-group rg-networking \
  --name vpngw-prod \
  --public-ip-addresses pip-vpngw pip-vpngw-2 \
  --enable-active-active true
```

---

### BGP with VPN Gateway

BGP (Border Gateway Protocol) enables dynamic routing — no need to manually specify every on-premises subnet.

```bash
# Create VPN Gateway with BGP enabled
az network vnet-gateway create \
  --resource-group rg-networking \
  --name vpngw-bgp \
  --vnet vnet-prod \
  --public-ip-address pip-vpngw \
  --gateway-type Vpn \
  --vpn-type RouteBased \
  --sku VpnGw2 \
  --asn 65010 \
  --bgp-peering-address 10.0.255.254

# Create Local Gateway with BGP
az network local-gateway create \
  --resource-group rg-networking \
  --name lgw-onprem-bgp \
  --gateway-ip-address 203.0.113.50 \
  --local-address-prefixes 10.1.0.0/16 \
  --asn 65020 \
  --bgp-peering-address 10.1.0.1

# Create connection with BGP enabled
az network vpn-connection create \
  --resource-group rg-networking \
  --name conn-bgp \
  --vnet-gateway1 vpngw-bgp \
  --local-gateway2 lgw-onprem-bgp \
  --shared-key "BGPKey2024!" \
  --enable-bgp true

# View learned BGP routes
az network vnet-gateway list-learned-routes \
  --resource-group rg-networking \
  --name vpngw-bgp \
  --output table
```

---

## 2. ExpressRoute

### What is ExpressRoute?
**ExpressRoute** provides a **private, dedicated connection** between your on-premises network and Azure datacenters — bypassing the public Internet entirely. Traffic goes through a connectivity provider (ISP/Exchange Provider).

```
                    ┌──────────────────────────────────────────────┐
                    │              Microsoft Network               │
                    │                                              │
On-Premises         │  Microsoft Edge    ExpressRoute Circuit      │
Network             │  ┌─────────────┐   ┌──────────────────┐    │
┌──────────────┐    │  │  MSEERouter │   │  Virtual Network │    │
│  Corp HQ     │    │  │  (Primary)  │   │  Gateway         │    │
│  10.1.0.0/16 │◄───┼─►│             │◄─►│  (UltraPerf SKU) │◄──┤
│              │    │  │  MSEERouter │   │                  │    │
│  MPLS/Fiber  │    │  │  (Secondary)│   └──────────────────┘    │
└──────────────┘    │  └─────────────┘           │               │
        │           │         ▲                  ▼               │
        ▼           │         │         ┌──────────────┐         │
┌──────────────┐    │  ┌──────┴──────┐  │  Azure       │         │
│  Connectivity│    │  │  Exchange   │  │  Services    │         │
│  Provider    │────┼─►│  Provider / │  │  (Storage,   │         │
│  (Equinix,   │    │  │  ISP        │  │   AAD, O365) │         │
│  AT&T, etc.) │    │  └─────────────┘  └──────────────┘         │
└──────────────┘    │                                              │
                    └──────────────────────────────────────────────┘
```

---

### ExpressRoute Circuit SKUs & Tiers

#### Billing Model
| Tier | Egress Billing | Best For |
|---|---|---|
| **Metered** | Pay per GB of outbound data | Variable/low traffic |
| **Unlimited** | Flat monthly fee | High-volume traffic |

#### Circuit SKU (Reach)
| SKU | Connectivity Scope |
|---|---|
| **Local** | Only 1 Azure region near your peering location |
| **Standard** | All regions within the same geopolitical boundary |
| **Premium** | Global (all Azure regions) + Microsoft 365 + Dynamics |

#### Bandwidth Options
50 Mbps, 100 Mbps, 200 Mbps, 500 Mbps, 1 Gbps, 2 Gbps, 5 Gbps, 10 Gbps

---

### ExpressRoute Peering Types

```
┌──────────────────────────────────────────────────────────┐
│  ExpressRoute Circuit                                    │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │  Private Peering                                   │ │
│  │  → Azure VNets (IaaS: VMs, Storage, App Service)  │ │
│  │  → Your IPs ↔ Azure private IPs                   │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │  Microsoft Peering                                 │ │
│  │  → Microsoft 365, Dynamics 365                     │ │
│  │  → Azure PaaS public endpoints (Storage, SQL)      │ │
│  │  → Requires public/registered IP prefixes          │ │
│  └────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────┘
```

> ⚠️ **Exam Tip:** **Public Peering** was deprecated and replaced by **Microsoft Peering**. If you see "Public Peering" in exam questions, treat it as Microsoft Peering.

---

### CLI Commands – ExpressRoute

#### Create an ExpressRoute Circuit
```bash
# 1. Create the circuit (generates a Service Key for your provider)
az network express-route create \
  --resource-group rg-networking \
  --name er-circuit-prod \
  --location eastus \
  --bandwidth 1000 \
  --peering-location "Silicon Valley" \
  --provider "Equinix" \
  --sku-family MeteredData \
  --sku-tier Standard

# 2. Get the Service Key (share with your connectivity provider)
az network express-route show \
  --resource-group rg-networking \
  --name er-circuit-prod \
  --query serviceKey \
  --output tsv

# 3. Check provisioning state (wait for provider to provision)
az network express-route show \
  --resource-group rg-networking \
  --name er-circuit-prod \
  --query "{ServiceProvider:serviceProviderProvisioningState, Circuit:provisioningState}" \
  --output table
```

#### List Available Providers and Locations
```bash
# List all ExpressRoute providers
az network express-route list-service-providers \
  --output table

# Filter providers by location
az network express-route list-service-providers \
  --query "[?contains(peeringLocations, 'Silicon Valley')].[name]" \
  --output table
```

#### Configure Private Peering
```bash
az network express-route peering create \
  --resource-group rg-networking \
  --circuit-name er-circuit-prod \
  --peering-type AzurePrivatePeering \
  --peer-asn 65020 \
  --primary-peer-subnet 192.168.100.0/30 \
  --secondary-peer-subnet 192.168.100.4/30 \
  --vlan-id 100
```

#### Configure Microsoft Peering
```bash
az network express-route peering create \
  --resource-group rg-networking \
  --circuit-name er-circuit-prod \
  --peering-type MicrosoftPeering \
  --peer-asn 65020 \
  --primary-peer-subnet 203.0.113.0/30 \
  --secondary-peer-subnet 203.0.113.4/30 \
  --vlan-id 200 \
  --advertised-public-prefixes "203.0.113.0/24"
```

#### Link ExpressRoute Circuit to a VNet Gateway
```bash
# 1. Create ExpressRoute Gateway in GatewaySubnet
az network public-ip create \
  --resource-group rg-networking \
  --name pip-ergw \
  --sku Standard \
  --allocation-method Static

az network vnet-gateway create \
  --resource-group rg-networking \
  --name ergw-prod \
  --location eastus \
  --public-ip-address pip-ergw \
  --vnet vnet-prod \
  --gateway-type ExpressRoute \
  --sku UltraPerformance \
  --no-wait

# 2. Get circuit resource ID
ER_ID=$(az network express-route show \
  --resource-group rg-networking \
  --name er-circuit-prod \
  --query id --output tsv)

# 3. Connect VNet gateway to ExpressRoute circuit
az network vpn-connection create \
  --resource-group rg-networking \
  --name conn-er-prod \
  --vnet-gateway1 ergw-prod \
  --express-route-circuit2 "$ER_ID" \
  --routing-weight 0
```

#### ExpressRoute Gateway SKUs
| SKU | Max Circuits | Throughput |
|---|---|---|
| Standard | 4 | 1 Gbps |
| HighPerformance | 4 | 2 Gbps |
| UltraPerformance | 16 | 10 Gbps |
| ErGw1AZ | 4 | 1 Gbps (Zone Redundant) |
| ErGw2AZ | 8 | 2 Gbps (Zone Redundant) |
| ErGw3AZ | 16 | 10 Gbps (Zone Redundant) |

#### Manage and Monitor ExpressRoute
```bash
# List circuits
az network express-route list \
  --resource-group rg-networking \
  --output table

# View circuit stats
az network express-route stats \
  --resource-group rg-networking \
  --name er-circuit-prod

# Update bandwidth
az network express-route update \
  --resource-group rg-networking \
  --name er-circuit-prod \
  --bandwidth 2000

# Delete circuit
az network express-route delete \
  --resource-group rg-networking \
  --name er-circuit-prod
```

---

### ExpressRoute FastPath

FastPath bypasses the ExpressRoute Gateway for data path traffic — sending packets directly to VMs, reducing latency.

```
Normal ExpressRoute Data Path:
On-Prem ──► MSEE ──► ExpressRoute GW ──► VM

FastPath Data Path:
On-Prem ──► MSEE ──────────────────────► VM
                    (GW bypassed for data)
```

```bash
# Enable FastPath on an existing connection
az network vpn-connection update \
  --resource-group rg-networking \
  --name conn-er-prod \
  --express-route-gateway-bypass true
```

> 💡 **Exam Tip:** FastPath requires **UltraPerformance** or **ErGw3AZ** gateway SKU.

---

## 3. VPN Gateway vs ExpressRoute

```
┌─────────────────────────────────────────────────────────────────────┐
│                   Decision Matrix                                   │
│                                                                     │
│  Feature          VPN Gateway          ExpressRoute                 │
│  ─────────────────────────────────────────────────────             │
│  Connection       Public Internet      Private / Dedicated          │
│  Encryption       Yes (IPsec)          Optional (MACSec)            │
│  Bandwidth        Up to 1.25 Gbps      Up to 100 Gbps              │
│  Latency          Variable             Consistent / Low             │
│  SLA              99.9% (A-A)          99.95%                       │
│  Setup Time       Minutes / Hours      Weeks (provider needed)      │
│  Cost             Lower                Higher                       │
│  Reliability      Internet-dependent   Provider SLA backed          │
│  P2S support      Yes                  No                           │
│  Use Case         Dev/test, backup,    Production, compliance,      │
│                   small offices        large data transfer          │
└─────────────────────────────────────────────────────────────────────┘
```

### Coexisting VPN + ExpressRoute

```
On-Premises
     │
     ├──── ExpressRoute (Primary, private) ────► Azure VNet
     │
     └──── VPN Gateway (Failover, IPsec)  ────► Azure VNet
```

```bash
# Both can coexist in the same VNet using separate gateways
# GatewaySubnet hosts BOTH the ER Gateway and VPN Gateway

# Create VPN Gateway (alongside ER Gateway)
az network vnet-gateway create \
  --resource-group rg-networking \
  --name vpngw-failover \
  --vnet vnet-prod \
  --public-ip-address pip-vpngw \
  --gateway-type Vpn \
  --vpn-type RouteBased \
  --sku VpnGw1 \
  --no-wait
```

> ⚠️ **Exam Tip:** You **cannot** use the same GatewaySubnet with two gateways of different types. Azure allows coexistence but requires proper sizing — use `/27` or larger for GatewaySubnet.

---

## 4. Azure Bastion

### What is Azure Bastion?
**Azure Bastion** is a fully managed PaaS service that provides secure RDP and SSH connectivity to VMs **directly from the Azure portal** over TLS (port 443), without exposing VMs to the public Internet.

```
                        HTTPS (Port 443)
User Browser ──────────────────────────────► Azure Bastion
                                                │
                                                │ RDP/SSH (Private)
                                                ▼
                         ┌──────────────────────────────┐
                         │       Azure VNet              │
                         │  ┌────────────────────────┐  │
                         │  │  AzureBastionSubnet     │  │
                         │  │  (10.0.100.0/26)        │  │
                         │  │  [Bastion Host]         │  │
                         │  └──────────┬─────────────┘  │
                         │             │ Private NIC     │
                         │    ┌────────┼────────┐        │
                         │    ▼        ▼        ▼        │
                         │  [VM-1]  [VM-2]  [VM-3]       │
                         │  No Public IP needed!          │
                         └──────────────────────────────┘
```

### Why Bastion vs Traditional RDP/SSH?

| Method | Exposure | Requirements | Security Risk |
|---|---|---|---|
| Public IP + NSG | VM has public IP | Open port 22/3389 to Internet | High — brute force, scan attacks |
| Jump Box / Bastion VM | Custom VM exposed | Manage jump VM patching | Medium — still a VM to maintain |
| Azure Bastion | No public IP on target VM | Only port 443 from browser | Low — fully managed by Microsoft |

---

### Bastion SKUs

| Feature | Basic | Standard | Premium |
|---|---|---|---|
| RDP/SSH via Portal | ✅ | ✅ | ✅ |
| Native Client Support | ❌ | ✅ | ✅ |
| IP-based connection | ❌ | ✅ | ✅ |
| Shareable Link | ❌ | ✅ | ✅ |
| Session Recording | ❌ | ❌ | ✅ |
| Private-only Bastion | ❌ | ❌ | ✅ |
| Scale Units | 2 (fixed) | 2–50 | 2–50 |
| Concurrent Sessions | ~25 | Up to 250 | Up to 250 |

> 💡 **Exam Tip:** Basic SKU only allows portal-based connections. Standard unlocks native RDP/SSH clients and IP-based access.

---

### CLI Commands – Azure Bastion

#### Step 1: Create AzureBastionSubnet (mandatory name, minimum /26)
```bash
az network vnet subnet create \
  --resource-group rg-networking \
  --vnet-name vnet-prod \
  --name AzureBastionSubnet \
  --address-prefix 10.0.100.0/26
```

> ⚠️ Subnet MUST be named exactly **AzureBastionSubnet**. Minimum size is **/26** (64 IPs).

#### Step 2: Create Public IP for Bastion (Standard SKU, Static)
```bash
az network public-ip create \
  --resource-group rg-networking \
  --name pip-bastion \
  --sku Standard \
  --allocation-method Static \
  --location eastus
```

#### Step 3: Create Bastion Host
```bash
# Basic SKU
az network bastion create \
  --resource-group rg-networking \
  --name bastion-prod \
  --location eastus \
  --vnet-name vnet-prod \
  --public-ip-address pip-bastion \
  --sku Basic

# Standard SKU (recommended)
az network bastion create \
  --resource-group rg-networking \
  --name bastion-prod \
  --location eastus \
  --vnet-name vnet-prod \
  --public-ip-address pip-bastion \
  --sku Standard \
  --scale-units 4
```

#### Step 4: Connect to VM via Bastion (CLI – Native Client)
```bash
# SSH to Linux VM using Bastion (Standard SKU required)
az network bastion ssh \
  --resource-group rg-networking \
  --name bastion-prod \
  --target-resource-id /subscriptions/<sub-id>/resourceGroups/rg-vms/providers/Microsoft.Compute/virtualMachines/vm-linux1 \
  --auth-type ssh-key \
  --username azureuser \
  --ssh-key ~/.ssh/id_rsa

# RDP to Windows VM using Bastion (Standard SKU required)
az network bastion rdp \
  --resource-group rg-networking \
  --name bastion-prod \
  --target-resource-id /subscriptions/<sub-id>/resourceGroups/rg-vms/providers/Microsoft.Compute/virtualMachines/vm-win1

# Connect by IP address (Standard SKU, IP-based connection)
az network bastion ssh \
  --resource-group rg-networking \
  --name bastion-prod \
  --target-ip-address 10.0.1.4 \
  --auth-type password \
  --username azureuser
```

#### Step 5: Create VM WITHOUT Public IP (Bastion access only)
```bash
# Create VM with no public IP – Bastion handles access
az vm create \
  --resource-group rg-vms \
  --name vm-private-1 \
  --image Ubuntu2204 \
  --vnet-name vnet-prod \
  --subnet subnet-web \
  --public-ip-address '""' \
  --nsg "" \
  --admin-username azureuser \
  --generate-ssh-keys
```

#### Manage and Monitor Bastion
```bash
# Show Bastion details
az network bastion show \
  --resource-group rg-networking \
  --name bastion-prod

# List all Bastion hosts in subscription
az network bastion list --output table

# Update Bastion SKU (Basic → Standard)
az network bastion update \
  --resource-group rg-networking \
  --name bastion-prod \
  --sku Standard \
  --scale-units 4

# Delete Bastion
az network bastion delete \
  --resource-group rg-networking \
  --name bastion-prod
```

---

### Bastion Tunneling (Port Forwarding)

Standard SKU supports tunneling — allows native desktop clients (like PuTTY, Windows Remote Desktop) to connect through Bastion.

```bash
# Create a tunnel to a VM on port 22 (SSH)
az network bastion tunnel \
  --resource-group rg-networking \
  --name bastion-prod \
  --target-resource-id /subscriptions/<sub-id>/resourceGroups/rg-vms/providers/Microsoft.Compute/virtualMachines/vm-linux1 \
  --resource-port 22 \
  --port 2222

# Now connect locally using standard SSH client:
# ssh azureuser@127.0.0.1 -p 2222

# Tunnel for RDP (port 3389)
az network bastion tunnel \
  --resource-group rg-networking \
  --name bastion-prod \
  --target-resource-id /subscriptions/<sub-id>/resourceGroups/rg-vms/providers/Microsoft.Compute/virtualMachines/vm-win1 \
  --resource-port 3389 \
  --port 13389

# Connect with Windows Remote Desktop to: 127.0.0.1:13389
```

---

### Shareable Bastion Links (Standard SKU)

Generate a time-limited URL that allows users to connect to a VM without Azure portal access.

```bash
# Generate shareable link (portal-based; not yet in CLI)
# Available in Azure Portal → Bastion → Shareable Links → + Add
# URL format: https://bastion.azure.com/api/shareable-url/<token>
```

---

### NSG Rules for Bastion

Bastion requires specific NSG rules on **AzureBastionSubnet**:

```bash
# Create NSG for Bastion subnet
az network nsg create \
  --resource-group rg-networking \
  --name nsg-bastion

# INBOUND: Allow HTTPS from Internet (user browser)
az network nsg rule create \
  --resource-group rg-networking \
  --nsg-name nsg-bastion \
  --name Allow-HTTPS-Inbound \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes Internet \
  --destination-address-prefixes '*' \
  --destination-port-ranges 443

# INBOUND: Allow Gateway Manager (control plane)
az network nsg rule create \
  --resource-group rg-networking \
  --nsg-name nsg-bastion \
  --name Allow-GatewayManager-Inbound \
  --priority 110 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes GatewayManager \
  --destination-address-prefixes '*' \
  --destination-port-ranges 443

# INBOUND: Allow Azure Load Balancer
az network nsg rule create \
  --resource-group rg-networking \
  --nsg-name nsg-bastion \
  --name Allow-AzureLB-Inbound \
  --priority 120 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes AzureLoadBalancer \
  --destination-address-prefixes '*' \
  --destination-port-ranges 443

# OUTBOUND: Allow SSH/RDP to VMs in VNet
az network nsg rule create \
  --resource-group rg-networking \
  --nsg-name nsg-bastion \
  --name Allow-SSH-RDP-Outbound \
  --priority 100 \
  --direction Outbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes '*' \
  --destination-address-prefixes VirtualNetwork \
  --destination-port-ranges 22 3389

# OUTBOUND: Allow Azure platform communication
az network nsg rule create \
  --resource-group rg-networking \
  --nsg-name nsg-bastion \
  --name Allow-Azure-Cloud-Outbound \
  --priority 110 \
  --direction Outbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes '*' \
  --destination-address-prefixes AzureCloud \
  --destination-port-ranges 443

# Associate NSG with AzureBastionSubnet
az network vnet subnet update \
  --resource-group rg-networking \
  --vnet-name vnet-prod \
  --name AzureBastionSubnet \
  --network-security-group nsg-bastion
```

---

### Full Architecture: VPN + Bastion + Private VMs

```
                                   Azure (East US)
                                  ┌──────────────────────────────────────┐
On-Premises                       │  VNet: 10.0.0.0/16                   │
┌────────────┐   IPsec/ER         │                                      │
│ Corp HQ    │◄──────────────────►│  ┌─────────────────────┐            │
│ 10.1.0.0/16│                   │  │  GatewaySubnet      │            │
└────────────┘                   │  │  10.0.255.0/27      │            │
                                  │  │  [VPN GW] [ER GW]  │            │
User (Browser)                    │  └─────────────────────┘            │
     │                            │                                      │
     │ HTTPS:443                  │  ┌─────────────────────┐            │
     ▼                            │  │  AzureBastionSubnet │            │
     └───────────────────────────►│  │  10.0.100.0/26      │            │
                                  │  │  [Bastion Host]     │            │
                                  │  └──────────┬──────────┘            │
                                  │             │ Private SSH/RDP        │
                                  │  ┌──────────▼──────────┐            │
                                  │  │  subnet-web         │            │
                                  │  │  10.0.1.0/24        │            │
                                  │  │  [VM-1] [VM-2]      │            │
                                  │  │  No Public IPs!     │            │
                                  │  └─────────────────────┘            │
                                  └──────────────────────────────────────┘
```

---

## 5. Exam Tips Summary

| Topic | Key Point |
|---|---|
| GatewaySubnet | Must be named exactly **GatewaySubnet**; min **/27**; no other resources |
| AzureBastionSubnet | Must be named exactly **AzureBastionSubnet**; min **/26** |
| VPN Policy-Based | Only 1 tunnel; no P2S; IKEv1 only; legacy use only |
| VPN Route-Based | Recommended; supports S2S, P2S, VNet-to-VNet, IKEv2, BGP |
| Basic VPN SKU | No BGP, no VNet-to-VNet, no IKEv2 — avoid in production |
| VNet-to-VNet | Bidirectional — must create connections in BOTH directions |
| ExpressRoute Peering | Private = VNets; Microsoft = M365 / Azure PaaS public endpoints |
| ExpressRoute FastPath | Bypasses GW for data; needs UltraPerformance or ErGw3AZ |
| ExpressRoute Public Peering | Deprecated — replaced by Microsoft Peering |
| VPN vs ER | VPN = Internet/encrypted/cheap; ER = Private/fast/SLA-backed |
| Bastion Basic | Portal only; no native client; no IP-based; ~25 sessions |
| Bastion Standard | Native client, tunneling, IP-based, shareable links, up to 250 sessions |
| Bastion NSG | Must allow GatewayManager:443 inbound and AzureCloud:443 outbound |
| Bastion + VM | Target VMs need NO public IP when using Bastion |
| Active-Active VPN | Both instances carry traffic; needs 2 public IPs on gateway |
| BGP with VPN | Dynamic routing; no need to list every on-prem subnet manually |
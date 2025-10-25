# Network Architecture

## Overview

The homelab uses three VMware Workstation virtual networks to create isolated segments for different security testing purposes. This design prevents accidental compromise of production systems while enabling realistic attack scenarios.

## Network Topology

```
┌─────────────────────────────────────────────────────────────────┐
│                         NAT Network                              │
│                      (Internet Access)                           │
│                      192.168.x.0/24                             │
└────────────┬──────────────────────────────┬────────────────────┘
             │                              │
             │                              │
        ┌────▼────┐                    ┌────▼────┐
        │  Kali   │                    │ Splunk  │
        │   Red   │                    │  SIEM   │
        └────┬────┘                    └────┬────┘
             │                              │
             │                              │
┌────────────┴──────────────────────────────┴────────────────────┐
│                    Vulnerable Network                           │
│                  (Isolated Attack Range)                        │
│                      10.10.10.0/24                             │
└──┬────────────┬─────────────┬────────────────────────────┬─────┘
   │            │             │                            │
   │            │             │                            │
┌──▼─────┐ ┌───▼────┐   ┌────▼────┐                  ┌────▼────┐
│ Kali   │ │ Meta-  │   │  DVWA   │                  │ Splunk  │
│  Red   │ │sploit- │   │  (Web)  │                  │  SIEM   │
│        │ │ able   │   │         │                  │         │
└────────┘ └────────┘   └─────────┘                  └────┬────┘
                                                           │
                                                           │
┌──────────────────────────────────────────────────────────┴─────┐
│                   Professional Network                         │
│              (Production Simulation)                           │
│                    172.16.0.0/24                              │
└──┬────────┬────────────┬────────────┬────────────┬────────┬───┘
   │        │            │            │            │        │
┌──▼───┐ ┌─▼────┐  ┌────▼─────┐ ┌────▼────┐ ┌────▼───┐ ┌──▼────┐
│ Kali │ │Splunk│  │ Windows  │ │ Windows │ │Windows │ │ (Future│
│ Red  │ │ SIEM │  │ Server   │ │   10    │ │   11   │ │  VMs) │
│      │ │      │  │   2022   │ │ Client  │ │ Client │ │       │
└──────┘ └──────┘  └──────────┘ └─────────┘ └────────┘ └───────┘
```

## Network Segments

### NAT Network (vmnet8)
**IP Range:** 192.168.x.0/24 (VMware default)  
**Gateway:** 192.168.x.2 (VMware NAT gateway)  
**DNS:** 192.168.x.2 or external DNS  
**Purpose:** Internet connectivity for updates and tool downloads

**Connected Systems:**
- Kali Red (eth0 or ens33) - Primary interface for tool downloads, exploit-db updates
- Splunk (ens33) - Splunk app updates, threat intel feeds, package repositories

**Security Considerations:**
- Limited to systems that require internet access
- Vulnerable targets intentionally excluded
- Monitor outbound connections from Kali for data exfiltration during practice scenarios

### Vulnerable Network (vmnet2 - Host-Only)
**IP Range:** 10.10.10.0/24  
**Gateway:** None (isolated)  
**DHCP:** Disabled  
**Purpose:** Contained environment for exploitation practice

**IP Assignments (Static Recommended):**
- 10.10.10.1 - Kali Red (eth1 or ens34)
- 10.10.10.10 - Metasploitable
- 10.10.10.20 - DVWA
- 10.10.10.100 - Splunk (ens34)

**Security Considerations:**
- **No internet access** - completely isolated from external networks
- No routing between this network and Professional Network
- All traffic contained within VMware virtual switch
- Ideal for testing ransomware, worms, and aggressive exploits without risk

**Monitoring:**
- Splunk interface on this network captures all attack traffic
- Enables building SIEM detection rules based on real exploitation attempts
- Log all Kali activity to Splunk for practice with attacker behavior analysis

### Professional Network (vmnet3 - Host-Only)
**IP Range:** 172.16.0.0/24  
**Gateway:** 172.16.0.1 (Windows Server 2022 when configured)  
**DHCP:** Windows Server 2022 DHCP service (when AD is deployed)  
**Purpose:** Simulates enterprise Active Directory environment

**IP Assignments:**
- 172.16.0.1 - Windows Server 2022 (Domain Controller)
- 172.16.0.2 - Splunk (ens35)
- 172.16.0.10 - Kali Red (eth2 or ens35)
- 172.16.0.20-50 - Windows 10 Client (DHCP or static)
- 172.16.0.51-80 - Windows 11 Client (DHCP or static)

**Security Considerations:**
- Isolated from internet unless explicitly routed through DC
- Enables AD-specific attacks: Kerberoasting, Pass-the-Hash, Golden Ticket, etc.
- Kali presence simulates insider threat or compromised workstation
- All domain authentication events logged to Splunk

**Monitoring:**
- Splunk configured as Windows Event Log collector
- Sysmon deployed on all Windows systems forwarding to Splunk
- Monitors authentication attempts, privilege escalation, lateral movement

## Multi-Homed Configuration

### Kali Red (3 NICs)
**Why multi-homed:** Enables attacking all network segments and downloading tools/exploits

- **eth0/ens33** (NAT): Internet access for tools, updates, exploit-db
- **eth1/ens34** (Vulnerable): Attack interface for Metasploitable/DVWA
- **eth2/ens35** (Professional): Simulates compromised internal system or insider threat

**Network Priority:**
- Default route via eth0 (NAT) for internet
- Static routes for 10.10.10.0/24 and 172.16.0.0/24 via appropriate interfaces

### Splunk SIEM (3 NICs)
**Why multi-homed:** Collects logs from all network segments

- **ens33** (NAT): Internet access for Splunk updates, apps, threat intelligence feeds
- **ens34** (Vulnerable): Monitors attack traffic, captures exploit attempts
- **ens35** (Professional): Receives Windows Event Logs, Sysmon, AD authentication logs

**Forwarding Configuration:**
- Universal Forwarders on Windows systems send logs to 172.16.0.2:9997
- Syslog receivers on all three interfaces
- No routing between networks - Splunk only receives/processes logs

## VMware Workstation Configuration

### Creating Virtual Networks

**NAT Network (vmnet8):**
- Default VMware NAT network
- No configuration changes needed
- Subnet typically 192.168.x.0/24

**Vulnerable Network (vmnet2):**
```
Edit > Virtual Network Editor (Administrator)
1. Add Network > vmnet2
2. Type: Host-only
3. Subnet: 10.10.10.0
4. Subnet Mask: 255.255.255.0
5. Disable "Use local DHCP service"
6. Disable "Connect to host network adapter"
7. Apply
```

**Professional Network (vmnet3):**
```
Edit > Virtual Network Editor (Administrator)
1. Add Network > vmnet3
2. Type: Host-only
3. Subnet: 172.16.0.0
4. Subnet Mask: 255.255.255.0
5. Enable "Use local DHCP service" (or manage via Windows Server DHCP)
6. Disable "Connect to host network adapter"
7. Apply
```

### Assigning NICs to VMs

**Example: Kali Red (3 NICs)**
```
VM Settings > Add > Network Adapter
- Adapter 1: NAT (vmnet8)
- Adapter 2: Custom (vmnet2)
- Adapter 3: Custom (vmnet3)
```

**Example: Metasploitable (1 NIC)**
```
VM Settings > Network Adapter
- Adapter 1: Custom (vmnet2) - Vulnerable Network only
```

## Security Best Practices

1. **Never bridge vulnerable VMs to host network** - keeps exploits contained
2. **Snapshot before dangerous operations** - easy rollback after ransomware/wiper tests
3. **Monitor Splunk during attacks** - builds practical SIEM correlation skills
4. **Document attack paths** - improves reporting and writeup skills for professional work
5. **Keep Kali and tools updated** - ensures realistic exploitation scenarios

## Troubleshooting

**VM can't reach internet on NAT network:**
- Check VMware NAT service is running: `services.msc` > "VMware NAT Service"
- Verify VM NIC is set to NAT (vmnet8)
- Check `/etc/resolv.conf` has valid DNS (192.168.x.2 or 8.8.8.8)

**VMs on host-only networks can't communicate:**
- Verify both VMs on same vmnetX (e.g., both on vmnet2)
- Check firewall rules on VMs aren't blocking traffic
- Confirm static IPs in same subnet (e.g., 10.10.10.1 and 10.10.10.10)

**Splunk not receiving logs:**
- Verify correct IP for Splunk on target network (check `ip a` or `ifconfig`)
- Check receiving port is open: `netstat -tulnp | grep 9997`
- Confirm forwarder configuration points to correct Splunk IP
- Check Splunk firewall rules allow inbound on 9997/tcp and 514/udp

---

**This architecture enables:**
- Safe exploitation practice without internet exposure
- Realistic SIEM deployment across multiple network segments
- Active Directory attack/defense scenarios
- Network segmentation testing and lateral movement practice

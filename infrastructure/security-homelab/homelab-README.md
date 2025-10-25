# Security Homelab - VMware Workstation Environment

A segmented virtualization lab for security research, SIEM deployment, and attack/defense practice. Built on VMware Workstation 17 with network isolation between vulnerable systems, attack platforms, and production-like environments.

## Lab Overview

**Purpose:** Hands-on security training, SIEM log analysis, vulnerability research, and Active Directory security testing.

**Hypervisor:** VMware Workstation 17 Pro  
**Host Hardware:**
- CPU: Intel i9-9900K (8C/16T)
- RAM: 96GB DDR4
- GPU: NVIDIA Quadro P1000

## Virtual Machines

| VM Name | OS | Role | Networks |
|---------|-------|------|----------|
| Kali Red | Kali Linux | Attack platform / penetration testing | NAT, Vulnerable, Professional |
| Metasploitable | Ubuntu (vulnerable) | Attack target / exploitation practice | Vulnerable |
| DVWA | Linux | Vulnerable web application testing | Vulnerable |
| Splunk | Ubuntu 24.04.3 LTS | SIEM / log aggregation & analysis | NAT, Vulnerable, Professional |
| WinServer2022 | Windows Server 2022 | Active Directory / domain controller | Professional |
| Win10-Client | Windows 10 | Domain-joined workstation | Professional |
| Win11-Client | Windows 11 | Domain-joined workstation | Professional |

## Network Architecture

The lab uses three isolated network segments to simulate real-world enterprise environments and enable attack/defense scenarios:

### 1. NAT Network (Internet Access)
- **Purpose:** Internet connectivity for updates, package downloads, and external research
- **Connected VMs:** Kali Red, Splunk
- **DHCP:** Enabled via VMware NAT
- **Subnet:** 192.168.x.0/24 (VMware default)

### 2. Vulnerable Network (Attack Range)
- **Purpose:** Isolated network for vulnerability exploitation without risk to other systems
- **Connected VMs:** Kali Red, Metasploitable, DVWA, Splunk
- **DHCP:** Disabled (static IPs recommended)
- **Subnet:** 10.10.10.0/24
- **No internet access** - fully isolated

### 3. Professional Network (Production Simulation)
- **Purpose:** Simulates enterprise environment with Active Directory, domain-joined workstations
- **Connected VMs:** Kali Red, Splunk, WinServer2022, Win10-Client, Win11-Client
- **DHCP:** Provided by Windows Server 2022 (when configured)
- **Subnet:** 172.16.0.0/24
- **No direct internet access** - routed through DC if needed

### Multi-Homed Systems

**Kali Red** - Connected to all three networks:
- Enables attacking vulnerable systems, testing professional network defenses, and downloading tools/exploits
- Acts as potential pivot point between networks in advanced scenarios

**Splunk** - Connected to all three networks:
- Collects logs from all segments
- Monitors attack traffic on Vulnerable Network
- Monitors AD authentication and security events on Professional Network
- Receives threat intelligence updates via NAT network

## Use Cases

### Attack/Defense Scenarios
- Practice exploitation techniques against Metasploitable and DVWA without risking production systems
- Test defensive tools and detection capabilities with Splunk SIEM
- Simulate lateral movement between networks via multi-homed attack platforms

### SIEM Training
- Configure Splunk to ingest Windows Event Logs, Sysmon, syslog, and web server logs
- Build detection rules and correlation searches for attack patterns
- Practice log analysis and incident investigation workflows

### Active Directory Security
- Deploy and configure AD DS on Windows Server 2022
- Practice AD enumeration, privilege escalation, and Kerberos attacks
- Test Group Policy hardening and security monitoring

### Vulnerability Research
- Test exploits in controlled environment
- Practice web application penetration testing with DVWA
- Develop and test custom scripts/tools against known-vulnerable systems

## Lab Capabilities

✅ Isolated attack range for safe exploitation practice  
✅ SIEM deployment with multi-network log aggregation  
✅ Active Directory domain for Windows security testing  
✅ Network segmentation mimicking enterprise architecture  
✅ Flexible configuration for various training scenarios  

## Next Steps

- [ ] Document detailed VM configuration procedures
- [ ] Create network diagram showing all connections
- [ ] Add Splunk configuration guide for log ingestion
- [ ] Document Active Directory setup on Windows Server 2022
- [ ] Add common attack scenario walkthroughs

## Skills Demonstrated

- Virtualization platform deployment (VMware Workstation)
- Network segmentation and design
- SIEM implementation and log management
- Security tool deployment (Kali, Splunk, vulnerable targets)
- Enterprise environment simulation (Active Directory)
- Multi-homed system configuration

---

**Status:** Active development and testing environment  
**Last Updated:** October 2025

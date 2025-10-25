# CrashCart - Technical Portfolio

**The proof of what I can do.**

This repository documents my technical capabilities across system administration, information security, infrastructure, and troubleshooting. Each section contains real-world examples, case studies, and project documentation demonstrating practical skills.

## Repository Purpose

CrashCart serves as evidence of technical competence through documented work. Not claims - proof. Not tutorials followed - problems solved. Not theoretical knowledge - hands-on implementation.

---

## Table of Contents

- [Infrastructure & Virtualization](#infrastructure--virtualization)
- [Information Security](#information-security)
- [System Administration](#system-administration)
- [Troubleshooting & Diagnostics](#troubleshooting--diagnostics)
- [Network Architecture](#network-architecture)
- [SIEM & Monitoring](#siem--monitoring)

---

## Infrastructure & Virtualization

### Security Homelab Environment
**Status:** Operational | **Last Updated:** October 2025

Multi-VM security research and training environment demonstrating infrastructure deployment, network segmentation, and enterprise simulation.

**Environment Specs:**
- **Hypervisor:** VMware Workstation 17 Pro
- **Host:** Intel i9-9900K, 96GB RAM, NVIDIA Quadro P1000
- **VMs:** 7 virtual machines across 3 isolated networks
- **Purpose:** Security research, SIEM deployment, attack/defense practice

**Virtual Machines:**
- Kali Red (Attack Platform) - Multi-homed across all networks
- Splunk Enterprise (SIEM) - Multi-homed log aggregation
- Metasploitable 2 (Vulnerable Target)
- DVWA (Web Application Testing)
- Windows Server 2022 (Domain Controller)
- Windows 10 Client (Domain Member)
- Windows 11 Client (Domain Member)

**Network Architecture:**
- **NAT Network (192.168.x.0/24)** - Internet access for tools/updates
- **Vulnerable Network (10.10.10.0/24)** - Isolated attack range, no internet
- **Professional Network (172.16.0.0/24)** - Active Directory domain simulation

**Skills Demonstrated:**
- VMware Workstation configuration and resource management
- Multi-network environment design and implementation
- Network isolation and segmentation
- Multi-homed system configuration
- Resource allocation and performance optimization

**Documentation:**
- [Complete Homelab Documentation](infrastructure/security-homelab/)
- [Network Architecture Details](infrastructure/security-homelab/network-architecture.md)
- [VM Setup Procedures](infrastructure/security-homelab/vm-setup-guide.md)
- [Troubleshooting Guide](infrastructure/security-homelab/troubleshooting-guide.md)

---

## Information Security

### SIEM Deployment & Configuration
**Status:** Operational | **Environment:** Homelab

Deployed Splunk Enterprise as centralized SIEM across three network segments, collecting logs from Linux and Windows systems.

**Implementation:**
- Multi-network deployment (NAT, Vulnerable, Professional networks)
- Universal Forwarders on all Windows systems
- Sysmon integration for enhanced Windows logging
- Syslog ingestion from Linux systems
- Multi-interface configuration for segmented log collection

**Log Sources:**
- Windows Event Logs (Security, System, Application)
- Sysmon operational logs
- Linux syslog
- Authentication events from Active Directory
- Application logs from web services

**Skills Demonstrated:**
- Splunk Enterprise installation and configuration
- Universal Forwarder deployment and management
- Multi-network SIEM architecture
- Log source configuration and parsing
- Detection rule development

**Documentation:**
- [Splunk Deployment Guide](security/siem-deployment/)

### Active Directory Security Testing
**Status:** Active Development | **Environment:** Homelab

Windows Server 2022 domain controller deployment for testing AD security, authentication, and common attack vectors.

**Configuration:**
- Domain: lab.local
- Domain Controller: DC01 (172.16.0.1)
- DHCP and DNS services
- Group Policy management
- Domain-joined Windows 10 and Windows 11 clients

**Testing Scenarios:**
- Kerberos authentication monitoring
- Failed login attempt detection
- Lateral movement indicators
- Privilege escalation testing
- Group Policy effectiveness

**Skills Demonstrated:**
- Active Directory Domain Services deployment
- DNS and DHCP configuration
- Domain controller promotion
- Group Policy creation and management
- AD security monitoring

**Documentation:**
- [AD Security Lab Setup](security/active-directory-lab/)

### Vulnerable Environment Operations
**Status:** Operational | **Purpose:** Exploitation Practice

Isolated attack range with intentionally vulnerable systems for practicing exploitation techniques and developing detection rules.

**Targets:**
- Metasploitable 2 (Linux, multiple service vulnerabilities)
- DVWA (Web application vulnerabilities)

**Attack Scenarios:**
- Network reconnaissance and enumeration
- Service exploitation (FTP, SSH, SMB, HTTP)
- Web application attacks (SQLi, XSS, command injection)
- Post-exploitation and privilege escalation
- SIEM detection rule validation

**Skills Demonstrated:**
- Penetration testing methodology
- Vulnerability exploitation
- Attack detection and monitoring
- SIEM correlation rule development

**Documentation:**
- [Attack Scenario Walkthroughs](security/attack-scenarios/)

---

## System Administration

### Windows Deployment Automation
**Project:** Golden Image Creation | **Status:** Complete

See dedicated repository: [Win11-Golden-Image](https://github.com/YOUR-USERNAME/Win11-Golden-Image)

Standardized Windows 10/11 deployment image reducing installation time from 4-6 hours to under 1 hour through automation.

**Key Achievements:**
- 75% deployment time reduction
- 100% deployment success rate
- PowerShell automation for software installation
- Sysprep generalization for hardware-agnostic deployment

**Skills Demonstrated:**
- Windows imaging (Sysprep, DISM, WIM)
- PowerShell scripting and automation
- Process improvement and standardization
- Deployment optimization

### PowerShell Administration
**Status:** Ongoing | **Code Repository:** [Sovereign-Ops-Toolbox](https://github.com/YOUR-USERNAME/Sovereign-Ops-Toolbox)

Collection of PowerShell scripts for system administration, automation, and security tasks.

**Categories:**
- Active Directory user/group management
- System configuration and hardening
- Log collection and analysis
- Automated reporting
- Security auditing

---

## Troubleshooting & Diagnostics

### Case Study: i9-13900K Multi-Monitor Configuration
**Status:** Documented | **Duration:** Multiple weeks

Systematic diagnosis of hardware under-specification issue where client attempted to drive 12 monitors from consumer-grade hardware.

**Problem:**
- Intel i9-13900K system with 12 monitors
- Underpowered PSU and weak discrete GPU
- System instability, crashes, display dropouts
- Client insisted configuration should work

**Diagnosis Methodology:**
1. Environmental isolation testing (reduced monitor count)
2. Windows Event Log analysis (TDR errors, power warnings)
3. Driver testing and optimization attempts
4. Power delivery validation
5. Load distribution testing across different configurations

**Root Cause:**
- Power supply insufficient for CPU + GPU + 12 display outputs under load
- Consumer GPU not designed for extreme multi-display configurations
- Integrated graphics sharing system resources, degrading performance
- Display bandwidth exceeding prosumer hardware capabilities

**Outcome:**
- Documented hardware limitations and specifications
- Provided upgrade path with cost estimates (PSU, professional GPU)
- Created standardized Windows image for rapid recovery during testing
- Client informed of realistic hardware requirements

**Skills Demonstrated:**
- Systematic troubleshooting methodology
- Windows Event Log analysis
- Hardware specification assessment
- Driver troubleshooting and testing
- Client communication and technical recommendations
- Professional documentation of complex issues

**Documentation:**
- [Complete Case Study](troubleshooting/13900k-multi-monitor-case-study.md)

---

## Network Architecture

### Multi-Tier Network Segmentation
**Implementation:** Homelab | **Status:** Operational

Three-network architecture demonstrating proper network segmentation and isolation for security testing.

**Design:**
- **Tier 1 (NAT):** Internet-connected for updates/tools
- **Tier 2 (Vulnerable):** Completely isolated attack range
- **Tier 3 (Professional):** Enterprise simulation with AD domain

**Security Controls:**
- No routing between Vulnerable and Professional networks
- Firewall rules preventing accidental exposure
- Multi-homed monitoring systems for visibility
- Strategic placement of attack and monitoring platforms

**Skills Demonstrated:**
- Network segmentation design
- VMware virtual networking configuration
- Security boundary implementation
- Enterprise network simulation

**Documentation:**
- [Network Architecture](infrastructure/security-homelab/network-architecture.md)

---

## SIEM & Monitoring

### Splunk Enterprise Implementation
**Status:** Operational | **Environment:** Homelab

Multi-network SIEM deployment demonstrating log aggregation, correlation, and monitoring across diverse systems.

**Architecture:**
- Splunk server with 3 network interfaces (NAT, Vulnerable, Professional)
- Universal Forwarders on Windows systems (port 9997)
- Syslog receivers (port 514 UDP)
- Log collection from all network segments

**Monitored Systems:**
- Windows authentication events
- Sysmon process monitoring
- Linux system logs
- Attack traffic on Vulnerable network
- Active Directory domain events

**Detection Capabilities:**
- Failed authentication attempts
- Suspicious process execution
- Lateral movement indicators
- Network reconnaissance activity
- Privilege escalation attempts

**Skills Demonstrated:**
- Splunk installation and configuration
- Log source integration (Windows, Linux)
- Universal Forwarder deployment
- Multi-network monitoring
- Detection rule development

**Documentation:**
- [SIEM Implementation Guide](security/siem-deployment/)

---

## Stats & Metrics

**Environments Deployed:** 1 complete security lab (7 VMs, 3 networks)  
**Systems Managed:** 7 virtual machines (Linux, Windows Server, Windows clients)  
**Networks Configured:** 3 isolated segments with proper segmentation  
**Deployment Automation:** 75% time reduction (Windows golden image)  
**Documentation:** 11 comprehensive technical documents  

---

## Skills Matrix

**Infrastructure:**
✅ VMware Workstation configuration and management  
✅ Multi-VM environment design and deployment  
✅ Resource allocation and performance optimization  
✅ Network segmentation and isolation  

**System Administration:**
✅ Windows Server 2022 deployment and configuration  
✅ Active Directory Domain Services  
✅ Windows 10/11 client management  
✅ Linux system administration (Ubuntu, Kali)  
✅ PowerShell automation and scripting  

**Information Security:**
✅ SIEM deployment and configuration (Splunk)  
✅ Log aggregation and analysis  
✅ Active Directory security monitoring  
✅ Penetration testing (Kali Linux)  
✅ Vulnerability exploitation and research  
✅ Network security and segmentation  

**Troubleshooting:**
✅ Systematic diagnostic methodology  
✅ Windows Event Log analysis  
✅ Hardware specification assessment  
✅ Driver troubleshooting and optimization  
✅ Root cause analysis and documentation  

**Tools & Technologies:**
- **Virtualization:** VMware Workstation 17
- **Operating Systems:** Windows Server 2022, Windows 10/11, Ubuntu, Kali Linux
- **SIEM:** Splunk Enterprise
- **Security Tools:** Kali Linux, Metasploitable, DVWA, Sysmon
- **Scripting:** PowerShell, Bash
- **Monitoring:** Splunk Universal Forwarders, Sysmon, Windows Event Logs
- **Networking:** VMware virtual networks, multi-homed configurations

---

## Repository Structure

```
CrashCart/
├── README.md (this file)
├── infrastructure/
│   └── security-homelab/
│       ├── README.md
│       ├── network-architecture.md
│       ├── vm-setup-guide.md
│       ├── troubleshooting-guide.md
│       └── CHANGELOG.md
├── security/
│   ├── siem-deployment/
│   ├── active-directory-lab/
│   └── attack-scenarios/
├── troubleshooting/
│   └── 13900k-multi-monitor-case-study.md
├── system-administration/
│   └── (links to other repos)
└── network-architecture/
    └── (diagrams and designs)
```

---

## Other Repositories

**Focused Projects:**
- [Win11-Golden-Image](https://github.com/YOUR-USERNAME/Win11-Golden-Image) - Windows deployment automation
- [Sovereign-Ops-Toolbox](https://github.com/YOUR-USERNAME/Sovereign-Ops-Toolbox) - PowerShell, Python, Bash scripts

---

## About This Repository

CrashCart is my technical portfolio - evidence of what I can build, troubleshoot, and implement. Each section contains real projects with measurable results, not theoretical knowledge or tutorials.

**Why "CrashCart"?**
In medicine, a crash cart contains everything needed to respond to emergencies. In IT, this repository contains everything needed to prove technical competence across domains.

---

**Last Updated:** October 2025  
**Status:** Active Development  
**Contact:** [Your contact info or LinkedIn]

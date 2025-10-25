# Homelab Changelog

## October 2025 - Initial Build

### Environment Setup
- Installed VMware Workstation 17 Pro on Windows host
- Configured host system with i9-9900K, 96GB RAM, NVIDIA Quadro P1000
- Created three isolated virtual networks for security testing

### Network Architecture Deployed
- **NAT Network (vmnet8):** Internet access for tool updates
- **Vulnerable Network (vmnet2):** Isolated attack range at 10.10.10.0/24
- **Professional Network (vmnet3):** Enterprise simulation at 172.16.0.0/24

### Virtual Machines Deployed

**Security Tools:**
- Kali Red (Attack Platform)
  - 4 CPUs, 8GB RAM, 80GB disk
  - Multi-homed across all three networks
  - Updated to latest Kali tools and exploits
  
- Splunk Enterprise (SIEM)
  - 4 CPUs, 12GB RAM, 100GB disk
  - Multi-homed for log collection from all networks
  - Configured receiving on port 9997 (forwarders) and 514 (syslog)

**Vulnerable Targets:**
- Metasploitable 2
  - Intentionally vulnerable Linux system
  - Connected to Vulnerable Network only
  - Multiple exploitable services (FTP, SSH, Telnet, SMB, HTTP)
  
- DVWA (Damn Vulnerable Web Application)
  - Ubuntu 24.04 with Apache, MySQL, PHP
  - Web application security testing platform
  - Isolated on Vulnerable Network

**Enterprise Environment:**
- Windows Server 2022 (Domain Controller)
  - Active Directory Domain Services installed
  - Domain: lab.local
  - DNS and DHCP services configured
  - Static IP: 172.16.0.1

- Windows 10 Client
  - Domain-joined workstation
  - Sysmon installed for enhanced logging
  - Universal Forwarder sending logs to Splunk

- Windows 11 Client
  - Domain-joined workstation
  - Sysmon installed for enhanced logging
  - Universal Forwarder sending logs to Splunk

### Network Segmentation Implemented
- Vulnerable targets completely isolated from internet
- Professional network simulates production AD environment
- Kali positioned as both external attacker and insider threat
- Splunk monitoring all network segments simultaneously

### Security Controls Configured
- No routing between Vulnerable and Professional networks
- Firewall rules prevent accidental exposure of vulnerable systems
- Splunk configured to alert on authentication failures and lateral movement
- All Windows systems forwarding security logs to SIEM

### Lab Capabilities Validated
✅ Attack scenarios against vulnerable targets  
✅ SIEM log collection from multiple sources  
✅ Active Directory authentication and domain services  
✅ Network segmentation and isolation  
✅ Multi-platform monitoring (Linux and Windows)  

### Skills Demonstrated Through This Build
- Virtualization platform deployment and resource management
- Network design with proper segmentation
- SIEM implementation (Splunk Enterprise)
- Active Directory deployment and domain configuration
- Multi-platform system administration (Linux, Windows Server, Windows clients)
- Security tool deployment (Kali, Metasploitable, DVWA)
- Log aggregation and forwarding configuration
- Infrastructure documentation and technical writing

### Known Issues / Future Enhancements
- [ ] Add pfSense firewall VM for advanced routing scenarios
- [ ] Deploy Wazuh or ELK stack for comparison with Splunk
- [ ] Create automated VM deployment scripts
- [ ] Add Windows domain user accounts for testing privilege escalation
- [ ] Configure Splunk dashboards for attack detection
- [ ] Add Blue Team VM with defensive tools (Velociraptor, Wireshark, etc.)
- [ ] Implement VPN server for remote access to lab
- [ ] Add documentation for common attack paths and detection rules

### Documentation Completed
- Main README with lab overview
- Network architecture diagram and configuration
- VM setup guide with step-by-step installation
- Troubleshooting guide for common issues
- This changelog documenting the build timeline

---

## Future Plans

### Short Term (Next 30 Days)
- Practice common exploitation techniques against Metasploitable
- Build Splunk detection rules for reconnaissance and exploitation
- Configure Group Policy in lab.local domain
- Document 5-10 attack scenarios with detection in Splunk

### Medium Term (30-90 Days)
- Add malware analysis VM with REMnux or FlareVM
- Deploy honeypot system on Vulnerable Network
- Create automated attack scenarios using Atomic Red Team
- Develop custom PowerShell scripts for AD enumeration testing

### Long Term (90+ Days)
- Build completely isolated "red team vs blue team" scenario
- Deploy Security Onion or other NSM platform
- Create training modules based on lab scenarios
- Consider expanding to cloud environment (AWS/Azure) for hybrid scenarios

---

**Last Updated:** October 25, 2025  
**Lab Status:** Operational and ready for security research

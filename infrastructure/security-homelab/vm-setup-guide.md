# VM Setup Guide

Step-by-step instructions for building each virtual machine in the homelab environment.

## Prerequisites

- VMware Workstation 17 Pro installed
- Virtual networks configured (see network-architecture.md)
- Sufficient disk space (~500GB recommended for all VMs)
- ISO files downloaded for each OS

## VM Resource Allocations

| VM | CPUs | RAM | Disk | Notes |
|----|------|-----|------|-------|
| Kali Red | 4 | 8GB | 80GB | Needs CPU for cracking/scanning |
| Metasploitable | 1 | 512MB | 8GB | Intentionally resource-limited |
| DVWA | 2 | 2GB | 20GB | Web server + database |
| Splunk | 4 | 12GB | 100GB | SIEM requires RAM for indexing |
| WinServer2022 | 4 | 8GB | 60GB | Domain Controller + DHCP |
| Win10-Client | 2 | 4GB | 60GB | Standard workstation |
| Win11-Client | 2 | 4GB | 60GB | Standard workstation |

**Total:** 19 CPUs, 38.5GB RAM, ~390GB disk

## 1. Kali Red (Attack Platform)

### Installation
1. Download Kali Linux from: https://www.kali.org/get-kali/
2. Create VM:
   - File > New Virtual Machine > Custom
   - Guest OS: Linux > Debian 11.x 64-bit
   - CPUs: 4 cores
   - RAM: 8192 MB
   - Network: NAT (we'll add more later)
   - Disk: 80GB, single file
3. Install Kali from ISO:
   - Boot from ISO
   - Graphical install
   - Hostname: kali-red
   - Username: Create non-root user (e.g., operator)
   - Partition: Guided - use entire disk
   - Software: Kali-linux-default, SSH server

### Post-Install Configuration

**Add additional NICs:**
```
VM Settings > Add > Network Adapter
- Add Adapter 2: Custom (vmnet2) - Vulnerable Network
- Add Adapter 3: Custom (vmnet3) - Professional Network
```

**Configure network interfaces:**
```bash
# Edit /etc/network/interfaces
sudo nano /etc/network/interfaces

# Add:
auto eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet static
    address 10.10.10.1
    netmask 255.255.255.0

auto eth2
iface eth2 inet static
    address 172.16.0.10
    netmask 255.255.255.0
```

**Restart networking:**
```bash
sudo systemctl restart networking
# OR
sudo reboot
```

**Update and install tools:**
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y kali-linux-large
sudo apt install -y seclists wordlists metasploit-framework
```

**Verify interfaces:**
```bash
ip addr show
# Should see eth0 (NAT), eth1 (10.10.10.1), eth2 (172.16.0.10)
```

## 2. Metasploitable (Vulnerable Target)

### Installation
1. Download Metasploitable 2 from: https://sourceforge.net/projects/metasploitable/
2. Extract ZIP file
3. Open in VMware:
   - File > Open > Select .vmx file
4. Edit VM Settings:
   - Network Adapter: Custom (vmnet2) - Vulnerable Network only
   - RAM: 512MB (default is fine)
   - CPUs: 1 (default is fine)

### Configuration

**Boot VM and login:**
- Username: `msfadmin`
- Password: `msfadmin`

**Set static IP:**
```bash
sudo nano /etc/network/interfaces

# Change to:
auto eth0
iface eth0 inet static
    address 10.10.10.10
    netmask 255.255.255.0
```

**Restart networking:**
```bash
sudo /etc/init.d/networking restart
```

**Verify vulnerable services are running:**
```bash
netstat -tulnp
# Should see many services: FTP (21), SSH (22), Telnet (23), HTTP (80), SMB (139, 445), etc.
```

**Do NOT update or patch** - vulnerabilities are the point

## 3. DVWA (Damn Vulnerable Web Application)

### Installation
1. Download Ubuntu Server 24.04 LTS ISO
2. Create VM:
   - File > New Virtual Machine
   - Guest OS: Linux > Ubuntu 64-bit
   - CPUs: 2 cores
   - RAM: 2048 MB
   - Network: Custom (vmnet2) - Vulnerable Network
   - Disk: 20GB

### DVWA Setup

**Install Ubuntu Server:**
- Hostname: dvwa
- Username: Create standard user
- Install OpenSSH server
- No additional packages

**Post-install:**
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y apache2 mysql-server php php-mysqli php-gd libapache2-mod-php
```

**Download and install DVWA:**
```bash
cd /var/www/html
sudo git clone https://github.com/digininja/DVWA.git
sudo chown -R www-data:www-data DVWA/
cd DVWA
sudo cp config/config.inc.php.dist config/config.inc.php
```

**Configure database:**
```bash
sudo mysql
```
```sql
CREATE DATABASE dvwa;
CREATE USER 'dvwa'@'localhost' IDENTIFIED BY 'p@ssw0rd';
GRANT ALL PRIVILEGES ON dvwa.* TO 'dvwa'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

**Edit DVWA config:**
```bash
sudo nano config/config.inc.php
# Update:
# $_DVWA[ 'db_user' ] = 'dvwa';
# $_DVWA[ 'db_password' ] = 'p@ssw0rd';
# $_DVWA[ 'db_database' ] = 'dvwa';
```

**Set static IP:**
```bash
sudo nano /etc/netplan/00-installer-config.yaml
```
```yaml
network:
  version: 2
  ethernets:
    ens33:
      addresses:
        - 10.10.10.20/24
      nameservers:
        addresses: [8.8.8.8]
```
```bash
sudo netplan apply
```

**Restart Apache:**
```bash
sudo systemctl restart apache2
```

**Access DVWA:**
- Browse to: http://10.10.10.20/DVWA/
- Click "Create / Reset Database"
- Login: admin / password
- Set security level to "low" for initial testing

## 4. Splunk SIEM

### Installation
1. Download Ubuntu Server 24.04.3 LTS ISO
2. Create VM:
   - File > New Virtual Machine
   - Guest OS: Linux > Ubuntu 64-bit
   - CPUs: 4 cores
   - RAM: 12288 MB (Splunk needs RAM for indexing)
   - Network: NAT (we'll add more interfaces)
   - Disk: 100GB

**Install Ubuntu:**
- Hostname: splunk
- Username: Create standard user
- Install OpenSSH server

**Add additional NICs:**
```
VM Settings > Add > Network Adapter
- Add Adapter 2: Custom (vmnet2) - Vulnerable Network
- Add Adapter 3: Custom (vmnet3) - Professional Network
```

### Splunk Installation

**Configure static IPs:**
```bash
sudo nano /etc/netplan/00-installer-config.yaml
```
```yaml
network:
  version: 2
  ethernets:
    ens33:  # NAT
      dhcp4: true
    ens34:  # Vulnerable Network
      addresses:
        - 10.10.10.100/24
    ens35:  # Professional Network
      addresses:
        - 172.16.0.2/24
```
```bash
sudo netplan apply
ip addr show  # Verify all interfaces
```

**Download and install Splunk:**
```bash
cd /tmp
wget -O splunk.tgz 'https://download.splunk.com/products/splunk/releases/9.1.2/linux/splunk-9.1.2-b6436b649711-Linux-x86_64.tgz'
sudo tar xvzf splunk.tgz -C /opt
sudo /opt/splunk/bin/splunk start --accept-license
# Set admin password when prompted
```

**Enable boot-start:**
```bash
sudo /opt/splunk/bin/splunk enable boot-start -user splunk
```

**Configure receiving ports:**
```bash
# For Universal Forwarders (Windows logs)
sudo /opt/splunk/bin/splunk enable listen 9997 -auth admin:yourpassword

# For syslog
sudo /opt/splunk/bin/splunk add udp 514 -auth admin:yourpassword
```

**Access Splunk Web:**
- Browse to: http://[NAT IP]:8000
- Login with admin credentials
- Complete initial setup wizard

## 5. Windows Server 2022 (Domain Controller)

### Installation
1. Download Windows Server 2022 ISO from Microsoft Evaluation Center
2. Create VM:
   - File > New Virtual Machine
   - Guest OS: Windows > Windows Server 2022
   - CPUs: 4 cores
   - RAM: 8192 MB
   - Network: Custom (vmnet3) - Professional Network
   - Disk: 60GB

**Install Windows Server:**
- Edition: Standard (Desktop Experience)
- Custom install
- Administrator password: Set strong password

### Post-Install Configuration

**Set static IP:**
```powershell
New-NetIPAddress -InterfaceAlias "Ethernet0" -IPAddress 172.16.0.1 -PrefixLength 24
Set-DnsClientServerAddress -InterfaceAlias "Ethernet0" -ServerAddresses 172.16.0.1
```

**Rename computer:**
```powershell
Rename-Computer -NewName "DC01" -Restart
```

**Install Active Directory Domain Services:**
```powershell
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
```

**Promote to Domain Controller:**
```powershell
Install-ADDSForest `
  -DomainName "lab.local" `
  -DomainNetbiosName "LAB" `
  -ForestMode "WinThreshold" `
  -DomainMode "WinThreshold" `
  -InstallDns:$true `
  -SafeModeAdministratorPassword (ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force) `
  -Force:$true
# Server will restart automatically
```

**Configure DHCP (optional):**
```powershell
Install-WindowsFeature -Name DHCP -IncludeManagementTools
Add-DhcpServerv4Scope -Name "Professional Network" -StartRange 172.16.0.50 -EndRange 172.16.0.200 -SubnetMask 255.255.255.0
Set-DhcpServerv4OptionValue -DnsServer 172.16.0.1 -Router 172.16.0.1
Restart-Service DHCPServer
```

## 6. Windows 10 Client

### Installation
1. Download Windows 10 ISO from Microsoft
2. Create VM:
   - File > New Virtual Machine
   - Guest OS: Windows > Windows 10 x64
   - CPUs: 2 cores
   - RAM: 4096 MB
   - Network: Custom (vmnet3) - Professional Network
   - Disk: 60GB

**Install Windows 10:**
- Skip product key for now
- Edition: Windows 10 Pro (required for domain join)
- Custom install

### Post-Install Configuration

**Set computer name:**
```powershell
Rename-Computer -NewName "WIN10-01" -Restart
```

**Join domain:**
```powershell
Add-Computer -DomainName "lab.local" -Credential LAB\Administrator -Restart
```

**Install Sysmon (for Splunk logging):**
```powershell
# Download Sysmon from Microsoft Sysinternals
Invoke-WebRequest -Uri "https://download.sysinternals.com/files/Sysmon.zip" -OutFile "C:\Temp\Sysmon.zip"
Expand-Archive -Path "C:\Temp\Sysmon.zip" -DestinationPath "C:\Temp\Sysmon"

# Download SwiftOnSecurity config
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml" -OutFile "C:\Temp\sysmonconfig.xml"

# Install Sysmon
C:\Temp\Sysmon\Sysmon64.exe -accepteula -i C:\Temp\sysmonconfig.xml
```

## 7. Windows 11 Client

### Installation
Follow same process as Windows 10, but:
- Use Windows 11 ISO
- Ensure VM has TPM 2.0 enabled (VM Settings > Options > Access Control > Encrypt)
- Computer name: WIN11-01

## Universal Forwarder Installation (All Windows VMs)

**Download Splunk Universal Forwarder:**
```powershell
Invoke-WebRequest -Uri "https://download.splunk.com/products/universalforwarder/releases/9.1.2/windows/splunkforwarder-9.1.2-b6436b649711-x64-release.msi" -OutFile "C:\Temp\splunkforwarder.msi"
```

**Install silently:**
```powershell
msiexec /i C:\Temp\splunkforwarder.msi RECEIVING_INDEXER="172.16.0.2:9997" AGREETOLICENSE=Yes /quiet
```

**Configure Windows Event Log inputs:**
```powershell
cd "C:\Program Files\SplunkUniversalForwarder\bin"
.\splunk.exe add monitor "Security"
.\splunk.exe add monitor "System"
.\splunk.exe add monitor "Application"
.\splunk.exe add monitor "Microsoft-Windows-Sysmon/Operational"
.\splunk.exe restart
```

## Validation Checklist

- [ ] All VMs can ping systems on their assigned networks
- [ ] Kali Red can reach internet via eth0
- [ ] Metasploitable is NOT reachable from NAT network
- [ ] DVWA web interface accessible from Kali Red
- [ ] Splunk web interface accessible from host browser
- [ ] Windows clients successfully joined to lab.local domain
- [ ] Splunk receiving logs from all Windows systems
- [ ] Domain authentication events visible in Splunk

---

**Next Steps:**
- Configure Splunk dashboards for attack monitoring
- Create domain users and groups in Active Directory
- Practice attacks against Metasploitable from Kali
- Build detection rules in Splunk based on attack patterns

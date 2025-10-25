# Troubleshooting Guide

Common issues encountered during homelab setup and their solutions.

## Table of Contents
1. [Network Connectivity Issues](#network-connectivity-issues)
2. [VMware Workstation Issues](#vmware-workstation-issues)
3. [Splunk Issues](#splunk-issues)
4. [Active Directory Issues](#active-directory-issues)
5. [Performance Issues](#performance-issues)

---

## Network Connectivity Issues

### VMs Cannot Communicate on Host-Only Network

**Symptoms:**
- Ping fails between VMs on same virtual network
- Static IPs configured but no connectivity

**Causes & Solutions:**

**1. VMs on different virtual networks**
```bash
# Verify network assignment in VMware
VM Settings > Network Adapter > check vmnetX matches between VMs
```

**2. Firewall blocking traffic**
```bash
# Linux - temporarily disable for testing
sudo ufw disable

# Windows - turn off firewall temporarily
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
```

**3. Wrong subnet configuration**
```bash
# Verify IPs are in same subnet
ip addr show  # Linux
ipconfig      # Windows

# Example: 10.10.10.1 and 10.10.10.10 are in same /24 subnet
# But 10.10.10.1 and 172.16.0.1 are NOT
```

**4. Virtual network doesn't exist**
```
Edit > Virtual Network Editor (Run as Administrator)
- Verify vmnet2 and vmnet3 exist
- If missing: Add Network > create host-only network with correct subnet
```

### Kali Red Cannot Access Internet

**Symptoms:**
- `ping 8.8.8.8` fails
- Cannot update packages
- DNS resolution fails

**Solutions:**

**1. Verify NAT service is running**
```powershell
# Windows host
services.msc > Find "VMware NAT Service" > ensure Started and Automatic
# If stopped: Right-click > Start
```

**2. Check interface is on NAT network**
```bash
# In Kali
ip addr show
# eth0 should have 192.168.x.x IP
# If not: VM Settings > Network Adapter 1 > change to NAT
```

**3. Check default route**
```bash
ip route show
# Should see: default via 192.168.x.2 dev eth0

# If missing:
sudo ip route add default via 192.168.x.2
```

**4. DNS resolution fails**
```bash
cat /etc/resolv.conf
# Should contain: nameserver 192.168.x.2 or nameserver 8.8.8.8

# Fix:
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
```

### Multi-Homed System Routing Issues

**Symptoms:**
- Kali can reach one network but not others
- Traffic going out wrong interface

**Solution: Configure static routes**
```bash
# View current routes
ip route show

# Add static routes for internal networks
sudo ip route add 10.10.10.0/24 dev eth1
sudo ip route add 172.16.0.0/24 dev eth2

# Make persistent - add to /etc/network/interfaces:
# up route add -net 10.10.10.0/24 dev eth1
# up route add -net 172.16.0.0/24 dev eth2
```

### Windows Cannot Join Domain

**Symptoms:**
- "Domain not found" error when joining
- DNS resolution fails for lab.local

**Solutions:**

**1. Verify DNS points to DC**
```powershell
Get-DnsClientServerAddress
# Should show 172.16.0.1

# Fix:
Set-DnsClientServerAddress -InterfaceAlias "Ethernet0" -ServerAddresses 172.16.0.1
```

**2. Test domain connectivity**
```powershell
Test-Connection -ComputerName DC01.lab.local
nslookup lab.local

# Should resolve to 172.16.0.1
```

**3. Verify time sync**
```powershell
# Time skew > 5 minutes breaks Kerberos authentication
w32tm /query /status

# Sync time:
w32tm /resync
```

**4. Check firewall on DC**
```powershell
# On DC01 - ensure these ports are open:
# 53 (DNS), 88 (Kerberos), 389 (LDAP), 445 (SMB), 135 (RPC)

# Temporarily disable for testing:
Set-NetFirewallProfile -Profile Domain -Enabled False
```

---

## VMware Workstation Issues

### VM Won't Power On After Host Reboot

**Symptoms:**
- "The virtual machine is in use" error
- Cannot start VM

**Solution:**
```
1. Close VMware Workstation completely
2. Navigate to VM directory
3. Delete all .lck folders
4. Delete .vmx.lck file if present
5. Restart VMware Workstation
6. Power on VM
```

### VM Performance Severely Degraded

**Symptoms:**
- VM very slow despite adequate resources
- Host CPU at 100%

**Solutions:**

**1. Check resource overcommitment**
```
Total VM RAM: Should not exceed ~80% of host physical RAM
Total VM CPUs: Should not exceed physical core count
```

**2. Verify VMware Tools installed**
```bash
# Linux - check if running
systemctl status vmtoolsd

# Install if missing:
sudo apt install open-vm-tools  # Ubuntu/Debian
```

**3. Disable memory swapping in VMs**
```
VM Settings > Options > Advanced
- Disable "Enable virtual CPU performance counters" if not needed
```

**4. Pause unused VMs**
```
Right-click VM > Power > Suspend
# Frees RAM and CPU without shutting down
```

### Copy/Paste Not Working Between Host and VM

**Symptoms:**
- Cannot copy/paste text
- Drag-and-drop files doesn't work

**Solution:**
```
1. Install VMware Tools (or open-vm-tools)
2. VM Settings > Options > Guest Isolation
3. Enable "Enable copy and paste"
4. Enable "Enable drag and drop"
5. Reboot VM
```

---

## Splunk Issues

### Splunk Not Receiving Windows Logs

**Symptoms:**
- No events from Windows systems in Splunk
- Search for `host=WIN10-01` returns no results

**Solutions:**

**1. Verify Universal Forwarder is running**
```powershell
# On Windows client
Get-Service SplunkForwarder
# Should be Running

# If stopped:
Start-Service SplunkForwarder
```

**2. Check forwarder configuration**
```powershell
# Check outputs.conf
Get-Content "C:\Program Files\SplunkUniversalForwarder\etc\system\local\outputs.conf"
# Should contain: 
# [tcpout]
# defaultGroup = splunk_indexers
# [tcpout:splunk_indexers]
# server = 172.16.0.2:9997
```

**3. Verify receiving port is open on Splunk**
```bash
# On Splunk server
sudo netstat -tulnp | grep 9997
# Should show: tcp 0.0.0.0:9997 LISTEN

# If not listening:
/opt/splunk/bin/splunk enable listen 9997 -auth admin:password
```

**4. Check firewall on Splunk server**
```bash
sudo ufw status
# Should allow 9997/tcp

# Add rule if needed:
sudo ufw allow 9997/tcp
sudo ufw reload
```

**5. Test connectivity from Windows to Splunk**
```powershell
Test-NetConnection -ComputerName 172.16.0.2 -Port 9997
# Should show: TcpTestSucceeded : True
```

### Splunk Web Interface Inaccessible

**Symptoms:**
- Cannot reach http://[IP]:8000
- Connection refused or times out

**Solutions:**

**1. Verify Splunk is running**
```bash
sudo /opt/splunk/bin/splunk status
# Should show: splunkd is running

# If not:
sudo /opt/splunk/bin/splunk start
```

**2. Check listening ports**
```bash
sudo netstat -tulnp | grep 8000
# Should show: tcp 0.0.0.0:8000 LISTEN
```

**3. Check firewall**
```bash
sudo ufw allow 8000/tcp
```

**4. Verify web interface is enabled**
```bash
/opt/splunk/bin/splunk enable webserver -auth admin:password
/opt/splunk/bin/splunk restart
```

### Splunk Indexing Slow / Running Out of Disk

**Symptoms:**
- Searches very slow
- Disk space warning in Splunk

**Solutions:**

**1. Check disk usage**
```bash
df -h
# Look for /opt/splunk partition usage

du -sh /opt/splunk/var/lib/splunk/*
# Identify large indexes
```

**2. Reduce retention time**
```bash
# Edit indexes.conf
sudo nano /opt/splunk/etc/system/local/indexes.conf

# Add or modify:
[default]
frozenTimePeriodInSecs = 604800  # 7 days instead of 6 years
maxTotalDataSizeMB = 50000       # Limit index size
```

**3. Delete old indexes**
```bash
/opt/splunk/bin/splunk clean eventdata -index _internal -f
/opt/splunk/bin/splunk clean eventdata -index main -f
```

**4. Add more disk to VM**
```
1. Shut down Splunk VM
2. VM Settings > Hard Disk > Expand
3. Increase disk size (e.g., 100GB → 200GB)
4. Boot VM
5. Extend partition:
   sudo growpart /dev/sda 3
   sudo resize2fs /dev/sda3
```

---

## Active Directory Issues

### Cannot Authenticate to Domain

**Symptoms:**
- Domain login fails on client
- "The trust relationship between this workstation and the primary domain failed"

**Solutions:**

**1. Verify computer account exists**
```powershell
# On DC
Get-ADComputer -Identity WIN10-01
# Should return computer object

# If not found - rejoin domain:
# On client:
Remove-Computer -UnjoinDomainCredential LAB\Administrator -Restart
Add-Computer -DomainName lab.local -Credential LAB\Administrator -Restart
```

**2. Reset computer account**
```powershell
# On DC
Reset-ComputerMachinePassword -Credential LAB\Administrator
```

**3. Check time sync**
```powershell
w32tm /query /status
# If time off by > 5 minutes, Kerberos fails

# Sync:
w32tm /resync
```

### Group Policy Not Applying

**Symptoms:**
- GPO changes not taking effect
- `gpresult /r` shows no policies applied

**Solutions:**

**1. Force Group Policy update**
```powershell
gpupdate /force
```

**2. Check GPO replication**
```powershell
# On DC
Get-GPOReport -All -ReportType Html -Path C:\Temp\GPOReport.html
# Open in browser to verify GPOs exist
```

**3. Verify DNS resolution of DC**
```powershell
nslookup lab.local
# Should return 172.16.0.1

# If fails:
Set-DnsClientServerAddress -InterfaceAlias "Ethernet0" -ServerAddresses 172.16.0.1
```

---

## Performance Issues

### Host System Running Slow

**Symptoms:**
- Host system unresponsive
- VMs lagging
- High CPU/RAM usage

**Solutions:**

**1. Check resource allocation**
```
Total VM RAM should not exceed 80% of host RAM
Example: 96GB host → max 76GB allocated to VMs
Current allocation: 38.5GB (safe)
```

**2. Suspend unused VMs**
```
Keep only necessary VMs running:
- For attack scenarios: Kali + Metasploitable + Splunk = ~20GB RAM
- For AD practice: Kali + DC + Win10 + Splunk = ~26GB RAM
```

**3. Reduce VM resources**
```
If running low on host resources:
- Reduce Splunk to 8GB RAM (minimum for small lab)
- Reduce VMs to 2 CPUs each unless actively testing
```

**4. Close other applications**
```
VMware Workstation is resource-intensive
- Close browsers with many tabs
- Close Docker if not needed
- Close other VMs (VirtualBox, etc.)
```

### Kali VM Extremely Slow

**Symptoms:**
- GUI very laggy
- Commands take forever to execute

**Solutions:**

**1. Increase allocated RAM**
```
VM Settings > Memory > increase to 8GB (minimum for comfortable use)
```

**2. Enable 3D acceleration**
```
VM Settings > Display
- Enable "Accelerate 3D graphics"
- Set graphics memory to 2GB
- Install VMware Tools if not already present
```

**3. Reduce running services**
```bash
# Disable unnecessary services
sudo systemctl disable bluetooth
sudo systemctl disable cups
```

---

## Emergency Procedures

### VM Won't Boot - Kernel Panic

**Solution:**
```
1. Shut down VM
2. Take snapshot (if not already corrupted)
3. VM Settings > Options > Advanced > Firmware Type
4. Try switching between BIOS and UEFI
5. Attempt boot
6. If still fails: restore from earlier snapshot
```

### Lost Domain Admin Password

**Solution:**
```
1. Mount Windows Server ISO to VM
2. Boot from ISO
3. Shift+F10 to open Command Prompt
4. Replace utilman.exe with cmd.exe:
   copy D:\windows\system32\utilman.exe D:\windows\system32\utilman.exe.bak
   copy D:\windows\system32\cmd.exe D:\windows\system32\utilman.exe
5. Reboot, remove ISO
6. At login screen, click Accessibility
7. Command prompt opens as SYSTEM
8. Reset password:
   net user Administrator NewPassword123!
```

### Splunk Admin Password Forgotten

**Solution:**
```bash
# Reset admin password
sudo /opt/splunk/bin/splunk cmd splunkd rest --noauth POST /services/admin/users/admin "password=NewPassword123!"

# Or reset completely:
sudo /opt/splunk/bin/splunk stop
sudo rm /opt/splunk/etc/passwd
sudo /opt/splunk/bin/splunk start
# Will prompt to create new admin password
```

---

## Prevention Best Practices

1. **Take snapshots before major changes**
   - Before installing new software
   - Before joining domain
   - Before running destructive tests

2. **Document IP addresses**
   - Keep spreadsheet of all VM IPs
   - Prevents "which IP was that VM?" confusion

3. **Regular backups of Splunk**
   ```bash
   /opt/splunk/bin/splunk backup -archiveName splunk_backup_$(date +%Y%m%d).tar.gz
   ```

4. **Export VM configurations**
   - Before major VMware updates
   - Keep backups of .vmx files

5. **Monitor host resources**
   - Don't allocate > 80% of RAM to VMs
   - Leave headroom for host OS

---

**If all else fails:** Restore from snapshot or rebuild VM using vm-setup-guide.md

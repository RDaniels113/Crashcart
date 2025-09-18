<#
.SYNOPSIS
  Enumerate Windows file system minifilters (FSFilter drivers) from an OFFLINE Windows image
  or the LIVE system, with clean CSV/TXT output for forensics and case studies.

.DESCRIPTION
  - Loads an offline SYSTEM hive, detects the current control set, and enumerates services whose Group is 'FSFilter*'.
  - Collects Name, DisplayName, Start, StartText, ImagePath, Company (from file version info when resolvable), and Altitude (from Instances).
  - Outputs both CSV (machine-readable) and TXT (human-readable).
  - If no -OfflineWindows is supplied, runs in ONLINE mode. In online mode, also tries 'fltmc filters' to capture live load order & altitudes.

.PARAMETER OfflineWindows
  Root path to an offline Windows installation (e.g. 'E:\Windows').

.PARAMETER OutPrefix
  Output file prefix (defaults to timestamped 'fsfilters').

.PARAMETER OutputDir
  Directory for output files (defaults to current directory).

.EXAMPLE
  # Offline analysis (mounted image at E:)
  .\Offline-FilterCheck.ps1 -OfflineWindows 'E:\Windows' -OutputDir '..\artifacts'

.EXAMPLE
  # Live system snapshot
  .\Offline-FilterCheck.ps1 -OutputDir '..\artifacts'

.NOTES
  Requires: PowerShell 5+ (works in Windows PowerShell), Admin recommended for hive load.
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$false)]
  [ValidateScript({ Test-Path $_ -PathType Container })]
  [string]$OfflineWindows,

  [Parameter(Mandatory=$false)]
  [string]$OutPrefix = ("fsfilters_{0:yyyyMMdd_HHmmss}" -f (Get-Date)),

  [Parameter(Mandatory=$false)]
  [ValidateScript({ Test-Path $_ -PathType Container })]
  [string]$OutputDir = (Get-Location).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-ImagePath {
  param(
    [string]$ImagePath,
    [string]$RootWindows = $null
  )
  if ([string]::IsNullOrWhiteSpace($ImagePath)) { return $null }
  $p = $ImagePath

  # Remove quotes
  $p = $p.Trim('"')

  # Expand system variables
  $p = $p -replace '%SystemRoot%', '\Windows'
  $p = $p -replace '%systemroot%', '\Windows'
  $p = $p -replace '%WinDir%', '\Windows'
  $p = $p -replace '%windir%', '\Windows'
  $p = $p -replace '%System32%', '\Windows\System32'
  $p = $p -replace '%system32%', '\Windows\System32'

  # If it starts with \??\ or \SystemRoot, normalize
  $p = $p -replace '^[\\?]{2}\\','\'
  if ($p -like '\Windows*' -and $RootWindows) {
    $p = Join-Path (Split-Path $RootWindows -Parent) $p.TrimStart('\')
  }

  # If path is like system32\foo.sys, anchor to Windows dir if given
  if (-not (Split-Path $p -IsAbsolute) -and $RootWindows) {
    $p = Join-Path $RootWindows $p
  }

  return $p
}

function Get-Company {
  param([string]$Path)
  try {
    if ($Path -and (Test-Path $Path -ErrorAction SilentlyContinue)) {
      $vi = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($Path)
      return $vi.CompanyName
    }
  } catch {}
  return $null
}

function Get-ControlSetNumber {
  param([string]$BaseKeyPath)
  # BaseKeyPath is HKLM:\SYSTEM (online) or HKLM:\OfflineSYS (offline)
  $sel = Get-ItemProperty -Path (Join-Path $BaseKeyPath 'Select')
  return $sel.Current
}

function Get-FSFiltersFromHive {
  param(
    [string]$SystemKeyPath,   # e.g., HKLM:\OfflineSYS or HKLM:\SYSTEM
    [string]$RootWindows      # null for online; offline windows folder for path resolve
  )

  $csn = Get-ControlSetNumber -BaseKeyPath $SystemKeyPath
  $csPath = Join-Path $SystemKeyPath ("ControlSet{0:000}" -f $csn)
  $svcPath = Join-Path $csPath 'Services'

  $items = @()
  Get-ChildItem $svcPath -ErrorAction SilentlyContinue | ForEach-Object {
    try {
      $p = Get-ItemProperty -Path $_.PsPath -ErrorAction Stop
      if ($p.Group -and ($p.Group -like 'FSFilter*')) {
        $name        = $_.PSChildName
        $disp        = $p.DisplayName
        $start       = if ($null -ne $p.Start) { [int]$p.Start } else { $null }
        $startText   = switch ($start) { 0 {'BOOT'} 1 {'SYSTEM'} 2 {'AUTO'} 3 {'MANUAL'} 4 {'DISABLED'} Default {'?'} }
        $imgRaw      = $p.ImagePath
        $imgResolved = Resolve-ImagePath -ImagePath $imgRaw -RootWindows $RootWindows

        # Try to get altitude (common under Instances subkey)
        $alt = $null
        $instKey = Join-Path $_.PsPath 'Instances'
        if (Test-Path $instKey) {
          try {
            $inst = Get-ItemProperty -Path $instKey -ErrorAction Stop
            if ($inst.DefaultInstance) {
              $defInstKey = Join-Path $instKey $inst.DefaultInstance
              if (Test-Path $defInstKey) {
                $di = Get-ItemProperty -Path $defInstKey -ErrorAction Stop
                if ($di.Altitude) { $alt = [string]$di.Altitude }
              }
            }
          } catch {}
        }

        $company = Get-Company -Path $imgResolved

        $items += [pscustomobject]@{
          Name        = $name
          DisplayName = $disp
          Group       = $p.Group
          Start       = $start
          StartText   = $startText
          Altitude    = $alt
          ImagePath   = $imgRaw
          ResolvedPath= $imgResolved
          Company     = $company
        }
      }
    } catch {}
  }
  return $items | Sort-Object Name
}

# --- MAIN ---

$csvPath = Join-Path $OutputDir ($OutPrefix + '.csv')
$txtPath = Join-Path $OutputDir ($OutPrefix + '.txt')

$offline = $false
$hiveMounted = $false
$offlineRoot = $null
$systemKey = 'HKLM:\SYSTEM'

try {
  if ($OfflineWindows) {
    # Validate Windows folder
    $systemHive = Join-Path $OfflineWindows 'System32\Config\SYSTEM'
    if (-not (Test-Path $systemHive)) {
      throw "SYSTEM hive not found at: $systemHive"
    }
    Write-Host "[*] Loading offline SYSTEM hive from: $systemHive"
    reg load HKLM\OfflineSYS "$systemHive" | Out-Null
    $hiveMounted = $true
    $offline = $true
    $systemKey = 'HKLM:\OfflineSYS'
    $offlineRoot = $OfflineWindows
  }

  Write-Host "[*] Enumerating FSFilter services ($([bool]$offline ? 'offline' : 'online') mode)..."
  $filters = Get-FSFiltersFromHive -SystemKeyPath $systemKey -RootWindows $offlineRoot

  if (-not $filters -or $filters.Count -eq 0) {
    Write-Warning "No FSFilter services found."
  }

  # Write CSV and TXT
  $filters | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
  $report = @()
  $report += "File System Minifilters Report (`$([bool]$offline ? 'OFFLINE' : 'ONLINE'))"
  $report += "Generated: $(Get-Date -Format u)"
  $report += "Output: $csvPath"
  $report += ""
  $report += "{0,-28} {1,-7} {2,-9} {3,-10} {4}" -f "Name","Start","StartTxt","Altitude","Company"
  $report += ("-"*100)
  foreach ($f in $filters) {
    $report += ("{0,-28} {1,-7} {2,-9} {3,-10} {4}" -f $f.Name, $f.Start, $f.StartText, ($f.Altitude ?? ''), ($f.Company ?? ''))
    if ($f.ImagePath) { $report += ("    ImagePath:  {0}" -f $f.ImagePath) }
    if ($f.ResolvedPath) { $report += ("    Resolved:   {0}" -f $f.ResolvedPath) }
    if ($f.DisplayName) { $report += ("    Display:    {0}" -f $f.DisplayName) }
    $report += ""
  }

  # If ONLINE, append live fltmc snapshot
  if (-not $offline) {
    try {
      $report += "Live 'fltmc filters' snapshot:"
      $report += "-------------------------------"
      $report += (fltmc filters 2>&1 | Out-String).TrimEnd()
      $report += ""
    } catch {
      $report += "fltmc not available or insufficient privileges."
    }
  }

  $report | Set-Content -Path $txtPath -Encoding UTF8
  Write-Host "[+] CSV written: $csvPath"
  Write-Host "[+] TXT written: $txtPath"

} catch {
  Write-Error $_.Exception.Message
} finally {
  if ($hiveMounted) {
    Write-Host "[*] Unloading offline SYSTEM hive..."
    reg unload HKLM\OfflineSYS | Out-Null
  }
}

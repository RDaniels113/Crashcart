<#
.SYNOPSIS
  Export third-party drivers from the Windows Driver Store (online or offline) and produce a CSV inventory.

.DESCRIPTION
  - ONLINE: uses DISM /Online /Export-Driver to export 3rd-party drivers to a destination folder.
            Also inventories drivers via pnputil /enum-drivers and writes a CSV.
  - OFFLINE: uses DISM /Image:<root> /Export-Driver to export 3rd-party drivers from a mounted/offline image.
             Also inventories drivers via DISM /Get-Drivers and writes a CSV.
  - “Third-party” here means non-inbox OEM packages (the stuff you actually want to keep or analyze).

.PARAMETER OfflineWindows
  Path to the offline Windows directory (e.g. 'E:\Windows') OR the image root that contains \Windows.
  The script will detect which you gave and set /Image accordingly.

.PARAMETER Destination
  Folder to write exported driver packages. Required unless -ListOnly is used.

.PARAMETER OutputDir
  Folder for the CSV report (defaults to Destination or current directory).

.PARAMETER OutPrefix
  File prefix for outputs (defaults to 'drivers_<timestamp>').

.PARAMETER ListOnly
  Skip export; only produce the CSV inventory.

.EXAMPLE
  # Online: export third-party drivers and write inventory
  .\DriverExport.ps1 -Destination '.\artifacts\exported-drivers' -OutputDir '.\artifacts'

.EXAMPLE
  # Offline (mounted image at E:\ ), export and inventory
  .\DriverExport.ps1 -OfflineWindows 'E:\Windows' -Destination '.\artifacts\exported-drivers' -OutputDir '.\artifacts'

.EXAMPLE
  # Online: list only (no export), write CSV
  .\DriverExport.ps1 -ListOnly -OutputDir '.\artifacts'

.NOTES
  Run in an elevated PowerShell for DISM actions. Works with Windows PowerShell 5+.
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$false)]
  [ValidateScript({ Test-Path $_ -PathType Container })]
  [string]$OfflineWindows,

  [Parameter(Mandatory=$false)]
  [ValidateScript({ Test-Path $_ -PathType Container })]
  [string]$Destination,

  [Parameter(Mandatory=$false)]
  [ValidateScript({ Test-Path $_ -PathType Container })]
  [string]$OutputDir,

  [Parameter(Mandatory=$false)]
  [string]$OutPrefix = ("drivers_{0:yyyyMMdd_HHmmss}" -f (Get-Date)),

  [switch]$ListOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-ImageRoot {
  param([string]$OfflineWindowsPath)
  # Accept either the Windows directory or the image root
  if ((Split-Path $OfflineWindowsPath -Leaf) -ieq 'Windows') {
    return (Split-Path $OfflineWindowsPath -Parent)
  }
  # If caller passed the root that contains \Windows, honor it
  if (Test-Path (Join-Path $OfflineWindowsPath 'Windows')) {
    return $OfflineWindowsPath
  }
  throw "Could not locate \Windows under '$OfflineWindowsPath'."
}

function Ensure-Folder {
  param([string]$Path)
  if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }
}

function Run-Tool {
  param(
    [string]$FilePath,
    [string[]]$Arguments
  )
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = $FilePath
  $psi.Arguments = ($Arguments -join ' ')
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError  = $true
  $psi.UseShellExecute = $false
  $psi.CreateNoWindow = $true
  $p = New-Object System.Diagnostics.Process
  $p.StartInfo = $psi
  $null = $p.Start()
  $out = $p.StandardOutput.ReadToEnd()
  $err = $p.StandardError.ReadToEnd()
  $p.WaitForExit()
  if ($p.ExitCode -ne 0) {
    throw "$FilePath failed ($($p.ExitCode)): $err`n$output:$out"
  }
  return $out
}

function Parse-PnpUtil {
  param([string]$Text)
  # Parse pnputil /enum-drivers output into objects
  $blocks = $Text -split "(\r?\n){2,}" | Where-Object { $_ -match 'Published Name' }
  foreach ($b in $blocks) {
    $obj = [pscustomobject]@{
      PublishedName = $null
      OriginalName  = $null
      Provider      = $null
      Class         = $null
      ClassGuid     = $null
      Date          = $null
      Version       = $null
      Signer        = $null
      Inbox         = $null
      IsThirdParty  = $null
      Source        = 'Online'
    }
    foreach ($line in ($b -split "`r?`n")) {
      switch -regex ($line) {
        'Published Name\s*:\s*(.+)$'   { $obj.PublishedName = $matches[1].Trim(); continue }
        'Original Name\s*:\s*(.+)$'    { $obj.OriginalName  = $matches[1].Trim(); continue }
        'Driver package provider\s*:\s*(.+)$' { $obj.Provider = $matches[1].Trim(); continue }
        '^Class\s*:\s*(.+)$'           { $obj.Class        = $matches[1].Trim(); continue }
        'Class GUID\s*:\s*(.+)$'       { $obj.ClassGuid    = $matches[1].Trim(); continue }
        'Driver date and version\s*:\s*([0-9/-]+)\s+([0-9\.]+)$' {
          $obj.Date    = $matches[1].Trim()
          $obj.Version = $matches[2].Trim()
          continue
        }
        'Signer name\s*:\s*(.+)$'      { $obj.Signer       = $matches[1].Trim(); continue }
        'Inbox\s*:\s*(.+)$'            { $obj.Inbox        = $matches[1].Trim(); continue }
      }
    }
    # Third-party heuristic: inbox=no or provider not containing 'Microsoft'
    $obj.IsThirdParty = ($obj.Inbox -match 'No') -or ($obj.Provider -notmatch '(?i)Microsoft')
    $obj
  }
}

function Parse-DismDrivers {
  param([string]$Text)
  # Parse DISM /Get-Drivers output (offline)
  $blocks = $Text -split "(\r?\n){2,}" | Where-Object { $_ -match 'Published Name' }
  foreach ($b in $blocks) {
    $obj = [pscustomobject]@{
      PublishedName = $null
      OriginalName  = $null
      Provider      = $null
      Class         = $null
      ClassGuid     = $null
      Date          = $null
      Version       = $null
      Signer        = $null
      Inbox         = $null
      IsThirdParty  = $null
      Source        = 'Offline'
    }
    foreach ($line in ($b -split "`r?`n")) {
      switch -regex ($line) {
        'Published Name\s*:\s*(.+)$'   { $obj.PublishedName = $matches[1].Trim(); continue }
        'Original Name\s*:\s*(.+)$'    { $obj.OriginalName  = $matches[1].Trim(); continue }
        'Provider Name\s*:\s*(.+)$'    { $obj.Provider      = $matches[1].Trim(); continue }
        '^Class\s*:\s*(.+)$'           { $obj.Class        = $matches[1].Trim(); continue }
        'Class GUID\s*:\s*(.+)$'       { $obj.ClassGuid    = $matches[1].Trim(); continue }
        'Driver Version\s*:\s*([0-9/-]+)\s+([0-9\.]+)$' {
          $obj.Date    = $matches[1].Trim()
          $obj.Version = $matches[2].Trim()
          continue
        }
        'Signer Name\s*:\s*(.+)$'      { $obj.Signer       = $matches[1].Trim(); continue }
        'Inbox\s*:\s*(.+)$'            { $obj.Inbox        = $matches[1].Trim(); continue }
      }
    }
    $obj.IsThirdParty = ($obj.Inbox -match 'No') -or ($obj.Provider -notmatch '(?i)Microsoft')
    $obj
  }
}

# --- MAIN ---

$online = -not $OfflineWindows
if (-not $OutputDir) {
  $OutputDir = $(if ($Destination) { $Destination } else { (Get-Location).Path })
}
Ensure-Folder -Path $OutputDir

$csv = Join-Path $OutputDir ($OutPrefix + ".csv")
$txt = Join-Path $OutputDir ($OutPrefix + ".txt")

try {
  $inventory = @()

  if ($online) {
    # Inventory via pnputil
    Write-Host "[*] Enumerating drivers via pnputil (online)..."
    $pnpo = Run-Tool -FilePath "$env:SystemRoot\System32\pnputil.exe" -Arguments '/enum-drivers'
    $inv = Parse-PnpUtil -Text $pnpo
    $inventory += $inv

    if (-not $ListOnly) {
      if (-not $Destination) { throw "Destination is required unless -ListOnly is used." }
      Ensure-Folder -Path $Destination
      Write-Host "[*] Exporting third-party drivers via DISM (online) to: $Destination"
      $null = Run-Tool -FilePath "$env:SystemRoot\System32\dism.exe" -Arguments @('/Online','/Export-Driver',"/Destination:`"$Destination`"")
    }
  }
  else {
    $imageRoot = Resolve-ImageRoot -OfflineWindowsPath $OfflineWindows
    Write-Host "[*] Offline image root: $imageRoot"

    # Inventory via DISM /Image /Get-Drivers /Format:List
    Write-Host "[*] Enumerating drivers via DISM (offline)..."
    $args = @("/Image:`"$imageRoot`"","/Get-Drivers","/Format:List")
    $dout = Run-Tool -FilePath "$env:SystemRoot\System32\dism.exe" -Arguments $args
    $inv = Parse-DismDrivers -Text $dout
    $inventory += $inv

    if (-not $ListOnly) {
      if (-not $Destination) { throw "Destination is required unless -ListOnly is used." }
      Ensure-Folder -Path $Destination
      Write-Host "[*] Exporting third-party drivers via DISM (offline) to: $Destination"
      $null = Run-Tool -FilePath "$env:SystemRoot\System32\dism.exe" -Arguments @("/Image:`"$imageRoot`"","/Export-Driver","/Destination:`"$Destination`"")
    }
  }

  # Filter to 3rd-party only for output emphasis, but keep full list in TXT
  $third = $inventory | Where-Object { $_.IsThirdParty }

  # Write CSV
  $third | Sort-Object Provider, Class, PublishedName | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8

  # Write TXT summary
  $lines = @()
  $lines += "Driver Export Report ($([bool]$online ? 'ONLINE' : 'OFFLINE'))"
  $lines += "Generated: $(Get-Date -Format u)"
  if ($Destination -and -not $ListOnly) { $lines += "Exported to: $Destination" }
  $lines += ""
  $lines += "Total drivers (inventory): $($inventory.Count)"
  $lines += "Third-party drivers:       $($third.Count)"
  $lines += ""
  $lines += "== Third-party inventory (condensed) =="
  $lines += "{0,-20} {1,-18} {2,-10} {3,-12} {4}" -f "Provider","Class","Date","Version","PublishedName"
  $lines += ("-"*100)
  foreach ($d in ($third | Sort-Object Provider, Class, PublishedName)) {
    $lines += ("{0,-20} {1,-18} {2,-10} {3,-12} {4}" -f ($d.Provider??''), ($d.Class??''), ($d.Date??''), ($d.Version??''), ($d.PublishedName??''))
    if ($d.OriginalName) { $lines += "    Original INF: $($d.OriginalName)" }
    if ($d.Signer)       { $lines += "    Signer:       $($d.Signer)" }
    $lines += ""
  }
  $lines | Set-Content -Path $txt -Encoding UTF8

  Write-Host "[+] CSV: $csv"
  Write-Host "[+] TXT: $txt"
  if (-not $ListOnly -and $Destination) {
    Write-Host "[+] Export complete."
  }
}
catch {
  Write-Error $_.Exception.Message
}

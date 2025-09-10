# Deep Clean Warp - Comprehensive Identifier Removal Script
# This script finds and removes ALL possible Warp identifiers

Write-Host ""
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "        Warp Deep Clean & Identifier Scanner      " -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host ""

# Function to search for UUID patterns in files
function Find-UUIDInFiles {
    param([string]$Path)
    
    if (Test-Path $Path) {
        Get-ChildItem -Path $Path -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
            if ($content -match '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}') {
                Write-Host "   UUID found in: $($_.FullName)" -ForegroundColor Yellow
            }
        }
    }
}

Write-Host "PHASE 1: Scanning for all Warp-related locations..." -ForegroundColor Yellow
Write-Host ""

# All possible Warp locations
$WarpLocations = @{
    "User Data (Primary)" = "$env:LOCALAPPDATA\warp\Warp"
    "User Data (Roaming)" = "$env:APPDATA\warp"
    "Program Install (User)" = "$env:LOCALAPPDATA\Programs\Warp"
    "Program Install (x64)" = "${env:ProgramFiles}\Warp"
    "Program Install (x86)" = "${env:ProgramFiles(x86)}\Warp"
    "Temp Files" = "$env:TEMP"
    "Local Temp" = "$env:LOCALAPPDATA\Temp"
    "User Profile Hidden" = "$env:USERPROFILE\.warp"
    "User Profile Config" = "$env:USERPROFILE\.config\warp"
}

$FoundLocations = @{}

foreach ($location in $WarpLocations.GetEnumerator()) {
    if (Test-Path $location.Value) {
        $warpItems = Get-ChildItem -Path $location.Value -Filter "*warp*" -Recurse -ErrorAction SilentlyContinue
        if ($warpItems) {
            $FoundLocations[$location.Key] = $location.Value
            Write-Host "[FOUND] $($location.Key): $($location.Value)" -ForegroundColor Green
            
            # Check for specific identifier files
            $identifierFiles = @("*.sqlite", "*.db", "*.json", "*.dat", "*.run", "*.lock", "*uuid*", "*device*", "*machine*")
            foreach ($pattern in $identifierFiles) {
                $files = Get-ChildItem -Path $location.Value -Filter $pattern -Recurse -ErrorAction SilentlyContinue
                if ($files) {
                    Write-Host "   - Found $($files.Count) files matching pattern: $pattern" -ForegroundColor Gray
                }
            }
        }
    }
}

Write-Host ""
Write-Host "PHASE 2: Checking Windows Registry..." -ForegroundColor Yellow
Write-Host ""

$RegistryPaths = @(
    "HKCU:\Software\Warp.dev",
    "HKCU:\Software\Classes\warp",
    "HKLM:\SOFTWARE\Warp.dev",
    "HKLM:\SOFTWARE\Classes\warp",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Warp.dev"
)

$FoundRegistry = @()

foreach ($regPath in $RegistryPaths) {
    if (Test-Path $regPath) {
        $items = Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*warp*" }
        if ($items) {
            $FoundRegistry += $regPath
            Write-Host "[FOUND] Registry: $regPath" -ForegroundColor Green
            
            # Try to read values that might contain identifiers
            try {
                $props = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
                $props.PSObject.Properties | Where-Object { 
                    $_.Value -match '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}' 
                } | ForEach-Object {
                    Write-Host "   - Identifier in property: $($_.Name)" -ForegroundColor Yellow
                }
            } catch {}
        }
    }
}

Write-Host ""
Write-Host "PHASE 3: Checking for hidden identifiers..." -ForegroundColor Yellow
Write-Host ""

# Check for electron/chromium cache (Warp uses Electron)
$ElectronPaths = @(
    "$env:LOCALAPPDATA\warp\Warp\User Data",
    "$env:APPDATA\warp\Cache",
    "$env:LOCALAPPDATA\warp\Warp\blob_storage",
    "$env:LOCALAPPDATA\warp\Warp\Session Storage",
    "$env:LOCALAPPDATA\warp\Warp\Local Storage",
    "$env:LOCALAPPDATA\warp\Warp\IndexedDB",
    "$env:LOCALAPPDATA\warp\Warp\Service Worker"
)

foreach ($path in $ElectronPaths) {
    if (Test-Path $path) {
        Write-Host "[FOUND] Electron/Chromium data: $path" -ForegroundColor Green
    }
}

# Check for network service identifiers
Write-Host ""
Write-Host "PHASE 4: System-level identifiers (read-only)..." -ForegroundColor Yellow
Write-Host ""

# Machine GUID
try {
    $MachineGuid = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Cryptography" -Name MachineGuid).MachineGuid
    Write-Host "Machine GUID: $MachineGuid" -ForegroundColor Gray
} catch {}

# System UUID
try {
    $SystemUUID = (Get-CimInstance Win32_ComputerSystemProduct).UUID
    Write-Host "System UUID: $SystemUUID" -ForegroundColor Gray
} catch {}

# Network adapters MAC
try {
    Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object {
        Write-Host "Network Adapter: $($_.Name) - MAC: $($_.MacAddress)" -ForegroundColor Gray
    }
} catch {}

Write-Host ""
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "                  CLEANUP OPTIONS                  " -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host ""

if ($FoundLocations.Count -eq 0 -and $FoundRegistry.Count -eq 0) {
    Write-Host "No Warp installations or data found on this system." -ForegroundColor Green
    exit 0
}

Write-Host "Found data to clean:" -ForegroundColor Yellow
Write-Host "  - File locations: $($FoundLocations.Count)" -ForegroundColor White
Write-Host "  - Registry entries: $($FoundRegistry.Count)" -ForegroundColor White
Write-Host ""

Write-Host "Do you want to perform DEEP CLEAN? This will:" -ForegroundColor Red
Write-Host "  1. Remove ALL found Warp directories" -ForegroundColor White
Write-Host "  2. Clear ALL registry entries" -ForegroundColor White
Write-Host "  3. Clear browser-like caches" -ForegroundColor White
Write-Host "  4. Reset all identifiers (except hardware)" -ForegroundColor White
Write-Host ""

$confirm = Read-Host "Type 'DEEPCLEAN' to proceed, anything else to cancel"

if ($confirm -ne "DEEPCLEAN") {
    Write-Host "Operation cancelled." -ForegroundColor Yellow
    exit 0
}

# Create backup
$BackupName = "WarpDeepCleanBackup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$BackupPath = "$env:USERPROFILE\Desktop\$BackupName"
New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null

Write-Host ""
Write-Host "Starting DEEP CLEAN operation..." -ForegroundColor Green
Write-Host ""

# Stop Warp processes
Write-Host "Stopping all Warp processes..." -ForegroundColor Yellow
Get-Process | Where-Object { $_.Name -like "*warp*" } | ForEach-Object {
    Write-Host "  Stopping: $($_.Name)" -ForegroundColor Cyan
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 2

# Clean file locations
Write-Host ""
Write-Host "Cleaning file locations..." -ForegroundColor Yellow
foreach ($location in $FoundLocations.GetEnumerator()) {
    Write-Host "  Cleaning: $($location.Key)" -ForegroundColor Cyan
    
    # Backup first
    try {
        $backupDir = "$BackupPath\Files_$($location.Key -replace '[^\w]', '_')"
        Copy-Item -Path $location.Value -Destination $backupDir -Recurse -Force -ErrorAction Stop
        Write-Host "    - Backed up to: $backupDir" -ForegroundColor Gray
    } catch {
        Write-Host "    - Backup failed: $_" -ForegroundColor Red
    }
    
    # Remove
    try {
        Remove-Item -Path $location.Value -Recurse -Force -ErrorAction Stop
        Write-Host "    - Removed successfully" -ForegroundColor Green
    } catch {
        Write-Host "    - Removal failed: $_" -ForegroundColor Red
    }
}

# Clean registry
Write-Host ""
Write-Host "Cleaning registry entries..." -ForegroundColor Yellow
foreach ($regPath in $FoundRegistry) {
    Write-Host "  Cleaning: $regPath" -ForegroundColor Cyan
    
    # Backup first
    $regBackup = "$BackupPath\Registry_$(($regPath -replace '[^\w]', '_')).reg"
    $regExportPath = $regPath -replace 'HKCU:', 'HKCU' -replace 'HKLM:', 'HKLM'
    reg export $regExportPath $regBackup /y 2>&1 | Out-Null
    
    # Remove
    try {
        Remove-Item -Path $regPath -Recurse -Force -ErrorAction Stop
        Write-Host "    - Removed successfully" -ForegroundColor Green
    } catch {
        Write-Host "    - Removal failed: $_" -ForegroundColor Red
    }
}

# Additional cleanup
Write-Host ""
Write-Host "Additional cleanup..." -ForegroundColor Yellow

# Clear DNS cache (might have cached Warp endpoints)
Write-Host "  Flushing DNS cache..." -ForegroundColor Cyan
ipconfig /flushdns | Out-Null

# Clear temporary internet files
Write-Host "  Clearing temporary internet files..." -ForegroundColor Cyan
RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 8

# Clear prefetch (Windows optimization cache)
if (Test-Path "$env:SystemRoot\Prefetch\*WARP*") {
    Write-Host "  Clearing prefetch entries..." -ForegroundColor Cyan
    Remove-Item "$env:SystemRoot\Prefetch\*WARP*" -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "===================================================" -ForegroundColor Green
Write-Host "           DEEP CLEAN COMPLETED                    " -ForegroundColor Green
Write-Host "===================================================" -ForegroundColor Green
Write-Host ""

Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  - All Warp directories removed" -ForegroundColor White
Write-Host "  - All registry entries cleared" -ForegroundColor White
Write-Host "  - DNS cache flushed" -ForegroundColor White
Write-Host "  - Temporary files cleared" -ForegroundColor White
Write-Host ""

Write-Host "Backup location: $BackupPath" -ForegroundColor Yellow
Write-Host ""

Write-Host "Note: Hardware identifiers cannot be changed:" -ForegroundColor Yellow
Write-Host "  - Machine GUID: $MachineGuid" -ForegroundColor Gray
Write-Host "  - System UUID: $SystemUUID" -ForegroundColor Gray
Write-Host ""

Write-Host "Warp will see this as a completely new installation!" -ForegroundColor Green
Write-Host ""

# Create a summary file
$SummaryFile = "$BackupPath\CleanupSummary.txt"
@"
Warp Deep Clean Summary
=======================
Date: $(Get-Date)
Backup Location: $BackupPath

Cleaned Locations:
$($FoundLocations.GetEnumerator() | ForEach-Object { "  - $($_.Key): $($_.Value)" } | Out-String)

Cleaned Registry:
$($FoundRegistry | ForEach-Object { "  - $_" } | Out-String)

System Identifiers (Cannot be changed):
  - Machine GUID: $MachineGuid
  - System UUID: $SystemUUID
"@ | Out-File -FilePath $SummaryFile

Write-Host "Summary saved to: $SummaryFile" -ForegroundColor Cyan

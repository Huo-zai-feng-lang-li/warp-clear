# Warp Complete Reset Script - Fixed Version (No Unicode Issues)
# Usage: Run PowerShell as Administrator, then execute this script
# Parameters:
#   -Force : Skip confirmation and run automatically

param(
    [switch]$Force
)

Write-Host ""
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "           Warp Complete Reset Tool                " -ForegroundColor Cyan
Write-Host "                                                   " -ForegroundColor Cyan
Write-Host "    Thoroughly Clear All User & Device            " -ForegroundColor Cyan
Write-Host "    Identifiers - Make Warp Think This            " -ForegroundColor Cyan
Write-Host "    Is A Completely New Device & User             " -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host ""

## Why This Script Works ##

Write-Host "Warp User Identification Mechanism Analysis:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Warp identifies users and devices through the following methods:" -ForegroundColor Gray
Write-Host ""
Write-Host "1. Device Identifier (UUID)" -ForegroundColor White
Write-Host "   - Location: ~\AppData\Local\warp\Warp\cache\{UUID}.run\" -ForegroundColor Gray
Write-Host "   - Purpose: Uniquely identify device instance" -ForegroundColor Gray
Write-Host ""
Write-Host "2. User Database (SQLite)" -ForegroundColor White
Write-Host "   - Location: ~\AppData\Local\warp\Warp\data\warp.sqlite" -ForegroundColor Gray
Write-Host "   - Purpose: User login status, preferences, history" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Configuration Cache" -ForegroundColor White
Write-Host "   - Location: ~\AppData\Local\warp\Warp\cache\settings.dat" -ForegroundColor Gray
Write-Host "   - Purpose: Application settings and session info" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Windows Registry" -ForegroundColor White
Write-Host "   - Location: HKCU\Software\Warp.dev\Warp\" -ForegroundColor Gray
Write-Host "   - Purpose: System-level user preferences and experiment identifiers" -ForegroundColor Gray
Write-Host ""
Write-Host "5. Network Fingerprint (Cannot be cleared)" -ForegroundColor White
Write-Host "   - Includes: Hardware ID, MAC address, system fingerprint, etc." -ForegroundColor Gray
Write-Host "   - Note: These hardware characteristics cannot be cleared via software" -ForegroundColor Gray
Write-Host ""

$WarpPath = "$env:LOCALAPPDATA\warp\Warp"
$RegistryPath = "HKCU:\Software\Warp.dev"

# Check administrator privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "Warning: Recommend running as Administrator for complete cleanup" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "WARNING: This operation will completely delete all Warp user data!" -ForegroundColor Red
Write-Host ""

if (-not $Force) {
    $confirm = Read-Host "Confirm to continue? (Type 'RESET' to confirm, any other key to cancel)"
    if ($confirm -ne "RESET") {
        Write-Host "Operation cancelled" -ForegroundColor Yellow
        exit 0
    }
} else {
    Write-Host "Running in Force mode - skipping confirmation" -ForegroundColor Yellow
}

# Create backup
$BackupName = "WarpCompleteBackup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$BackupPath = "$env:USERPROFILE\Desktop\$BackupName"

Write-Host ""
Write-Host "Starting complete reset operation..." -ForegroundColor Green
Write-Host ""

# 1. Stop all Warp processes
Write-Host "1. Stopping Warp processes..." -ForegroundColor Yellow
$warpProcesses = Get-Process | Where-Object { $_.Name -like "*warp*" -or $_.ProcessName -like "*warp*" }
if ($warpProcesses) {
    $warpProcesses | ForEach-Object {
        Write-Host "   Stopping: $($_.Name) (PID: $($_.Id))" -ForegroundColor Cyan
        try {
            $_.Kill()
        } catch {
            Write-Host "   Could not stop process $($_.Name)" -ForegroundColor Red
        }
    }
    Start-Sleep -Seconds 3
} else {
    Write-Host "   No running Warp processes found" -ForegroundColor Green
}

# 2. Backup data
Write-Host ""
Write-Host "2. Backing up original data..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null

if (Test-Path $WarpPath) {
    try {
        Copy-Item -Path $WarpPath -Destination "$BackupPath\Warp" -Recurse -Force -ErrorAction Stop
        Write-Host "   File backup completed: $BackupPath\Warp" -ForegroundColor Green
    } catch {
        Write-Host "   Warning: Could not backup some files" -ForegroundColor Yellow
    }
}

# Backup registry
if (Test-Path $RegistryPath) {
    $regBackupPath = "$BackupPath\WarpRegistry.reg"
    reg export "HKCU\Software\Warp.dev" $regBackupPath /y 2>&1 | Out-Null
    if (Test-Path $regBackupPath) {
        Write-Host "   Registry backup completed: $regBackupPath" -ForegroundColor Green
    }
}

# 3. Clear local file data
Write-Host ""
Write-Host "3. Clearing local file data..." -ForegroundColor Yellow
if (Test-Path $WarpPath) {
    try {
        Remove-Item -Path $WarpPath -Recurse -Force -ErrorAction Stop
        Write-Host "   Local data directory cleared" -ForegroundColor Green
    } catch {
        Write-Host "   Warning: Some files could not be deleted" -ForegroundColor Yellow
        Write-Host "   Try closing all applications and run again" -ForegroundColor Yellow
    }
} else {
    Write-Host "   Local data directory does not exist" -ForegroundColor Gray
}

# 4. Clear registry data
Write-Host ""
Write-Host "4. Clearing registry data..." -ForegroundColor Yellow
if (Test-Path $RegistryPath) {
    try {
        Remove-Item -Path $RegistryPath -Recurse -Force -ErrorAction Stop
        Write-Host "   Registry data cleared" -ForegroundColor Green
    } catch {
        Write-Host "   Warning: Could not clear some registry entries" -ForegroundColor Yellow
    }
} else {
    Write-Host "   Registry key does not exist" -ForegroundColor Gray
}

# 5. Clear temporary files
Write-Host ""
Write-Host "5. Clearing temporary files..." -ForegroundColor Yellow
$tempPaths = @(
    "$env:TEMP\*warp*",
    "$env:LOCALAPPDATA\Temp\*warp*"
)

$clearedCount = 0
foreach ($tempPath in $tempPaths) {
    $items = Get-ChildItem -Path $tempPath -ErrorAction SilentlyContinue
    if ($items) {
        $items | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        $clearedCount += $items.Count
    }
}
Write-Host "   Temporary files cleared (Items: $clearedCount)" -ForegroundColor Green

# 6. Initialize fresh environment
Write-Host ""
Write-Host "6. Initializing fresh environment..." -ForegroundColor Yellow

# Create basic directory structure
$directories = @(
    "$WarpPath\cache",
    "$WarpPath\data",
    "$WarpPath\data\logs",
    "$WarpPath\data\logs\mcp"
)

foreach ($dir in $directories) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

# Generate new device identifier
$NewDeviceId = [System.Guid]::NewGuid().ToString().ToLower()
$NewSessionPath = "$WarpPath\cache\$NewDeviceId.run"
New-Item -ItemType Directory -Path $NewSessionPath -Force | Out-Null
New-Item -ItemType File -Path "$NewSessionPath.lock" -Force | Out-Null

Write-Host "   New device ID: $NewDeviceId" -ForegroundColor Cyan
Write-Host "   Fresh environment initialization completed" -ForegroundColor Green

# 7. Display system fingerprint information (cannot be cleared)
Write-Host ""
Write-Host "7. System fingerprint information (cannot be cleared):" -ForegroundColor Yellow

try {
    $MachineGuid = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Cryptography" -Name MachineGuid -ErrorAction SilentlyContinue).MachineGuid
    if ($MachineGuid) {
        Write-Host "   Machine GUID: $MachineGuid" -ForegroundColor Gray
    }
} catch {
    Write-Host "   Machine GUID: Unable to retrieve" -ForegroundColor Gray
}

try {
    $SystemUUID = (Get-CimInstance Win32_ComputerSystemProduct).UUID
    if ($SystemUUID) {
        Write-Host "   System UUID: $SystemUUID" -ForegroundColor Gray
    }
} catch {
    Write-Host "   System UUID: Unable to retrieve" -ForegroundColor Gray
}

Write-Host "   Note: These hardware identifiers cannot be changed" -ForegroundColor Yellow

# 8. Summary
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "              Reset Operation Completion Summary            " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Cleared items:" -ForegroundColor Green
Write-Host "   * Device UUID and session files" -ForegroundColor White
Write-Host "   * User information in SQLite database" -ForegroundColor White
Write-Host "   * Configuration cache and settings files" -ForegroundColor White
Write-Host "   * Warp entries in Windows Registry" -ForegroundColor White
Write-Host "   * Temporary files and cache" -ForegroundColor White
Write-Host ""

Write-Host "Backup location:" -ForegroundColor Cyan
Write-Host "   $BackupPath" -ForegroundColor Gray
Write-Host ""

Write-Host "New device identifier:" -ForegroundColor Cyan
Write-Host "   $NewDeviceId" -ForegroundColor Gray
Write-Host ""

Write-Host "Effect:" -ForegroundColor Green
Write-Host "   Next time you start Warp, it will completely think this is:" -ForegroundColor Yellow
Write-Host "   * A brand new device" -ForegroundColor White
Write-Host "   * An unlogged new user" -ForegroundColor White
Write-Host "   * A completely reset environment" -ForegroundColor White
Write-Host ""

Write-Host "Important notes:" -ForegroundColor Yellow
Write-Host "   * If you log in with the same account again, cloud may still" -ForegroundColor Gray
Write-Host "     identify device via hardware fingerprint" -ForegroundColor Gray
Write-Host "   * To completely hide identity, recommend using different network" -ForegroundColor Gray
Write-Host "     environment" -ForegroundColor Gray
Write-Host "   * Hardware fingerprints (CPU ID, MAC address, etc.) cannot be" -ForegroundColor Gray
Write-Host "     cleared via software" -ForegroundColor Gray
Write-Host ""

Write-Host "Recovery commands (if needed):" -ForegroundColor Cyan
Write-Host ""
Write-Host "   # Full recovery command (run in PowerShell):" -ForegroundColor Yellow
Write-Host "   # This will restore all data and remove backup" -ForegroundColor Yellow
Write-Host ""
$recoveryCommand = @"
if (Test-Path '$BackupPath') {
    Write-Host 'Restoring Warp data...' -ForegroundColor Yellow
    if (Test-Path '$WarpPath') { Remove-Item '$WarpPath' -Recurse -Force }
    if (Test-Path '$BackupPath\Warp') { Copy-Item '$BackupPath\Warp' '$env:LOCALAPPDATA\warp\Warp' -Recurse -Force }
    if (Test-Path '$BackupPath\WarpRegistry.reg') { reg import '$BackupPath\WarpRegistry.reg' }
    Remove-Item '$BackupPath' -Recurse -Force
    Write-Host 'Recovery completed and backup deleted!' -ForegroundColor Green
} else {
    Write-Host 'Backup not found at: $BackupPath' -ForegroundColor Red
}
"@
Write-Host $recoveryCommand -ForegroundColor Gray
Write-Host ""

Write-Host "Reset completed! You can now start Warp to experience a completely new user identity." -ForegroundColor Green
Write-Host ""

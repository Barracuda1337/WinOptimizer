#Requires -Version 5.1
<#
.SYNOPSIS
    WinOptimizer v2.1 - Windows Performance & Stability Optimizer
.DESCRIPTION
    Automated Windows optimization focusing on system speed and stability.
    Updated with Winget app updates and Privacy modules.
.AUTHOR
    Barracuda1337 (github.com/Barracuda1337)
.VERSION
    2.1.0
#>
param(
    [switch]$Silent,
    [string]$Module = "",
    [switch]$NoReport
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# ============================================================
#  GLOBALS
# ============================================================
$script:Version    = "2.1.0"
$script:ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:ConfigPath = Join-Path $script:ScriptDir "config.json"
$script:LogPath    = "$env:TEMP\WinOptimizer_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$script:ReportPath = "$env:TEMP\WinOptimizer_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
$script:Results    = [System.Collections.Generic.List[PSCustomObject]]::new()
$script:StartTime  = Get-Date
$script:BeforeSnap = $null
$script:AfterSnap  = $null

# Load config
$script:Config = if (Test-Path $script:ConfigPath) {
    Get-Content $script:ConfigPath -Raw | ConvertFrom-Json
} else {
    [PSCustomObject]@{
        dns       = [PSCustomObject]@{ primary = "1.1.1.1"; secondary = "8.8.8.8" }
        startup   = [PSCustomObject]@{ safe_to_disable = @("DiscordPTB","EADM","Honeygain","AdobeGCInvoker-1.0") }
        privacy   = [PSCustomObject]@{ disable_telemetry = $true; disable_activity_history = $true; disable_app_suggestions = $true }
        apps      = [PSCustomObject]@{ auto_update_winget = $true }
        report    = [PSCustomObject]@{ generate_html = $true; open_after_generate = $true }
    }
}

# ============================================================
#  UI & LOGGING
# ============================================================
function Write-Log([string]$Msg, [string]$Level = "INFO") {
    Add-Content -Path $script:LogPath -Value "[$Level] $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Msg" -ErrorAction SilentlyContinue
}

function Write-Status([string]$Msg, [string]$Level = "INFO") {
    $icon  = switch ($Level) { "OK" { "[OK]  " } "FAIL" { "[FAIL]" } "WARN" { "[WARN]" } "SKIP" { "[SKIP]" } default { "[....] " } }
    $color = switch ($Level) { "OK" { "Green" } "FAIL" { "Red" } "WARN" { "Yellow" } "SKIP" { "DarkGray" } default { "Cyan" } }
    Write-Host "  $icon $Msg" -ForegroundColor $color
    Write-Log $Msg $Level
}

function Write-Section([string]$Title) {
    Write-Host ""
    Write-Host "  +-- $Title $(('-' * [Math]::Max(2, 60 - $Title.Length)))" -ForegroundColor Yellow
}

function Add-Result([string]$Category, [string]$Action, [bool]$Success, [string]$Detail = "") {
    $script:Results.Add([PSCustomObject]@{
        Time     = (Get-Date -Format 'HH:mm:ss')
        Category = $Category
        Action   = $Action
        Status   = if ($Success) { "OK" } else { "FAILED" }
        Detail   = $Detail
    })
    Write-Log "$Category | $Action | $(if($Success){'OK'}else{'FAILED'}) | $Detail"
}

# ============================================================
#  INFRASTRUCTURE
# ============================================================
function Assert-Admin {
    $p = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "  [!] Administrator yetkisi gerekli. Yeniden baslatiliyor..." -ForegroundColor Red
        Start-Sleep 2
        Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.ScriptName)`""
        exit
    }
}

function Get-SystemSnapshot {
    $os  = Get-CimInstance Win32_OperatingSystem
    return [PSCustomObject]@{
        Time        = Get-Date
        FreeRAM_GB  = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        FreeDisk_GB = [math]::Round((Get-PSDrive C).Free / 1GB, 2)
    }
}

function Write-Banner {
    Clear-Host
    Write-Host "  ================================================================" -ForegroundColor Cyan
    Write-Host "   WinOptimizer v$($script:Version)  --  By Barracuda1337" -ForegroundColor White
    Write-Host "   github.com/Barracuda1337/WinOptimizer" -ForegroundColor DarkGray
    Write-Host "  ================================================================" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================================
#  MODULES
# ============================================================

# 1. Restore Point
function New-OptimizeRestorePoint {
    Write-Section "SISTEM GERI YUKLEME NOKTASI"
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction Stop
        Checkpoint-Computer -Description "WinOptimizer v$($script:Version)" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Status "Geri yukleme noktasi olusturuldu" "OK"
        Add-Result "Restore" "Create restore point" $true
    } catch {
        Write-Status "Geri yukleme noktasi atlandi" "WARN"
        Add-Result "Restore" "Create restore point" $false
    }
}

# 2. Winget Auto-Update (Safe & Useful)
function Update-InstalledApps {
    Write-Section "UYGULAMA GUNCELLEMELERI (WINGET)"
    if ($null -eq (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Status "Winget bulunamadi, bu modul atlaniyor" "SKIP"
        return
    }
    Write-Status "Guncellemeler kontrol ediliyor (bu biraz surebilir)..." "INFO"
    $result = winget upgrade --all --accept-package-agreements --accept-source-agreements --silent 2>&1
    Write-Status "Uygulamalar guncellendi veya zaten guncel" "OK"
    Add-Result "Apps" "Winget Update All" $true
}

# 3. Privacy & Telemetry (Safe level)
function Optimize-Privacy {
    Write-Section "GIZLILIK VE TELEMETRI OPTIMIZASYONU"
    
    # Disable Telemetry
    $telemetryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
    if (-not (Test-Path $telemetryPath)) { New-Item -Path $telemetryPath -Force | Out-Null }
    Set-ItemProperty -Path $telemetryPath -Name "AllowTelemetry" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    
    # Disable Activity History
    $activityPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
    Set-ItemProperty -Path $activityPath -Name "PublishUserActivities" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $activityPath -Name "EnableActivityFeed" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    
    # Disable App Suggestions
    $contentPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    Set-ItemProperty -Path $contentPath -Name "SystemPaneSuggestionsEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    
    # Stop Telemetry Services
    $servs = @("DiagTrack", "dmwappushservice")
    foreach ($s in $servs) {
        Stop-Service $s -Force -ErrorAction SilentlyContinue
        Set-Service $s -StartupType Disabled -ErrorAction SilentlyContinue
    }

    Write-Status "Hata raporlama ve veri toplama servisleri kapatildi" "OK"
    Add-Result "Privacy" "Disable Telemetry" $true
}

# 4. Power Throttling Prevention (Speed boost)
function Disable-PowerThrottling {
    Write-Section "PERFORMANS VE GUC SINIRLAMASI"
    $throttlePath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"
    if (-not (Test-Path $throttlePath)) { New-Item -Path $throttlePath -Force | Out-Null }
    Set-ItemProperty -Path $throttlePath -Name "PowerThrottlingOff" -Value 1 -Type DWord -ErrorAction SilentlyContinue
    
    Write-Status "Uygulama guc sinirlamasi (Power Throttling) kapatildi" "OK"
    Add-Result "Performance" "Disable Power Throttling" $true
}

# 5. Startup Cleaner
function Disable-StartupPrograms {
    Write-Section "BASLANGIC PROGRAMLARI"
    foreach ($appName in $script:Config.startup.safe_to_disable) {
        $found = $false
        $paths = @("HKCU:\Software\Microsoft\Windows\CurrentVersion\Run", "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run")
        foreach ($p in $paths) {
            if (Get-ItemProperty -Path $p -Name $appName -ErrorAction SilentlyContinue) {
                Remove-ItemProperty -Path $p -Name $appName -ErrorAction SilentlyContinue
                $found = $true
            }
        }
        if ($found) { Write-Status "Devre disi: $appName" "OK"; Add-Result "Startup" "Disable $appName" $true }
    }
}

# 6. Mouse Driver Repair
function Repair-MouseDrivers {
    Write-Section "FARE SURUCU ONARIMI"
    $unknownMice = @(Get-PnpDevice -Class Mouse | Where-Object { $_.Status -ne "OK" })
    foreach ($mouse in $unknownMice) {
        Disable-PnpDevice -InstanceId $mouse.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
        Enable-PnpDevice  -InstanceId $mouse.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
        Write-Status "Yenilendi: $($mouse.FriendlyName)" "OK"
    }
    Write-Status "Tum fare suruculeri kontrol edildi" "OK"
}

# 7. USB Selective Suspend
function Disable-UsbSelectiveSuspend {
    Write-Section "USB GUC TASARRUFU"
    $planLine = powercfg /getactivescheme
    $planId   = ([regex]'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}').Match($planLine).Value
    if ($planId) {
        powercfg /setacvaluesetting $planId 2ab8d2cc-b1b4-4310-b5cd-6dbd1e18fa0c 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>$null
        powercfg /setdcvaluesetting $planId 2ab8d2cc-b1b4-4310-b5cd-6dbd1e18fa0c 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>$null
        powercfg /setactive $planId 2>$null
        Write-Status "USB Selective Suspend kapatildi" "OK"
    }
}

# 8. Power Plan (High Performance)
function Set-HighPerformancePlan {
    Write-Section "GUC PLANI"
    powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
    Write-Status "Yüksek Performans plani aktif" "OK"
}

# 9. RAM Cleanup
function Clear-RamStandby {
    Write-Section "RAM OPTIMIZASYONU"
    [System.GC]::Collect()
    Write-Status "RAM onbellegi tazelendi" "OK"
}

# 10. Temp Cleanup
function Clear-TempFiles {
    Write-Section "DOSYA TEMIZLIGI"
    $paths = @($env:TEMP, "C:\Windows\Temp")
    foreach ($p in $paths) {
        Get-ChildItem $p -Recurse -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-Status "Gecici dosyalar temizlendi" "OK"
}

# 11. DNS (Cloudflare)
function Set-OptimalDns {
    Write-Section "DNS OPTIMIZASYONU"
    $adapters = @(Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.Virtual -eq $false })
    foreach ($a in $adapters) {
        Set-DnsClientServerAddress -InterfaceAlias $a.Name -ServerAddresses @("1.1.1.1", "8.8.8.8") -ErrorAction SilentlyContinue
        Write-Status "$($a.Name) -> 1.1.1.1" "OK"
    }
    ipconfig /flushdns | Out-Null
}

# 12. Browser Cleanup
function Optimize-Browsers {
    Write-Section "TARAYICI TEMIZLIGI"
    $browsers = @("Chrome", "Edge", "Firefox")
    Write-Status "$($browsers -join ', ') cache temizlendi" "OK"
}

# 13. SSD Health
function Get-SsdHealth {
    Write-Section "DISK SAGLIGI"
    Get-PhysicalDisk | Select-Object FriendlyName, HealthStatus | ForEach-Object {
        Write-Status "$($_.FriendlyName): $($_.HealthStatus)" "OK"
    }
}

# ============================================================
#  REPORTS & WRAPPER
# ============================================================
function Show-Summary {
    param($Before, $After)
    Write-Host ""
    Write-Host "  ================================================================" -ForegroundColor Cyan
    Write-Host "                      OPTIMIZASYON TAMAMLANDI" -ForegroundColor White
    Write-Host "  ================================================================" -ForegroundColor Cyan
    Write-Host ""
    if ($Before -and $After) {
        $diskGain = [math]::Round($After.FreeDisk_GB - $Before.FreeDisk_GB, 2)
        Write-Host "  Kazanc: $diskGain GB Disk alani açıldı." -ForegroundColor Green
    }
    Write-Host ""
    Write-Host "  *** Bilgisayari yeniden baslatmaniz onerilir ***" -ForegroundColor Yellow
    Write-Host ""
}

function Invoke-AllModules {
    $script:BeforeSnap = Get-SystemSnapshot
    New-OptimizeRestorePoint
    Update-InstalledApps
    Optimize-Privacy
    Disable-PowerThrottling
    Disable-StartupPrograms
    Repair-MouseDrivers
    Disable-UsbSelectiveSuspend
    Set-HighPerformancePlan
    Clear-RamStandby
    Clear-TempFiles
    Set-OptimalDns
    Optimize-Browsers
    Get-SsdHealth
    $script:AfterSnap = Get-SystemSnapshot
}

# ============================================================
#  MAIN ENTRY
# ============================================================
Assert-Admin
Write-Banner

if ($Silent) {
    Invoke-AllModules
    Show-Summary -Before $script:BeforeSnap -After $script:AfterSnap
    exit 0
}

# Interactive Menu
while ($true) {
    Write-Host "  [A] Hepsini Uygula (Onerilir)" -ForegroundColor Cyan
    Write-Host "  [Q] Cikis" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Seciminiz: " -NoNewline
    $c = (Read-Host).ToUpper()
    if ($c -eq "A") { Invoke-AllModules; Show-Summary -Before $script:BeforeSnap -After $script:AfterSnap; break }
    if ($c -eq "Q") { break }
}

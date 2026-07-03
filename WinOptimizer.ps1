#Requires -Version 5.1
<#
.SYNOPSIS
    WinOptimizer v2.0 - Windows Performance & Stability Optimizer
.DESCRIPTION
    Automated Windows optimization. Compatible with Windows 10/11.
    Modules: Restore Point, Startup Cleaner, Mouse Fix, USB Power, Power Plan,
             SysMain, Temp Cleanup, DNS, Ethernet, Chrome/Firefox/Edge,
             RAM Cleanup, Bloatware Remover, Game Mode, SSD Health, HTML Report.
.PARAMETER Silent
    Run all modules without menu interaction.
.PARAMETER Module
    Run a specific module by name. Example: -Module "dns"
.PARAMETER NoReport
    Skip HTML report generation.
.EXAMPLE
    .\WinOptimizer.ps1
    .\WinOptimizer.ps1 -Silent
    .\WinOptimizer.ps1 -Module dns
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
$script:Version    = "2.0.0"
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
        bloatware = [PSCustomObject]@{ packages = @("Microsoft.BingNews","Microsoft.XboxApp","Microsoft.SkypeApp") }
        cleanup   = [PSCustomObject]@{ include_browser_cache = $false; include_event_logs = $false }
        report    = [PSCustomObject]@{ generate_html = $true; open_after_generate = $true }
    }
}

# ============================================================
#  LOGGING
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
#  SYSTEM SNAPSHOT (before/after comparison)
# ============================================================
function Get-SystemSnapshot {
    $os  = Get-CimInstance Win32_OperatingSystem
    $cpu = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
    return [PSCustomObject]@{
        Time        = Get-Date
        FreeRAM_GB  = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        TotalRAM_GB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
        FreeDisk_GB = [math]::Round((Get-PSDrive C).Free / 1GB, 2)
        CPU_Pct     = $cpu
        StartupCount = @(Get-CimInstance Win32_StartupCommand).Count
    }
}

# ============================================================
#  ADMIN CHECK
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

function Write-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "  ================================================================" -ForegroundColor Cyan
    Write-Host "   WinOptimizer v$($script:Version)  --  Windows Optimizer" -ForegroundColor White
    Write-Host "   Compatible: Windows 10 / 11 (x64) | PS 5.1+" -ForegroundColor DarkGray
    Write-Host "   Yunus Karatas (github.com/Barracuda1337)" -ForegroundColor DarkGray
    Write-Host "  ================================================================" -ForegroundColor Cyan
    Write-Host ""

    # OS & Hardware info
    $os  = (Get-CimInstance Win32_OperatingSystem)
    $cpu = (Get-CimInstance Win32_Processor | Select-Object -First 1).Name
    $ram = [math]::Round((Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1GB, 0)
    $gpu = (Get-CimInstance Win32_VideoController | Where-Object { $_.AdapterRAM -gt 100MB } | Select-Object -First 1).Name

    Write-Host "  OS : $($os.Caption) (Build $($os.BuildNumber))" -ForegroundColor Gray
    Write-Host "  CPU: $cpu" -ForegroundColor Gray
    Write-Host "  RAM: $ram GB" -ForegroundColor Gray
    if ($gpu) { Write-Host "  GPU: $gpu" -ForegroundColor Gray }
    Write-Host ""
}

# ============================================================
#  MODULE 1 -- RESTORE POINT
# ============================================================
function New-OptimizeRestorePoint {
    Write-Section "SISTEM GERI YUKLEME NOKTASI"
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction Stop
        Checkpoint-Computer -Description "WinOptimizer v$($script:Version) - $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Status "Geri yukleme noktasi olusturuldu" "OK"
        Add-Result "Restore" "Create restore point" $true
    } catch {
        Write-Status "Olusturulamadi (24 saat siniri veya Windows politikasi): $($_.Exception.Message)" "WARN"
        Add-Result "Restore" "Create restore point" $false $_.Exception.Message
    }
}

# ============================================================
#  MODULE 2 -- STARTUP CLEANER (dynamic, detects installed apps)
# ============================================================
function Disable-StartupPrograms {
    Write-Section "BASLANGIC PROGRAMLARI OPTIMIZASYONU"

    $toDisable  = $script:Config.startup.safe_to_disable
    $regPaths   = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
    )
    $approvedPath  = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
    $disabledBytes = [byte[]](3,0,0,0,0,0,0,0,0,0,0,0)

    $allStartup = @(Get-CimInstance Win32_StartupCommand)
    Write-Status "Toplam baslangic programi: $($allStartup.Count)" "INFO"

    $disabledCount = 0
    foreach ($appName in $toDisable) {
        $found = $false
        foreach ($regPath in $regPaths) {
            if (Get-ItemProperty -Path $regPath -Name $appName -ErrorAction SilentlyContinue) {
                Remove-ItemProperty -Path $regPath -Name $appName -ErrorAction SilentlyContinue
                $found = $true
            }
        }
        if (Get-ItemProperty -Path $approvedPath -Name $appName -ErrorAction SilentlyContinue) {
            Set-ItemProperty -Path $approvedPath -Name $appName -Value $disabledBytes -ErrorAction SilentlyContinue
            $found = $true
        }
        if ($found) {
            Write-Status "Devre disi: $appName" "OK"
            Add-Result "Startup" "Disable $appName" $true
            $disabledCount++
        }
    }

    if ($disabledCount -eq 0) {
        Write-Status "Hedef programlarin hicbiri baslangicta bulunamadi" "SKIP"
    } else {
        Write-Status "$disabledCount program devre disi birakildi" "OK"
        Add-Result "Startup" "Total disabled" $true "$disabledCount programs"
    }
}

# ============================================================
#  MODULE 3 -- MOUSE DRIVER REPAIR
# ============================================================
function Repair-MouseDrivers {
    Write-Section "FARE SURUCU ONARIMI"

    $unknownMice = @(Get-PnpDevice -Class Mouse | Where-Object { $_.Status -ne "OK" })
    $okMice      = @(Get-PnpDevice -Class Mouse | Where-Object { $_.Status -eq "OK" })

    Write-Status "Aktif fare sayisi: $($okMice.Count) | Sorunlu: $($unknownMice.Count)" "INFO"

    foreach ($mouse in $unknownMice) {
        Write-Status "Yeniden yukleniyor: $($mouse.FriendlyName)" "INFO"
        Disable-PnpDevice -InstanceId $mouse.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 800
        Enable-PnpDevice  -InstanceId $mouse.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
        Write-Status "Surucu yenilendi: $($mouse.FriendlyName)" "OK"
        Add-Result "Mouse" "Reinstall driver" $true $mouse.FriendlyName
    }

    foreach ($mouse in $okMice) {
        $regKey = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($mouse.InstanceId)\Device Parameters"
        if (Test-Path $regKey) {
            Set-ItemProperty -Path $regKey -Name "EnhancedPowerManagementEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
        }
    }

    Write-Status "HID guc yonetimi kapatildi (tum fareler)" "OK"
    Add-Result "Mouse" "Disable HID power management" $true "All mice"

    if ($unknownMice.Count -eq 0 -and $okMice.Count -gt 0) {
        Write-Status "Tum fare suruculeri saglıkli" "OK"
    }
}

# ============================================================
#  MODULE 4 -- USB SELECTIVE SUSPEND
# ============================================================
function Disable-UsbSelectiveSuspend {
    Write-Section "USB SELECTIVE SUSPEND"

    $planId = ([regex]'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}').Match((powercfg /getactivescheme)).Value
    if (-not $planId) { Write-Status "Aktif guc plani bulunamadi" "FAIL"; return }

    powercfg /setacvaluesetting $planId 2ab8d2cc-b1b4-4310-b5cd-6dbd1e18fa0c 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>$null
    powercfg /setdcvaluesetting $planId 2ab8d2cc-b1b4-4310-b5cd-6dbd1e18fa0c 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>$null
    powercfg /setactive $planId 2>$null

    Write-Status "USB Selective Suspend kapatildi" "OK"
    Add-Result "USB" "Disable USB Selective Suspend" $true $planId
}

# ============================================================
#  MODULE 5 -- POWER PLAN
# ============================================================
function Set-HighPerformancePlan {
    Write-Section "GUC PLANI OPTIMIZASYONU"

    powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
    $planName = (powercfg /getactivescheme) -replace '.*\((.+)\).*','$1'
    Write-Status "Guc plani: $planName" "OK"
    Add-Result "PowerPlan" "High Performance" $true $planName

    $mmPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
    Set-ItemProperty -Path $mmPath -Name "NetworkThrottlingIndex" -Value 0xffffffff -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $mmPath -Name "SystemResponsiveness"   -Value 0          -Type DWord -ErrorAction SilentlyContinue
    Write-Status "Network Throttling kaldirildi" "OK"
    Add-Result "PowerPlan" "Remove Network Throttling" $true

    $gamePath = "$mmPath\Tasks\Games"
    if (Test-Path $gamePath) {
        Set-ItemProperty -Path $gamePath -Name "GPU Priority"        -Value 8      -Type DWord  -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $gamePath -Name "Priority"            -Value 6      -Type DWord  -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $gamePath -Name "Scheduling Category" -Value "High" -Type String -ErrorAction SilentlyContinue
        Write-Status "Oyun CPU/GPU onceligi arttirildi" "OK"
        Add-Result "PowerPlan" "Game GPU Priority" $true
    }
}

# ============================================================
#  MODULE 6 -- GAME MODE + GPU SCHEDULING
# ============================================================
function Enable-GameMode {
    Write-Section "GAME MODE VE GPU HARDWARE SCHEDULING"

    # Windows Game Mode
    $gamePath = "HKCU:\Software\Microsoft\GameBar"
    if (-not (Test-Path $gamePath)) { New-Item -Path $gamePath -Force | Out-Null }
    Set-ItemProperty -Path $gamePath -Name "AllowAutoGameMode"  -Value 1 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $gamePath -Name "AutoGameModeEnabled"-Value 1 -Type DWord -ErrorAction SilentlyContinue
    Write-Status "Windows Game Mode etkinlestirildi" "OK"
    Add-Result "GameMode" "Enable Game Mode" $true

    # GPU Hardware Scheduling (Windows 10 2004+)
    $gpuPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
    $hwSched = Get-ItemProperty -Path $gpuPath -Name "HwSchMode" -ErrorAction SilentlyContinue
    if ($null -ne $hwSched) {
        Set-ItemProperty -Path $gpuPath -Name "HwSchMode" -Value 2 -Type DWord -ErrorAction SilentlyContinue
        Write-Status "GPU Hardware Scheduling etkinlestirildi (yeniden baslatma gerekli)" "OK"
        Add-Result "GameMode" "GPU Hardware Scheduling" $true
    } else {
        # Create key if not exists
        Set-ItemProperty -Path $gpuPath -Name "HwSchMode" -Value 2 -Type DWord -ErrorAction SilentlyContinue
        Write-Status "GPU Hardware Scheduling registry anahtari olusturuldu" "OK"
        Add-Result "GameMode" "GPU Hardware Scheduling" $true
    }

    # Variable Refresh Rate (if supported)
    Set-ItemProperty -Path $gpuPath -Name "VRROptimizeEnable" -Value 1 -Type DWord -ErrorAction SilentlyContinue
    Write-Status "VRR (Variable Refresh Rate) optimizasyonu etkinlestirildi" "OK"
    Add-Result "GameMode" "VRR Optimization" $true
}

# ============================================================
#  MODULE 7 -- SYSMAIN
# ============================================================
function Disable-SysMain {
    Write-Section "SYSMAIN / SUPERFETCH"

    $hasSSD = @(Get-PhysicalDisk | Where-Object { $_.MediaType -eq "SSD" })
    if ($hasSSD.Count -gt 0) {
        Stop-Service SysMain -Force         -ErrorAction SilentlyContinue
        Set-Service  SysMain -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Status "SysMain durduruldu ($($hasSSD.Count) SSD tespit edildi)" "OK"
        Add-Result "SysMain" "Disable SysMain" $true "$($hasSSD.Count) SSD found"
    } else {
        Write-Status "HDD sistemi -- SysMain aktif birakıliyor" "SKIP"
        Add-Result "SysMain" "Keep SysMain (HDD)" $true
    }
}

# ============================================================
#  MODULE 8 -- RAM CLEANUP (Empty Standby List)
# ============================================================
function Clear-RamStandby {
    Write-Section "RAM TEMIZLIGI (STANDBY LIST)"

    $os = Get-CimInstance Win32_OperatingSystem
    $beforeFree = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    Write-Status "Onceki bos RAM: $beforeFree GB" "INFO"

    # EmptyStandbyList.exe mevcutsa kullan
    $emptySL = Join-Path $script:ScriptDir "tools\EmptyStandbyList.exe"
    if (Test-Path $emptySL) {
        & $emptySL workingsets 2>$null  | Out-Null
        & $emptySL modifiedpagelist 2>$null | Out-Null
        & $emptySL standbylist 2>$null  | Out-Null
    }

    # PowerShell yontemi: GC zorla
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    [System.GC]::Collect()

    # SetProcessWorkingSetSize ile her prosesin working set'ini kirc
    $ClearRamCode = @"
using System;
using System.Runtime.InteropServices;
using System.Diagnostics;

public class RamCleaner {
    [DllImport("kernel32.dll")]
    public static extern bool SetProcessWorkingSetSize(IntPtr proc, int min, int max);

    public static void EmptyWorkingSets() {
        foreach (Process p in Process.GetProcesses()) {
            try { SetProcessWorkingSetSize(p.Handle, -1, -1); } catch {}
        }
    }
}
"@
    try {
        if (-not ([System.Management.Automation.PSTypeName]'RamCleaner').Type) {
            Add-Type -TypeDefinition $ClearRamCode -ErrorAction SilentlyContinue
        }
        [RamCleaner]::EmptyWorkingSets()
    } catch {}

    Start-Sleep 1
    $os2 = Get-CimInstance Win32_OperatingSystem
    $afterFree = [math]::Round($os2.FreePhysicalMemory / 1MB, 2)
    $freed = [math]::Round($afterFree - $beforeFree, 2)

    Write-Status "Sonraki bos RAM: $afterFree GB (Kazanc: +$freed GB)" "OK"
    Add-Result "RAM" "Clear Standby List" $true "Freed: +$freed GB | Free: $afterFree GB"
}

# ============================================================
#  MODULE 9 -- TEMP FILE CLEANUP
# ============================================================
function Clear-TempFiles {
    Write-Section "GECICI DOSYA TEMIZLIGI"

    $totalFreed = 0

    $cleanPaths = @(
        [PSCustomObject]@{ Path = $env:TEMP;          Label = "Kullanici Temp" },
        [PSCustomObject]@{ Path = "C:\Windows\Temp"; Label = "Windows Temp" }
    )
    foreach ($p in $cleanPaths) {
        if (-not (Test-Path $p.Path)) { continue }
        $before = (Get-ChildItem $p.Path -Recurse -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
        Get-ChildItem $p.Path -Recurse -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        $freed = [math]::Round($before / 1MB, 0)
        $totalFreed += $freed
        Write-Status "$($p.Label): $freed MB temizlendi" "OK"
        Add-Result "Cleanup" $p.Label $true "$freed MB"
    }

    # WU cache
    Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
    $wuPath = "C:\Windows\SoftwareDistribution\Download"
    if (Test-Path $wuPath) {
        $wuSize = [math]::Round((Get-ChildItem $wuPath -Recurse -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB, 0)
        Remove-Item "$wuPath\*" -Recurse -Force -ErrorAction SilentlyContinue
        $totalFreed += $wuSize
        Write-Status "Windows Update cache: $wuSize MB" "OK"
        Add-Result "Cleanup" "WU Cache" $true "$wuSize MB"
    }
    Start-Service wuauserv -ErrorAction SilentlyContinue

    # Delivery Optimization
    Delete-DeliveryOptimizationCache -Force -ErrorAction SilentlyContinue
    Write-Status "Delivery Optimization cache temizlendi" "OK"

    # Prefetch (sadece HDD sistemlerde, SSD'de gereksiz)
    $ssdCount = @(Get-PhysicalDisk | Where-Object { $_.MediaType -eq "SSD" }).Count
    if ($ssdCount -eq 0) {
        Get-ChildItem "C:\Windows\Prefetch" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
        Write-Status "Prefetch temizlendi (HDD)" "OK"
        Add-Result "Cleanup" "Prefetch (HDD)" $true
    }

    $freeGB = [math]::Round((Get-PSDrive C).Free / 1GB, 1)
    Write-Status "Toplam temizlenen: ~$totalFreed MB | C: bos: $freeGB GB" "OK"
    Add-Result "Cleanup" "TOTAL" $true "~$totalFreed MB | $freeGB GB free"
}

# ============================================================
#  MODULE 10 -- DNS OPTIMIZATION
# ============================================================
function Set-OptimalDns {
    Write-Section "DNS OPTIMIZASYONU"

    $primary   = $script:Config.dns.primary
    $secondary = $script:Config.dns.secondary

    $adapters = @(Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.Virtual -eq $false })
    foreach ($adapter in $adapters) {
        $current = (Get-DnsClientServerAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4).ServerAddresses
        Write-Status "$($adapter.Name): $($current -join ' | ') --> $primary | $secondary" "INFO"
        Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses @($primary, $secondary) -ErrorAction SilentlyContinue
        Write-Status "$($adapter.Name) DNS guncellendi" "OK"
        Add-Result "DNS" $adapter.Name $true "$primary, $secondary"
    }
    ipconfig /flushdns | Out-Null
    Write-Status "DNS onbellegi temizlendi" "OK"
    Add-Result "DNS" "Flush DNS" $true
}

# ============================================================
#  MODULE 11 -- ETHERNET GIGABIT
# ============================================================
function Set-EthernetGigabit {
    Write-Section "ETHERNET HIZ OPTIMIZASYONU"

    $eths = @(Get-NetAdapter | Where-Object { $_.MediaType -eq "802.3" -and $_.Status -eq "Up" -and $_.Virtual -eq $false })
    if ($eths.Count -eq 0) { Write-Status "Aktif Ethernet bulunamadi" "SKIP"; return }

    foreach ($eth in $eths) {
        Write-Status "$($eth.Name): $($eth.LinkSpeed)" "INFO"
        Set-NetAdapterAdvancedProperty -Name $eth.Name -RegistryKeyword "GigaLite"     -RegistryValue 0 -ErrorAction SilentlyContinue
        Set-NetAdapterAdvancedProperty -Name $eth.Name -RegistryKeyword "*SpeedDuplex" -RegistryValue 6 -ErrorAction SilentlyContinue
        Start-Sleep 2
        $newSpeed = (Get-NetAdapter -Name $eth.Name).LinkSpeed
        Write-Status "$($eth.Name) --> $newSpeed" "OK"
        Add-Result "Ethernet" $eth.Name $true "Was: $($eth.LinkSpeed) | Now: $newSpeed"
        if ($newSpeed -like "*100*") {
            Write-Status "UYARI: Kablo (Cat6) veya router portu kontrol edin" "WARN"
        }
    }
}

# ============================================================
#  MODULE 12 -- BROWSER OPTIMIZER (Chrome + Firefox + Edge)
# ============================================================
function Optimize-Browsers {
    Write-Section "TARAYICI OPTIMIZASYONU"

    # ---- CHROME ----
    $chromePath = "$env:LOCALAPPDATA\Google\Chrome\User Data"
    if (Test-Path $chromePath) {
        $policyPath = "HKLM:\SOFTWARE\Policies\Google\Chrome"
        if (-not (Test-Path $policyPath)) { New-Item -Path $policyPath -Force -ErrorAction SilentlyContinue | Out-Null }
        Set-ItemProperty -Path $policyPath -Name "HardwareAccelerationModeEnabled" -Value 1 -Type DWord -ErrorAction SilentlyContinue

        $caches = @("Default\GPUCache","ShaderCache","Default\Code Cache","Default\Cache\Cache_Data")
        $totalChromeMB = 0
        foreach ($cache in $caches) {
            $full = Join-Path $chromePath $cache
            if (Test-Path $full) {
                $sz = [math]::Round((Get-ChildItem $full -Recurse -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB, 0)
                Remove-Item "$full\*" -Recurse -Force -ErrorAction SilentlyContinue
                $totalChromeMB += $sz
            }
        }
        Write-Status "Chrome: $totalChromeMB MB cache temizlendi + GPU hizlandirma aktif" "OK"
        Add-Result "Browser" "Chrome" $true "$totalChromeMB MB freed"
    } else {
        Write-Status "Chrome: kurulu degil" "SKIP"
    }

    # ---- FIREFOX ----
    $ffPath = "$env:APPDATA\Mozilla\Firefox\Profiles"
    if (Test-Path $ffPath) {
        $ffProfiles = Get-ChildItem $ffPath -Directory -ErrorAction SilentlyContinue
        $totalFFMB  = 0
        foreach ($prof in $ffProfiles) {
            $cachePaths = @(
                (Join-Path $prof.FullName "cache2"),
                (Join-Path $prof.FullName "startupCache"),
                (Join-Path $prof.FullName "shader-cache")
            )
            foreach ($cp in $cachePaths) {
                if (Test-Path $cp) {
                    $sz = [math]::Round((Get-ChildItem $cp -Recurse -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB, 0)
                    Remove-Item "$cp\*" -Recurse -Force -ErrorAction SilentlyContinue
                    $totalFFMB += $sz
                }
            }
        }
        Write-Status "Firefox: $totalFFMB MB cache temizlendi ($($ffProfiles.Count) profil)" "OK"
        Add-Result "Browser" "Firefox" $true "$totalFFMB MB freed"
    } else {
        Write-Status "Firefox: kurulu degil" "SKIP"
    }

    # ---- EDGE ----
    $edgePath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data"
    if (Test-Path $edgePath) {
        $edgeCaches = @("Default\Cache\Cache_Data","Default\GPUCache","Default\Code Cache","ShaderCache")
        $totalEdgeMB = 0
        foreach ($cache in $edgeCaches) {
            $full = Join-Path $edgePath $cache
            if (Test-Path $full) {
                $sz = [math]::Round((Get-ChildItem $full -Recurse -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB, 0)
                Remove-Item "$full\*" -Recurse -Force -ErrorAction SilentlyContinue
                $totalEdgeMB += $sz
            }
        }
        Write-Status "Edge: $totalEdgeMB MB cache temizlendi" "OK"
        Add-Result "Browser" "Edge" $true "$totalEdgeMB MB freed"
    } else {
        Write-Status "Edge: kurulu degil" "SKIP"
    }
}

# ============================================================
#  MODULE 13 -- SSD HEALTH CHECK (SMART)
# ============================================================
function Get-SsdHealth {
    Write-Section "DISK SAGLIK KONTROLU (SMART)"

    $disks = Get-PhysicalDisk
    foreach ($disk in $disks) {
        $mediaType = $disk.MediaType
        $health    = $disk.HealthStatus
        $oper      = $disk.OperationalStatus
        $sizeGB    = [math]::Round($disk.Size / 1GB, 0)

        $statusLevel = switch ($health) {
            "Healthy"  { "OK"   }
            "Warning"  { "WARN" }
            "Unhealthy"{ "FAIL" }
            default    { "INFO" }
        }

        Write-Status "$($disk.FriendlyName) | $mediaType | $sizeGB GB | $health | $oper" $statusLevel
        Add-Result "Disk" $disk.FriendlyName ($health -eq "Healthy") "$mediaType | $sizeGB GB | $health"
    }

    # C: disk doluluk uyarisi
    $freeGB = [math]::Round((Get-PSDrive C).Free / 1GB, 1)
    $usedGB = [math]::Round((Get-PSDrive C).Used / 1GB, 1)
    $totalGB = $freeGB + $usedGB
    $pct = [math]::Round(($usedGB / $totalGB) * 100, 0)

    if ($pct -ge 90) {
        Write-Status "KRITIK: C: surucusu %$pct dolu! Disk temizligi yapiniz." "FAIL"
        Add-Result "Disk" "C: Space Warning" $false "%$pct full ($freeGB GB free)"
    } elseif ($pct -ge 75) {
        Write-Status "UYARI: C: surucusu %$pct dolu ($freeGB GB bos)" "WARN"
        Add-Result "Disk" "C: Space" $true "%$pct full ($freeGB GB free)"
    } else {
        Write-Status "C: disk durumu iyi: %$pct dolu, $freeGB GB bos" "OK"
        Add-Result "Disk" "C: Space" $true "$freeGB GB free (%$pct used)"
    }
}

# ============================================================
#  MODULE 14 -- WIFI OPTIMIZATION
# ============================================================
function Optimize-WiFi {
    Write-Section "WI-FI OPTIMIZASYONU"

    $wifiAdapters = @(Get-NetAdapter | Where-Object { $_.MediaType -eq "Native 802.11" -and $_.Status -eq "Up" })
    if ($wifiAdapters.Count -eq 0) {
        $wifiAdapters = @(Get-NetAdapter | Where-Object { $_.Name -like "*Wi*" -or $_.Name -like "*WiFi*" -or $_.Name -like "*Wireless*" })
    }

    if ($wifiAdapters.Count -eq 0) {
        Write-Status "Aktif Wi-Fi adaptoru bulunamadi" "SKIP"
        Add-Result "WiFi" "Check adapters" $true "No active Wi-Fi"
        return
    }

    foreach ($wifi in $wifiAdapters) {
        Write-Status "$($wifi.Name): $($wifi.LinkSpeed)" "INFO"

        # Agressive roaming azalt (baglanti kopyasini azaltir)
        Set-NetAdapterAdvancedProperty -Name $wifi.Name -DisplayName "Roaming Aggressiveness" -DisplayValue "1. Lowest" -ErrorAction SilentlyContinue
        Set-NetAdapterAdvancedProperty -Name $wifi.Name -RegistryKeyword "RoamAggressiveness" -RegistryValue 1 -ErrorAction SilentlyContinue

        # 802.11n/ac kanalı genisligi optimizasyonu
        Set-NetAdapterAdvancedProperty -Name $wifi.Name -RegistryKeyword "ChannelWidth24" -RegistryValue 20  -ErrorAction SilentlyContinue
        Set-NetAdapterAdvancedProperty -Name $wifi.Name -RegistryKeyword "ChannelWidth52" -RegistryValue 0   -ErrorAction SilentlyContinue

        # Wi-Fi guc tasarrufu kapat
        Set-NetAdapterAdvancedProperty -Name $wifi.Name -RegistryKeyword "PowerSavingMode" -RegistryValue 0 -ErrorAction SilentlyContinue
        Set-NetAdapterAdvancedProperty -Name $wifi.Name -DisplayName "WZC IBSS Channel Number" -DisplayValue "11" -ErrorAction SilentlyContinue

        Write-Status "$($wifi.Name): Roaming optimize edildi, guc tasarrufu kapatildi" "OK"
        Add-Result "WiFi" $wifi.Name $true "Roaming low, power save off"
    }
}

# ============================================================
#  MODULE 15 -- BLOATWARE REMOVER (optional, interactive)
# ============================================================
function Remove-Bloatware {
    param([switch]$Force)

    Write-Section "BLOATWARE KALDIR"

    $packages = $script:Config.bloatware.packages
    $installed = @(Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Where-Object { $_.Name -in $packages })

    if ($installed.Count -eq 0) {
        Write-Status "Hedef bloatware bulunamadi (zaten temiz!)" "SKIP"
        Add-Result "Bloatware" "Scan" $true "None found"
        return
    }

    Write-Status "Kaldirilabilir $($installed.Count) uygulama bulundu:" "INFO"
    $installed | ForEach-Object { Write-Host "    - $($_.Name)" -ForegroundColor DarkGray }

    if (-not $Force -and -not $Silent) {
        Write-Host ""
        Write-Host "  Bunlari kaldirmak ister misiniz? (E/H): " -NoNewline -ForegroundColor White
        $confirm = (Read-Host).Trim()
        if ($confirm -notmatch "^[EeYy]") {
            Write-Status "Bloatware kaldirma atlandi (kullanici vazgecti)" "SKIP"
            Add-Result "Bloatware" "Remove" $true "Skipped by user"
            return
        }
    }

    $removed = 0
    foreach ($app in $installed) {
        try {
            Remove-AppxPackage -Package $app.PackageFullName -ErrorAction Stop
            Remove-AppxProvisionedPackage -Online -PackageName $app.PackageFullName -ErrorAction SilentlyContinue | Out-Null
            Write-Status "Kaldirildi: $($app.Name)" "OK"
            $removed++
        } catch {
            Write-Status "Kaldirilamadi: $($app.Name) ($($_.Exception.Message))" "WARN"
        }
    }
    Add-Result "Bloatware" "Remove" $true "$removed / $($installed.Count) removed"
}

# ============================================================
#  MODULE 16 -- VISUAL FX (Performans icin gorsel efektleri kapat)
# ============================================================
function Optimize-VisualEffects {
    Write-Section "GORSEL EFEKT OPTIMIZASYONU"

    # Performance mode (en dusuk gorsel) = 2
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
    Set-ItemProperty -Path $regPath -Name "VisualFXSetting" -Value 3 -Type DWord -ErrorAction SilentlyContinue

    # Arayuz animasyonlarini kapat (kayan pencere vs.)
    $advPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-ItemProperty -Path $advPath -Name "TaskbarAnimations"  -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $advPath -Name "ListviewAlphaSelect" -Value 0 -Type DWord -ErrorAction SilentlyContinue

    # Transparency efektini kapat
    $personPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    Set-ItemProperty -Path $personPath -Name "EnableTransparency" -Value 0 -Type DWord -ErrorAction SilentlyContinue

    Write-Status "Gorsel efektler performans moduna alindi" "OK"
    Add-Result "VisualFX" "Optimize effects" $true "Performance mode"
}

# ============================================================
#  MODULE 17 -- SCHEDULED TASK (Haftalik otomatik bakim)
# ============================================================
function Register-WeeklyTask {
    param([switch]$Remove)

    Write-Section "HAFTALIK OTOMATIK BAKIM GOREVI"

    $taskName = "WinOptimizer_WeeklyMaintenance"

    if ($Remove) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
        Write-Status "Zamanlanmis gorev kaldirildi" "OK"
        Add-Result "ScheduledTask" "Remove" $true
        return
    }

    $existing = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Status "Gorev zaten mevcut: '$taskName'" "SKIP"
        Add-Result "ScheduledTask" "Already exists" $true
        return
    }

    $scriptPath = $MyInvocation.ScriptName
    if (-not $scriptPath) { $scriptPath = Join-Path $script:ScriptDir "WinOptimizer.ps1" }

    $action  = New-ScheduledTaskAction -Execute "powershell.exe" `
                   -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`" -Silent -NoReport"
    $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "03:00AM"
    $settings = New-ScheduledTaskSettingsSet -RunOnlyIfNetworkAvailable:$false -StartWhenAvailable

    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings `
        -RunLevel Highest -Description "WinOptimizer haftalik otomatik bakim" -ErrorAction SilentlyContinue | Out-Null

    Write-Status "Haftalik gorev olusturuldu: Her Pazar 03:00'da calisacak" "OK"
    Add-Result "ScheduledTask" "Register weekly task" $true "Every Sunday 03:00"
}

# ============================================================
#  HTML REPORT GENERATOR
# ============================================================
function Export-HtmlReport {
    param([PSCustomObject]$Before, [PSCustomObject]$After)

    $duration = [math]::Round(((Get-Date) - $script:StartTime).TotalSeconds, 1)
    $okCount   = @($script:Results | Where-Object { $_.Status -eq "OK" }).Count
    $failCount = @($script:Results | Where-Object { $_.Status -eq "FAILED" }).Count
    $skipCount = @($script:Results | Where-Object { $_.Status -eq "SKIP" }).Count

    $ramGain  = if ($Before -and $After) { [math]::Round($After.FreeRAM_GB - $Before.FreeRAM_GB, 2) } else { 0 }
    $diskGain = if ($Before -and $After) { [math]::Round($After.FreeDisk_GB - $Before.FreeDisk_GB, 2) } else { 0 }

    $rowsHtml = ($script:Results | ForEach-Object {
        $badgeClass = switch ($_.Status) { "OK" { "ok" } "FAILED" { "fail" } default { "skip" } }
        "<tr><td>$($_.Time)</td><td>$($_.Category)</td><td>$($_.Action)</td><td><span class='badge $badgeClass'>$($_.Status)</span></td><td>$($_.Detail)</td></tr>"
    }) -join "`n"

    $osInfo  = (Get-CimInstance Win32_OperatingSystem).Caption
    $cpuInfo = (Get-CimInstance Win32_Processor | Select-Object -First 1).Name

    $html = @"
<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>WinOptimizer Report - $(Get-Date -Format 'yyyy-MM-dd HH:mm')</title>
<style>
  :root {
    --bg: #0d1117; --surface: #161b22; --border: #30363d;
    --text: #e6edf3; --dim: #8b949e; --green: #3fb950;
    --red: #f85149; --yellow: #d29922; --blue: #58a6ff;
    --accent: #1f6feb;
  }
  * { margin:0; padding:0; box-sizing:border-box; }
  body { background:var(--bg); color:var(--text); font-family: 'Segoe UI', system-ui, sans-serif; font-size:14px; }
  .header { background: linear-gradient(135deg, #1f6feb22, #388bfd11); border-bottom:1px solid var(--border); padding: 32px 40px; }
  .header h1 { font-size:28px; font-weight:700; color:var(--blue); }
  .header p { color:var(--dim); margin-top:4px; }
  .container { max-width:1200px; margin:0 auto; padding:32px 40px; }
  .stats { display:grid; grid-template-columns:repeat(auto-fit,minmax(160px,1fr)); gap:16px; margin-bottom:32px; }
  .stat { background:var(--surface); border:1px solid var(--border); border-radius:8px; padding:20px; text-align:center; }
  .stat .val { font-size:32px; font-weight:700; margin-bottom:4px; }
  .stat .lbl { color:var(--dim); font-size:12px; text-transform:uppercase; letter-spacing:.5px; }
  .val.green { color:var(--green); } .val.red { color:var(--red); } .val.blue { color:var(--blue); } .val.yellow { color:var(--yellow); }
  .card { background:var(--surface); border:1px solid var(--border); border-radius:8px; margin-bottom:24px; overflow:hidden; }
  .card-header { padding:16px 20px; border-bottom:1px solid var(--border); font-weight:600; color:var(--blue); font-size:13px; text-transform:uppercase; letter-spacing:.5px; }
  table { width:100%; border-collapse:collapse; }
  th,td { padding:10px 16px; text-align:left; border-bottom:1px solid var(--border); font-size:13px; }
  th { color:var(--dim); font-weight:500; background:var(--bg); }
  tr:last-child td { border-bottom:none; }
  tr:hover td { background: rgba(255,255,255,.02); }
  .badge { padding:2px 10px; border-radius:12px; font-size:11px; font-weight:600; }
  .badge.ok { background:#3fb95022; color:var(--green); }
  .badge.fail { background:#f8514922; color:var(--red); }
  .badge.skip { background:#8b949e22; color:var(--dim); }
  .sys-info { display:grid; grid-template-columns:1fr 1fr; gap:16px; }
  .info-row { display:flex; justify-content:space-between; padding:8px 0; border-bottom:1px solid var(--border); }
  .info-row:last-child { border:none; }
  .info-val { color:var(--text); font-weight:500; }
  .info-key { color:var(--dim); }
  .footer { text-align:center; color:var(--dim); font-size:12px; padding:32px; border-top:1px solid var(--border); margin-top:16px; }
</style>
</head>
<body>
<div class="header">
  <h1>WinOptimizer v$($script:Version)</h1>
  <p>$(Get-Date -Format 'dddd, dd MMMM yyyy HH:mm') -- Calisma suresi: ${duration}s</p>
</div>
<div class="container">

  <div class="stats">
    <div class="stat"><div class="val green">$okCount</div><div class="lbl">Basarili</div></div>
    <div class="stat"><div class="val red">$failCount</div><div class="lbl">Basarisiz</div></div>
    <div class="stat"><div class="val blue">$skipCount</div><div class="lbl">Atlanan</div></div>
    <div class="stat"><div class="val green">$(if($diskGain -gt 0){"+$diskGain GB"}else{"0 GB"})</div><div class="lbl">Disk Kazanc</div></div>
    <div class="stat"><div class="val blue">$(if($ramGain -gt 0){"+$ramGain GB"}else{"0 GB"})</div><div class="lbl">RAM Kazanc</div></div>
    <div class="stat"><div class="val yellow">${duration}s</div><div class="lbl">Sure</div></div>
  </div>

  <div class="sys-info">
    <div class="card">
      <div class="card-header">Sistem Bilgisi</div>
      <div style="padding:16px 20px;">
        <div class="info-row"><span class="info-key">OS</span><span class="info-val">$osInfo</span></div>
        <div class="info-row"><span class="info-key">CPU</span><span class="info-val">$cpuInfo</span></div>
        <div class="info-row"><span class="info-key">Log</span><span class="info-val">$($script:LogPath)</span></div>
      </div>
    </div>
    <div class="card">
      <div class="card-header">Once / Sonra</div>
      <div style="padding:16px 20px;">
        <div class="info-row"><span class="info-key">Bos RAM (Once)</span><span class="info-val">$(if($Before){$Before.FreeRAM_GB}else{'N/A'}) GB</span></div>
        <div class="info-row"><span class="info-key">Bos RAM (Sonra)</span><span class="info-val">$(if($After){$After.FreeRAM_GB}else{'N/A'}) GB</span></div>
        <div class="info-row"><span class="info-key">Bos Disk (Once)</span><span class="info-val">$(if($Before){$Before.FreeDisk_GB}else{'N/A'}) GB</span></div>
        <div class="info-row"><span class="info-key">Bos Disk (Sonra)</span><span class="info-val">$(if($After){$After.FreeDisk_GB}else{'N/A'}) GB</span></div>
      </div>
    </div>
  </div>

  <div class="card" style="margin-top:24px;">
    <div class="card-header">Islem Detaylari ($($script:Results.Count) islem)</div>
    <table>
      <thead><tr><th>Saat</th><th>Kategori</th><th>Islem</th><th>Durum</th><th>Detay</th></tr></thead>
      <tbody>$rowsHtml</tbody>
    </table>
  </div>

</div>
<div class="footer">WinOptimizer v$($script:Version) -- github.com/Barracuda1337/WinOptimizer -- MIT License</div>
</body>
</html>
"@

    $html | Out-File -FilePath $script:ReportPath -Encoding UTF8 -Force
    Write-Status "HTML rapor olusturuldu: $($script:ReportPath)" "OK"

    if ($script:Config.report.open_after_generate -and -not $NoReport) {
        Start-Process $script:ReportPath
    }
}

# ============================================================
#  SUMMARY (terminal)
# ============================================================
function Show-Summary {
    param([PSCustomObject]$Before, [PSCustomObject]$After)

    $duration = [math]::Round(((Get-Date) - $script:StartTime).TotalSeconds, 1)
    $ok    = @($script:Results | Where-Object { $_.Status -eq "OK" }).Count
    $fail  = @($script:Results | Where-Object { $_.Status -eq "FAILED" }).Count
    $total = $script:Results.Count

    Write-Host ""
    Write-Host "  =============================================================" -ForegroundColor Cyan
    Write-Host "   WinOptimizer v$($script:Version)  --  By Yunus Karatas" -ForegroundColor White
    Write-Host "   github.com/Barracuda1337/WinOptimizer" -ForegroundColor DarkGray
    Write-Host "  =============================================================" -ForegroundColor Cyan

    if ($Before -and $After) {
        $ramGain  = [math]::Round($After.FreeRAM_GB - $Before.FreeRAM_GB, 2)
        $diskGain = [math]::Round($After.FreeDisk_GB - $Before.FreeDisk_GB, 2)
        Write-Host ""
        Write-Host "  ONCE  --> SONRA" -ForegroundColor DarkGray
        Write-Host "  RAM bos  : $($Before.FreeRAM_GB) GB --> $($After.FreeRAM_GB) GB (kazanc: +$ramGain GB)" -ForegroundColor $(if($ramGain -gt 0){"Green"}else{"Gray"})
        Write-Host "  Disk bos : $($Before.FreeDisk_GB) GB --> $($After.FreeDisk_GB) GB (kazanc: +$diskGain GB)" -ForegroundColor $(if($diskGain -gt 0){"Green"}else{"Gray"})
    }

    Write-Host ""
    $script:Results | Format-Table -Property Category, Action, Status, Detail -AutoSize | Out-String |
        ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }

    Write-Host "  Basarili: $ok / $total | Sure: ${duration}s" -ForegroundColor Green
    if ($fail -gt 0) { Write-Host "  Basarisiz: $fail" -ForegroundColor Red }
    Write-Host "  Log: $($script:LogPath)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  *** BILGISAYARINIZI YENIDEN BASLATMANIZ ONERILIR ***" -ForegroundColor Yellow
    Write-Host ""
}

# ============================================================
#  RUN ALL MODULES
# ============================================================
function Invoke-AllModules {
    $script:BeforeSnap = Get-SystemSnapshot
    New-OptimizeRestorePoint
    Disable-StartupPrograms
    Repair-MouseDrivers
    Disable-UsbSelectiveSuspend
    Set-HighPerformancePlan
    Enable-GameMode
    Disable-SysMain
    Clear-RamStandby
    Clear-TempFiles
    Set-OptimalDns
    Set-EthernetGigabit
    Optimize-Browsers
    Optimize-WiFi
    Optimize-VisualEffects
    Get-SsdHealth
    $script:AfterSnap = Get-SystemSnapshot
}

# ============================================================
#  INTERACTIVE MENU
# ============================================================
function Show-Menu {
    Write-Host "  Bir modul sec (Enter veya A = Hepsini Uygula):" -ForegroundColor White
    Write-Host ""
    Write-Host "  [1 ] Geri Yukleme Noktasi Olustur"              -ForegroundColor Gray
    Write-Host "  [2 ] Baslangic Programlari Temizle"              -ForegroundColor Gray
    Write-Host "  [3 ] Fare Surucu Onar"                           -ForegroundColor Gray
    Write-Host "  [4 ] USB Selective Suspend Kapat"                -ForegroundColor Gray
    Write-Host "  [5 ] Guc Plani -> Yuksek Performans"             -ForegroundColor Gray
    Write-Host "  [6 ] Game Mode + GPU Hardware Scheduling"        -ForegroundColor Gray
    Write-Host "  [7 ] SysMain / Superfetch Kapat"                 -ForegroundColor Gray
    Write-Host "  [8 ] RAM Standby Temizle"                        -ForegroundColor Gray
    Write-Host "  [9 ] Gecici Dosyalari Temizle"                   -ForegroundColor Gray
    Write-Host "  [10] DNS Optimizasyonu (Cloudflare 1.1.1.1)"     -ForegroundColor Gray
    Write-Host "  [11] Ethernet Gigabit Duzelt"                    -ForegroundColor Gray
    Write-Host "  [12] Chrome + Firefox + Edge Cache Temizle"      -ForegroundColor Gray
    Write-Host "  [13] Wi-Fi Optimizasyonu"                        -ForegroundColor Gray
    Write-Host "  [14] Bloatware Kaldir (Xbox, Teams, Bing vb.)"   -ForegroundColor Gray
    Write-Host "  [15] Gorsel Efektleri Optimize Et"               -ForegroundColor Gray
    Write-Host "  [16] Disk Saglik Kontrol (SMART)"                -ForegroundColor Gray
    Write-Host "  [17] Haftalik Otomatik Bakim Gorevi Ekle"        -ForegroundColor Gray
    Write-Host "  [18] Haftalik Gorevi Kaldir"                     -ForegroundColor DarkGray
    Write-Host "  [R ] HTML Rapor Olustur"                         -ForegroundColor Cyan
    Write-Host "  [A ] Hepsini Uygula (Onerilir)"                  -ForegroundColor Cyan
    Write-Host "  [Q ] Cikis"                                      -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Seciminiz: " -ForegroundColor White -NoNewline
}

# ============================================================
#  SINGLE MODULE DISPATCHER
# ============================================================
function Invoke-SingleModule([string]$Key) {
    switch ($Key) {
        "1"  { New-OptimizeRestorePoint }
        "2"  { Disable-StartupPrograms }
        "3"  { Repair-MouseDrivers }
        "4"  { Disable-UsbSelectiveSuspend }
        "5"  { Set-HighPerformancePlan }
        "6"  { Enable-GameMode }
        "7"  { Disable-SysMain }
        "8"  { Clear-RamStandby }
        "9"  { Clear-TempFiles }
        "10" { Set-OptimalDns }
        "11" { Set-EthernetGigabit }
        "12" { Optimize-Browsers }
        "13" { Optimize-WiFi }
        "14" { Remove-Bloatware }
        "15" { Optimize-VisualEffects }
        "16" { Get-SsdHealth }
        "17" { Register-WeeklyTask }
        "18" { Register-WeeklyTask -Remove }
        "R"  { Export-HtmlReport -Before $script:BeforeSnap -After $script:AfterSnap }
        default { Write-Host "  Gecersiz secim." -ForegroundColor Red }
    }
}

# ============================================================
#  ENTRY POINT
# ============================================================
Assert-Admin

# -Module parametresi ile tek modul calistir
if ($Module -ne "") {
    Write-Banner
    Invoke-SingleModule $Module.ToUpper()
    Show-Summary -Before $null -After $null
    exit 0
}

Write-Banner

if ($Silent) {
    Write-Host "  [Silent Mode] Tum optimizasyonlar uygulanıyor..." -ForegroundColor Yellow
    Invoke-AllModules
    Show-Summary -Before $script:BeforeSnap -After $script:AfterSnap
    if (-not $NoReport -and $script:Config.report.generate_html) {
        Export-HtmlReport -Before $script:BeforeSnap -After $script:AfterSnap
    }
    exit 0
}

# Interactive loop
$running = $true
while ($running) {
    Show-Menu
    $choice = (Read-Host).Trim().ToUpper()

    switch ($choice) {
        { $_ -eq "" -or $_ -eq "A" } {
            Invoke-AllModules
            Show-Summary -Before $script:BeforeSnap -After $script:AfterSnap
            if (-not $NoReport -and $script:Config.report.generate_html) {
                Export-HtmlReport -Before $script:BeforeSnap -After $script:AfterSnap
            }
        }
        "Q" {
            Write-Host ""
            Write-Host "  Iyi gunler!" -ForegroundColor Cyan
            Write-Host ""
            $running = $false
            continue
        }
        default {
            Invoke-SingleModule $choice
            Show-Summary -Before $script:BeforeSnap -After $script:AfterSnap
        }
    }

    if ($running -and $choice -ne "Q") {
        Write-Host "  Baska islem yapmak ister misiniz? (E / H): " -NoNewline -ForegroundColor White
        $again = (Read-Host).Trim()
        if ($again -notmatch "^[EeYy]") {
            $running = $false
        } else {
            Write-Banner
        }
    }
}

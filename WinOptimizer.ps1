#Requires -Version 5.1
<#
.SYNOPSIS
    WinOptimizer v2.2 - Advanced Windows CLI Toolbox
.DESCRIPTION
    System optimization, software installation via Winget, and deep cleaning.
.AUTHOR
    Barracuda1337 (github.com/Barracuda1337)
.VERSION
    2.2.0
#>
param([switch]$Silent)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# ============================================================
#  GLOBALS
# ============================================================
$script:Version    = "2.2.0"
$script:ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:ConfigPath = Join-Path $script:ScriptDir "config.json"
$script:Results    = @()

# Load config
if (Test-Path $script:ConfigPath) {
    $script:Config = Get-Content $script:ConfigPath -Raw | ConvertFrom-Json
}

# ============================================================
#  UI HELPERS
# ============================================================
function Write-Status([string]$Msg, [string]$Level = "INFO") {
    $color = switch ($Level) { "OK" { "Green" } "FAIL" { "Red" } "WARN" { "Yellow" } default { "Cyan" } }
    Write-Host "  [$Level] $Msg" -ForegroundColor $color
}

function Write-Banner {
    Clear-Host
    Write-Host "  ================================================================" -ForegroundColor Cyan
    Write-Host "   WinOptimizer v$($script:Version)  --  By Barracuda1337" -ForegroundColor White
    Write-Host "  ================================================================" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================================
#  MODULES
# ============================================================

# Software Installer (Winget based)
function Show-SoftwareMenu {
    Write-Banner
    Write-Host "  --- YAZILIM YUKLEME MENUSU (WINGET) ---" -ForegroundColor Yellow
    Write-Host "  Yuklemek istediginiz programlarin numaralarini virgulle ayirarak yazin (or: 1,3,5)" -ForegroundColor Gray
    Write-Host ""
    
    $list = $script:Config.install_list
    for ($i=0; $i -lt $list.Count; $i++) {
        Write-Host "  [$($i+1)] $($list[$i].name)" -ForegroundColor White
    }
    Write-Host "  [Q] Menuye Don" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Seciminiz: " -NoNewline
    $input = Read-Host
    if ($input.ToUpper() -eq "Q") { return }

    $selections = $input -split ","
    foreach ($s in $selections) {
        $idx = [int]($s.Trim()) - 1
        if ($idx -ge 0 -and $idx -lt $list.Count) {
            $app = $list[$idx]
            Write-Status "Yukleniyor: $($app.name)..." "INFO"
            winget install --id $app.id --silent --accept-package-agreements --accept-source-agreements | Out-Null
            Write-Status "$($app.name) yuklendi!" "OK"
        }
    }
    Write-Host ""
    Write-Host "Tum islemler bitti. Devam etmek icin Enter..."
    Read-Host
}

# Privacy & Speed Tweaks
function Invoke-DeepOptimize {
    Write-Status "Sistem geri yukleme noktasi olusturuluyor..." "INFO"
    Checkpoint-Computer -Description "WinOptimizer v2.2 Root" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue
    
    Write-Status "Telemetri ve veri toplama kapatiliyor..." "INFO"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Stop-Service "DiagTrack" -Force -ErrorAction SilentlyContinue
    Set-Service "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue

    Write-Status "Uygulama guc sinirlamasi kapatiliyor (Full Power)..." "INFO"
    $throttlePath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"
    if (-not (Test-Path $throttlePath)) { New-Item -Path $throttlePath -Force | Out-Null }
    Set-ItemProperty -Path $throttlePath -Name "PowerThrottlingOff" -Value 1 -Type DWord -ErrorAction SilentlyContinue

    Write-Status "Gecici dosyalar temizleniyor..." "INFO"
    $tempPaths = @($env:TEMP, "C:\Windows\Temp")
    foreach($p in $tempPaths) { Get-ChildItem $p -Recurse -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue }

    Write-Status "DNS Cloudflare olarak ayarlaniyor..." "INFO"
    Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | ForEach-Object {
        Set-DnsClientServerAddress -InterfaceAlias $_.Name -ServerAddresses ("1.1.1.1", "8.8.8.8") -ErrorAction SilentlyContinue
    }

    Write-Status "Hiz ayarlari uygulandi!" "OK"
}

# ============================================================
#  MAIN MENU
# ============================================================
function Assert-Admin {
    $p = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Start-Process powershell -Verb RunAs -ArgumentList "-File `"$($MyInvocation.ScriptName)`""
        exit
    }
}

Assert-Admin
while ($true) {
    Write-Banner
    Write-Host "  [1] TUM OPTIMIZASYONLARI UYGULA" -ForegroundColor Cyan
    Write-Host "  [2] YAZILIM YUKLEME MENUSU" -ForegroundColor Green
    Write-Host "  [3] TEMIZLIK YAP (TEMP & CACHE)" -ForegroundColor Yellow
    Write-Host "  [4] UYGULAMALARI GUNCELLE (WINGET)" -ForegroundColor Cyan
    Write-Host "  [Q] CIKIS" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Seciminiz: " -NoNewline
    $choice = (Read-Host).ToUpper()

    switch ($choice) {
        "1" { Invoke-DeepOptimize; Write-Host "`nBitti! Devam etmek icin Enter..."; Read-Host }
        "2" { Show-SoftwareMenu }
        "3" { # Sadece temizlik
            $prev = (Get-PSDrive C).Free / 1GB
            Get-ChildItem $env:TEMP -Recurse -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            $now = (Get-PSDrive C).Free / 1GB
            Write-Status "Temizlik bitti. Kazanc: $([math]::Round($now-$prev, 2)) GB" "OK"
            Start-Sleep 2
        }
        "4" { Write-Status "Guncellemeler kontrol ediliyor..."; winget upgrade --all --accept-package-agreements; Write-Host "`nDevam etmek icin Enter..."; Read-Host }
        "Q" { break }
    }
}

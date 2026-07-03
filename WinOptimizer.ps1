#Requires -Version 5.1
<#
.SYNOPSIS
    WinOptimizer v2.2.1 - Advanced Windows CLI Toolbox
.DESCRIPTION
    System optimization, software installation via Winget, and deep cleaning.
.AUTHOR
    Barracuda1337 (github.com/Barracuda1337)
.VERSION
    2.2.1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# ============================================================
#  GLOBALS & FALLBACK CONFIG
# ============================================================
$script:Version = "2.2.1"
$script:Results = @()

# Varsayilan Yazilim Listesi (Eger config.json yoksa buradan okunur)
$script:DefaultApps = @(
    @{ name = "Google Chrome"; id = "Google.Chrome" },
    @{ name = "Visual Studio Code"; id = "Microsoft.VisualStudioCode" },
    @{ name = "Spotify"; id = "Spotify.Spotify" },
    @{ name = "Steam"; id = "Valve.Steam" },
    @{ name = "Discord"; id = "Discord.Discord" },
    @{ name = "VLC Media Player"; id = "VideoLAN.VLC" },
    @{ name = "7-Zip"; id = "7zip.7zip" },
    @{ name = "AB Download Manager"; id = "alirezahe.ABDownloadManager" }
)

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

function Show-SoftwareMenu {
    Write-Banner
    Write-Host "  --- YAZILIM YUKLEME MENUSU (WINGET) ---" -ForegroundColor Yellow
    Write-Host "  Yuklemek istediginiz programlarin numaralarini virgulle ayirarak yazin (or: 1,3,5)" -ForegroundColor Gray
    Write-Host ""
    
    $list = $script:DefaultApps
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
        $idx = 0
        if ([int]::TryParse($s.Trim(), [ref]$idx)) {
            $idx--
            if ($idx -ge 0 -and $idx -lt $list.Count) {
                $app = $list[$idx]
                Write-Status "Yukleniyor: $($app.name)..." "INFO"
                winget install --id $app.id --silent --accept-package-agreements --accept-source-agreements
                Write-Status "$($app.name) yuklendi (veya zaten var)!" "OK"
            }
        }
    }
    Write-Host ""
    Write-Host "Islemler bitti. Devam etmek icin Enter..."
    Read-Host | Out-Null
}

function Invoke-DeepOptimize {
    Write-Section "SISTEM OPTIMIZASYONU"
    Write-Status "Telemetri kapatiliyor..." "INFO"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    
    Write-Status "Performans ayarlari uygulaniyor..." "INFO"
    powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
    
    Write-Status "Gecici dosyalar temizleniyor..." "INFO"
    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-Status "Islem tamamlandi!" "OK"
    Start-Sleep -Seconds 2
}

# ============================================================
#  MAIN ENTRY
# ============================================================
function Assert-Admin {
    $p = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Admin yetkisi gerekiyor..." -ForegroundColor Red
        exit
    }
}

Assert-Admin
while ($true) {
    Write-Banner
    Write-Host "  [1] TUM OPTIMIZASYONLARI UYGULA" -ForegroundColor Cyan
    Write-Host "  [2] YAZILIM YUKLEME MENUSU" -ForegroundColor Green
    Write-Host "  [3] TEMIZLIK YAP (TEMP)" -ForegroundColor Yellow
    Write-Host "  [4] UYGULAMALARI GUNCELLE (WINGET)" -ForegroundColor White
    Write-Host "  [Q] CIKIS" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Seciminiz: " -NoNewline
    $choice = (Read-Host).ToUpper()

    switch ($choice) {
        "1" { Invoke-DeepOptimize }
        "2" { Show-SoftwareMenu }
        "3" { 
            Write-Status "Temizlik yapiliyor..." "INFO"
            Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Status "Bitti!" "OK"; Start-Sleep 2 
        }
        "4" { winget upgrade --all; Write-Host "Devam etmek icin Enter..."; Read-Host | Out-Null }
        "Q" { break }
    }
}

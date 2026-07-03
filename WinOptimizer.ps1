#Requires -Version 5.1
<#
.SYNOPSIS
    WinOptimizer v2.7 - Expert Techolay Toolbox
.DESCRIPTION
    Advanced maintenance tools, categorized App Store, and deep system cleaning.
.AUTHOR
    Barracuda1337 (github.com/Barracuda1337)
.VERSION
    2.7.0
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# ============================================================
#  THE EXPERT SOFTWARE REPOSITORY (V2.7)
# ============================================================
$script:Version = "2.7.0"
$script:SoftwareRepo = @{
    "1" = @{ 
        Name = "Tarayicilar (Browsers)"; 
        Apps = @(
            @{ name = "Google Chrome"; id = "Google.Chrome" },
            @{ name = "Brave Browser"; id = "Brave.Brave" },
            @{ name = "Zen Browser"; id = "Zen-Browser.Zen" },
            @{ name = "Arc Browser"; id = "TheBrowserCompany.Arc" }
        )
    };
    "2" = @{ 
        Name = "Sistem Bakim & Onarim (Expert)"; 
        Apps = @(
            @{ name = "DDU (Driver Uninstaller)"; id = "Wagnardsoft.DisplayDriverUninstaller" },
            @{ name = "Revo Uninstaller (Derin Sil)"; id = "RevoUninstaller.RevoUninstaller" },
            @{ name = "Microsoft PC Manager"; id = "Microsoft.PCManager" },
            @{ name = "Rufus (ISO-to-USB)"; id = "PeteBatard.Rufus" },
            @{ name = "BleachBit (Derin Temizlik)"; id = "BleachBit.BleachBit" },
            @{ name = "Autoruns (Sysinternals)"; id = "Microsoft.Sysinternals.Autoruns" }
        )
    };
    "3" = @{ 
        Name = "Donanim Test & Analiz"; 
        Apps = @(
            @{ name = "CPU-Z"; id = "CPUID.CPU-Z" },
            @{ name = "GPU-Z"; id = "TechPowerUp.GPU-Z" },
            @{ name = "HWiNFO64"; id = "REALiX.HWiNFO64" },
            @{ name = "CrystalDiskInfo"; id = "CrystalDewWorld.CrystalDiskInfo" },
            @{ name = "FurMark (GPU Stress)"; id = "Geeks3D.FurMark" },
            @{ name = "Speccy (Hardware Info)"; id = "Piriform.Speccy" }
        )
    };
    "4" = @{ 
        Name = "Uretkenlik & Medya"; 
        Apps = @(
            @{ name = "Everything (Hizli Arama)"; id = "voidtools.Everything" },
            @{ name = "PowerToys"; id = "Microsoft.PowerToys" },
            @{ name = "Notepad++"; id = "Notepad++.Notepad++" },
            @{ name = "VLC Media Player"; id = "VideoLAN.VLC" },
            @{ name = "Spotify"; id = "Spotify.Spotify" }
        )
    };
    "5" = @{ 
        Name = "Iletisimi & Gaming"; 
        Apps = @(
            @{ name = "Discord"; id = "Discord.Discord" },
            @{ name = "Steam"; id = "Valve.Steam" },
            @{ name = "ExitLag (Ping)"; id = "ExitLag.ExitLag" },
            @{ name = "LagoFast (Ping)"; id = "LagoFast.LagoFast" }
        )
    }
}

# ============================================================
#  CORE FUNCTIONS
# ============================================================
function Write-Banner {
    Clear-Host
    Write-Host "  ================================================================" -ForegroundColor Cyan
    Write-Host "   WinOptimizer v$($script:Version)  --  EXPERT EDITION" -ForegroundColor White
    Write-Host "  ================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-AppStore {
    while ($true) {
        Write-Banner
        Write-Host "  --- UZMAN YAZILIM KATEGORILERI ---" -ForegroundColor Yellow
        $keys = $script:SoftwareRepo.Keys | Sort-Object
        foreach ($k in $keys) { Write-Host "  [$k] $($script:SoftwareRepo[$k].Name)" -ForegroundColor White }
        Write-Host "  [Q] Geri Don" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  Seciminiz: " -NoNewline
        $catInput = Read-Host
        if ($catInput.ToUpper() -eq "Q") { break }

        if ($script:SoftwareRepo.ContainsKey($catInput)) {
            $category = $script:SoftwareRepo[$catInput]
            Write-Banner
            Write-Host "  --- $($category.Name) ---" -ForegroundColor Yellow
            for ($i=0; $i -lt $category.Apps.Count; $i++) {
                Write-Host "  [$($i+1)] $($category.Apps[$i].name)" -ForegroundColor White
            }
            Write-Host ""
            Write-Host "  (or: 1,3) 'A' (Hepsi) | [B] Geri" -ForegroundColor DarkGray
            Write-Host "  Secim: " -NoNewline
            $appInput = Read-Host
            if ($appInput.ToUpper() -eq "B") { continue }

            $targets = if ($appInput.ToUpper() -eq "A") { $category.Apps } else {
                $appInput -split "," | ForEach-Object { 
                    $idx = 0; if([int]::TryParse($_.Trim(), [ref]$idx)) { if($idx -gt 0 -and $idx -le $category.Apps.Count) { $category.Apps[$idx-1] } }
                }
            }
            foreach ($app in $targets) {
                if ($app) {
                    Write-Host "  [!] Yukleniyor: $($app.name)..." -ForegroundColor Cyan
                    winget install --id $app.id --silent --accept-package-agreements --accept-source-agreements
                }
            }
            Write-Host "  Islem tamam. Enter..." -ForegroundColor Green; Read-Host | Out-Null
        }
    }
}

# ============================================================
#  MAIN LOOP
# ============================================================
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-File `"$($MyInvocation.ScriptName)`""; exit
}

while ($true) {
    Write-Banner
    Write-Host "  [1] TUM OPTIMIZASYONLARI UYGULA" -ForegroundColor Cyan
    Write-Host "  [2] UZMAN YAZILIM MAGAZASI (Techolay Meta)" -ForegroundColor Green
    Write-Host "  [3] TUM UYGULAMALARI GUNCELLE (Sistem Sagligi)" -ForegroundColor White
    Write-Host "  [Q] CIKIS" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Seciminiz: " -NoNewline
    $choice = (Read-Host).ToUpper()

    switch ($choice) {
        "1" { 
            Write-Host "  [!] Calisiyor..." -ForegroundColor Cyan
            # Telemetry & Power
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
            # Clean
            Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue 
            Write-Host "  [OK] Bitti!" -ForegroundColor Green; Start-Sleep 2
        }
        "2" { Show-AppStore }
        "3" { winget upgrade --all; Write-Host "Bitti. Enter..."; Read-Host | Out-Null }
        "Q" { break }
    }
}

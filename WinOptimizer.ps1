#Requires -Version 5.1
<#
.SYNOPSIS
    WinOptimizer v2.6 - Techolay Treasure Hub
.DESCRIPTION
    System optimization, categorized App Store, and deep maintenance tools.
.AUTHOR
    Barracuda1337 (github.com/Barracuda1337)
.VERSION
    2.6.0
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# ============================================================
#  ULTIMATE SOFTWARE REPOSITORY (V2.6)
# ============================================================
$script:Version = "2.6.0"
$script:SoftwareRepo = @{
    "1" = @{ 
        Name = "Tarayicilar (Modern & Klasik)"; 
        Apps = @(
            @{ name = "Google Chrome"; id = "Google.Chrome" },
            @{ name = "Zen Browser (Yeni!)"; id = "Zen-Browser.Zen" },
            @{ name = "Arc Browser (Yeni!)"; id = "TheBrowserCompany.Arc" },
            @{ name = "Brave Browser"; id = "Brave.Brave" },
            @{ name = "Mozilla Firefox"; id = "Mozilla.Firefox" }
        )
    };
    "2" = @{ 
        Name = "Bakim, Onarim & Test (Techolay)"; 
        Apps = @(
            @{ name = "DDU (Ekran Karti Temizleyici)"; id = "Wagnardsoft.DisplayDriverUninstaller" },
            @{ name = "MS PC Manager (Resmi)"; id = "Microsoft.PCManager" },
            @{ name = "Rufus (Format USB Hazirla)"; id = "PeteBatard.Rufus" },
            @{ name = "FurMark (GPU Stress Test)"; id = "Geeks3D.FurMark" },
            @{ name = "CrystalDiskInfo (Disk Saglik)"; id = "CrystalDewWorld.CrystalDiskInfo" },
            @{ name = "CrystalDiskMark (Disk Hiz)"; id = "CrystalDewWorld.CrystalDiskMark" }
        )
    };
    "3" = @{ 
        Name = "Donanim Izleme & Ses"; 
        Apps = @(
            @{ name = "MSI Afterburner"; id = "MSI.Afterburner" },
            @{ name = "HWiNFO64"; id = "REALiX.HWiNFO64" },
            @{ name = "CPU-Z"; id = "CPUID.CPU-Z" },
            @{ name = "EarTrumpet (Ses)"; id = "File-New-Project.EarTrumpet" },
            @{ name = "FxSound (Ses)"; id = "FxSound.FxSound" }
        )
    };
    "4" = @{ 
        Name = "Pro Araclar & Gelistirici"; 
        Apps = @(
            @{ name = "Cursor AI"; id = "Anysphere.Cursor" },
            @{ name = "VS Code"; id = "Microsoft.VisualStudioCode" },
            @{ name = "PowerToys"; id = "Microsoft.PowerToys" },
            @{ name = "Everything (Hizli Arama)"; id = "voidtools.Everything" },
            @{ name = "Notepad++"; id = "Notepad++.Notepad++" }
        )
    };
    "5" = @{ 
        Name = "Medya & Internet"; 
        Apps = @(
            @{ name = "Spotify"; id = "Spotify.Spotify" },
            @{ name = "VLC Player"; id = "VideoLAN.VLC" },
            @{ name = "Discord"; id = "Discord.Discord" },
            @{ name = "qBittorrent"; id = "qBittorrent.qBittorrent" },
            @{ name = "IDM (Indirme)"; id = "Tonec.InternetDownloadManager" }
        )
    };
    "6" = @{ 
        Name = "Gaming & Ping Boosters"; 
        Apps = @(
            @{ name = "ExitLag"; id = "ExitLag.ExitLag" },
            @{ name = "LagoFast"; id = "LagoFast.LagoFast" },
            @{ name = "Steam"; id = "Valve.Steam" }
        )
    }
}

# ============================================================
#  ENGINE & UI
# ============================================================
function Write-Banner {
    Clear-Host
    $os = Get-CimInstance Win32_OperatingSystem
    Write-Host "  ================================================================" -ForegroundColor Cyan
    Write-Host "   WinOptimizer v$($script:Version)  --  Techolay Treasure Hunt" -ForegroundColor White
    Write-Host "   User: Barracuda1337 | OS: $($os.Caption)" -ForegroundColor DarkGray
    Write-Host "  ================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-AppStore {
    while ($true) {
        Write-Banner
        Write-Host "  --- KATEGORI SECIN ---" -ForegroundColor Yellow
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
            Write-Host "  Liste: " -ForegroundColor Gray
            for ($i=0; $i -lt $category.Apps.Count; $i++) {
                Write-Host "  [$($i+1)] $($category.Apps[$i].name)" -ForegroundColor White
            }
            Write-Host ""
            Write-Host "  Numaralari yazin (or: 1,3) veya 'A' (Hepsi). Geri icin 'B':" -ForegroundColor DarkGray
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
            Write-Host "  Bitti. Devam etmek icin Enter..." -ForegroundColor Green; Read-Host | Out-Null
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
    Write-Host "  [1] HIZLI OPTIMIZE ET (Temizlik & Servisler)" -ForegroundColor Cyan
    Write-Host "  [2] TE-HO-LAY YAZILIM MAGAZASI" -ForegroundColor Green
    Write-Host "  [3] PING DUSURME REHBERI" -ForegroundColor Yellow
    Write-Host "  [4] TUM UYGULAMALARI GUNCELLE (Sistem Sagligi)" -ForegroundColor White
    Write-Host "  [Q] CIKIS" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Seciminiz: " -NoNewline
    $choice = (Read-Host).ToUpper()

    switch ($choice) {
        "1" { 
            Write-Host "  [!] Calisiyor..." -ForegroundColor Cyan
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
            Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue 
            Write-Host "  [OK] Bitti!" -ForegroundColor Green; Start-Sleep 2
        }
        "2" { Show-AppStore }
        "3" { 
            Clear-Host
            Write-Host "  PING DUSURME REHBERI" -ForegroundColor Yellow
            Write-Host "  1. ExitLag gibi araclar veriyi ISS yonlendirmesinden kurtarir."
            Write-Host "  2. Rakipler: LagoFast, GearUp Booster, NoPing."
            Write-Host "  3. Tavsiye: ISS'niz kotu degilse bu araclar ping artirabilir!"
            Read-Host "  Enter..." | Out-Null
        }
        "4" { winget upgrade --all; Write-Host "Bitti. Enter..."; Read-Host | Out-Null }
        "Q" { break }
    }
}

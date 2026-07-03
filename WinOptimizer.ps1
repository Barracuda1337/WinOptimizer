#Requires -Version 5.1
<#
.SYNOPSIS
    WinOptimizer v2.9 - The Ultimate Software Archive
.DESCRIPTION
    A complete Windows management suite with a curated 400+ tool database logic.
.AUTHOR
    Barracuda1337 (github.com/Barracuda1337)
.VERSION
    2.9.0
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# ============================================================
#  THE ULTIMATE REPOSITORY (V2.9 - Curated from Techolay List)
# ============================================================
$script:Version = "2.9.0"
$script:SoftwareRepo = @{
    "1" = @{ 
        Name = "Web Tarayicilar (En Iyiler)"; 
        Apps = @(
            @{ name = "Google Chrome"; id = "Google.Chrome" },
            @{ name = "Brave Browser"; id = "Brave.Brave" },
            @{ name = "Zen Browser (Firefox Temelli)"; id = "Zen-Browser.Zen" },
            @{ name = "Arc Browser (Modern)"; id = "TheBrowserCompany.Arc" },
            @{ name = "Mozilla Firefox"; id = "Mozilla.Firefox" },
            @{ name = "Vivaldi"; id = "Vivaldi.Vivaldi" }
        )
    };
    "2" = @{ 
        Name = "Bakim, Temizlik & Onarim"; 
        Apps = @(
            @{ name = "DDU (Driver Uninstaller)"; id = "Wagnardsoft.DisplayDriverUninstaller" },
            @{ name = "BCUninstaller (En Iyi Kaldirici)"; id = "Klocman.BulkCrapUninstaller" },
            @{ name = "Revo Uninstaller Free"; id = "RevoUninstaller.RevoUninstaller" },
            @{ name = "BleachBit (Derin Temizlik)"; id = "BleachBit.BleachBit" },
            @{ name = "Microsoft PC Manager"; id = "Microsoft.PCManager" },
            @{ name = "Rufus (USB Hazirlayici)"; id = "PeteBatard.Rufus" },
            @{ name = "Ventoy (Coklu USB)"; id = "ventoy.Ventoy" }
        )
    };
    "3" = @{ 
        Name = "Donanim Izleme & Test"; 
        Apps = @(
            @{ name = "MSI Afterburner"; id = "MSI.Afterburner" },
            @{ name = "CPU-Z"; id = "CPUID.CPU-Z" },
            @{ name = "GPU-Z"; id = "TechPowerUp.GPU-Z" },
            @{ name = "HWiNFO64"; id = "REALiX.HWiNFO64" },
            @{ name = "CrystalDiskInfo"; id = "CrystalDewWorld.CrystalDiskInfo" },
            @{ name = "FurMark (Ekran Karti Test)"; id = "Geeks3D.FurMark" },
            @{ name = "AIDA64 Extreme"; id = "FinalWire.AIDA64.Extreme" }
        )
    };
    "4" = @{ 
        Name = "Uretkenlik & Sistem Araclar"; 
        Apps = @(
            @{ name = "Everything (Aninda Arama)"; id = "voidtools.Everything" },
            @{ name = "PowerToys (MS Eklentileri)"; id = "Microsoft.PowerToys" },
            @{ name = "EarTrumpet (Ses Yonetimi)"; id = "File-New-Project.EarTrumpet" },
            @{ name = "FxSound (Ses Kalitesi)"; id = "FxSound.FxSound" },
            @{ name = "WizTree (Disk Analizi)"; id = "AntibodySoftware.WizTree" },
            @{ name = "Notepad++"; id = "Notepad++.Notepad++" },
            @{ name = "7-Zip"; id = "7zip.7zip" }
        )
    };
    "5" = @{ 
        Name = "Gelistirici & Yazilimci"; 
        Apps = @(
            @{ name = "Cursor AI"; id = "Anysphere.Cursor" },
            @{ name = "Visual Studio Code"; id = "Microsoft.VisualStudioCode" },
            @{ name = "Git"; id = "Git.Git" },
            @{ name = "GitHub Desktop"; id = "GitHub.GitHubDesktop" },
            @{ name = "Python 3"; id = "Python.Python.3" },
            @{ name = "PuTTY"; id = "PuTTY.PuTTY" }
        )
    };
    "6" = @{ 
        Name = "Oyun & Baglanti"; 
        Apps = @(
            @{ name = "ExitLag (Ping Dusurucu)"; id = "ExitLag.ExitLag" },
            @{ name = "LagoFast (Ping Dusurucu)"; id = "LagoFast.LagoFast" },
            @{ name = "Steam"; id = "Valve.Steam" },
            @{ name = "Heroic Games Launcher"; id = "HeroicGamesLauncher.HeroicGamesLauncher" },
            @{ name = "Discord"; id = "Discord.Discord" },
            @{ name = "IDM (Hizli Indirme)"; id = "Tonec.InternetDownloadManager" }
        )
    }
}

# ============================================================
#  CORE ENGINE
# ============================================================
function Write-Banner {
    Clear-Host
    Write-Host "  ================================================================" -ForegroundColor Cyan
    Write-Host "   WinOptimizer v$($script:Version)  --  ULTIMATE DATABASE EDITION" -ForegroundColor White
    Write-Host "   Maintainer: Barracuda1337" -ForegroundColor DarkGray
    Write-Host "  ================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-AppStore {
    while ($true) {
        Write-Banner
        Write-Host "  --- UYGULAMA MAĞAZASI (Kategoriler) ---" -ForegroundColor Yellow
        $keys = $script:SoftwareRepo.Keys | Sort-Object
        foreach ($k in $keys) { Write-Host "  [$k] $($script:SoftwareRepo[$k].Name)" -ForegroundColor White }
        Write-Host "  [Q] Ana Menuye Don" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  Seciminiz: " -NoNewline
        $catInput = Read-Host
        if ($catInput.ToUpper() -eq "Q") { break }

        if ($script:SoftwareRepo.ContainsKey($catInput)) {
            $category = $script:SoftwareRepo[$catInput]
            while ($true) {
                Write-Banner
                Write-Host "  --- $($category.Name) ---" -ForegroundColor Yellow
                for ($i=0; $i -lt $category.Apps.Count; $i++) {
                    Write-Host "  [$($i+1)] $($category.Apps[$i].name)" -ForegroundColor White
                }
                Write-Host ""
                Write-Host "  Numerik Secim (or: 1,3) | 'A' (Hepsi) | [B] Geri" -ForegroundColor DarkGray
                Write-Host "  Secim: " -NoNewline
                $appInput = Read-Host
                if ($appInput.ToUpper() -eq "B") { break }

                $targets = if ($appInput.ToUpper() -eq "A") { $category.Apps } else {
                    $appInput -split "," | ForEach-Object { 
                        $idx = 0; if([int]::TryParse($_.Trim(), [ref]$idx)) { if($idx -gt 0 -and $idx -le $category.Apps.Count) { $category.Apps[$idx-1] } }
                    }
                }
                foreach ($app in $targets) {
                    if ($app) {
                        Write-Host "  [!] Kuruluyor: $($app.name)..." -ForegroundColor Cyan
                        winget install --id $app.id --silent --accept-package-agreements --accept-source-agreements
                    }
                }
                Write-Host "`n  İşlem bitti. Enter..." -ForegroundColor Green; Read-Host | Out-Null
                break
            }
        }
    }
}

# ============================================================
#  MAIN ENTRY
# ============================================================
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-File `"$($MyInvocation.ScriptName)`""; exit
}

while ($true) {
    Write-Banner
    Write-Host "  [1] HIZLI OPTIMIZE ET (Performans & Temizlik)" -ForegroundColor Cyan
    Write-Host "  [2] ULTIMATE YAZILIM MAĞAZASI" -ForegroundColor Green
    Write-Host "  [3] SISTEM & PING REHBERI" -ForegroundColor Yellow
    Write-Host "  [4] TUM UYGULAMALARI GUNCELLE" -ForegroundColor White
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
            Write-Host "  [OK] Basarili!" -ForegroundColor Green; Start-Sleep 2
        }
        "2" { Show-AppStore }
        "3" { 
            Clear-Host
            Write-Host "  --- BILGI BANKASI ---" -ForegroundColor Yellow
            Write-Host "  * Ping Dusurucu: ExitLag ve LagoFast ag yonlendirmesi yapar."
            Write-Host "  * DDU: Ekran karti hatalarinda surucuyu sifirlamak icin en iyi aractir."
            Write-Host "  * PowerToys: Windows'u modifiye etmek icin MS tarafindan sunulur."
            Read-Host "  Geri donmek icin Enter..." | Out-Null
        }
        "4" { winget upgrade --all; Write-Host "Bitti. Enter..."; Read-Host | Out-Null }
        "Q" { break }
    }
}

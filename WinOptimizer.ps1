#Requires -Version 5.1
<#
.SYNOPSIS
    WinOptimizer v2.5 - Community & Techolay Edition
.DESCRIPTION
    Comprehensive Windows survival kit with community-driven app store.
.AUTHOR
    Barracuda1337 (github.com/Barracuda1337)
.VERSION
    2.5.0
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# ============================================================
#  ULTIMATE SOFTWARE REPOSITORY
# ============================================================
$script:Version = "2.5.0"
$script:SoftwareRepo = @{
    "1" = @{ 
        Name = "Web Tarayicilar & Iletisim"; 
        Apps = @(
            @{ name = "Google Chrome"; id = "Google.Chrome" },
            @{ name = "Brave Browser"; id = "Brave.Brave" },
            @{ name = "Discord"; id = "Discord.Discord" },
            @{ name = "Telegram"; id = "Telegram.TelegramDesktop" }
        )
    };
    "2" = @{ 
        Name = "Sistem Izleme & Donanim (Techolay)"; 
        Apps = @(
            @{ name = "MSI Afterburner"; id = "MSI.Afterburner" },
            @{ name = "HWiNFO64"; id = "REALiX.HWiNFO64" },
            @{ name = "CPU-Z"; id = "CPUID.CPU-Z" },
            @{ name = "GPU-Z"; id = "TechPowerUp.GPU-Z" },
            @{ name = "AIDA64 Extreme"; id = "FinalWire.AIDA64.Extreme" }
        )
    };
    "3" = @{ 
        Name = "Medya, Ses & Goruntu"; 
        Apps = @(
            @{ name = "FxSound (Ses Artirici)"; id = "FxSound.FxSound" },
            @{ name = "EarTrumpet (Ses Kontrol)"; id = "File-New-Project.EarTrumpet" },
            @{ name = "VLC Media Player"; id = "VideoLAN.VLC" },
            @{ name = "OBS Studio"; id = "OBSProject.OBSStudio" },
            @{ name = "HandBrake"; id = "HandBrake.HandBrake" },
            @{ name = "Spotify"; id = "Spotify.Spotify" }
        )
    };
    "4" = @{ 
        Name = "Gelistirici & Pro Araclar"; 
        Apps = @(
            @{ name = "Cursor AI"; id = "Anysphere.Cursor" },
            @{ name = "VS Code"; id = "Microsoft.VisualStudioCode" },
            @{ name = "Notepad++"; id = "Notepad++.Notepad++" },
            @{ name = "Git"; id = "Git.Git" },
            @{ name = "PowerToys"; id = "Microsoft.PowerToys" }
        )
    };
    "5" = @{ 
        Name = "Dosya, Disk & Internet"; 
        Apps = @(
            @{ name = "Everything (Arama)"; id = "voidtools.Everything" },
            @{ name = "WizTree (Disk Analiz)"; id = "AntibodySoftware.WizTree" },
            @{ name = "7-Zip"; id = "7zip.7zip" },
            @{ name = "IDM"; id = "Tonec.InternetDownloadManager" },
            @{ name = "qBittorrent"; id = "qBittorrent.qBittorrent" },
            @{ name = "ShareX"; id = "ShareX.ShareX" }
        )
    };
    "6" = @{ 
        Name = "Gaming & Ping Boosters"; 
        Apps = @(
            @{ name = "ExitLag"; id = "ExitLag.ExitLag" },
            @{ name = "LagoFast"; id = "LagoFast.LagoFast" },
            @{ name = "GearUP Booster"; id = "GearUP.GearUPBooster" },
            @{ name = "Steam"; id = "Valve.Steam" }
        )
    }
}

# ============================================================
#  REBHER & ENGINE
# ============================================================
function Show-PingGuide {
    Clear-Host
    Write-Host "  ================================================================" -ForegroundColor Cyan
    Write-Host "                 PING & SISTEM TAVSIYELERI" -ForegroundColor White
    Write-Host "  ================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1. Ping Nasil Duser?" -ForegroundColor Yellow
    Write-Host "     ISS'niz kotu yonlendirme (routing) yapiyorsa ExitLag gibi"
    Write-Host "     araclar verilerinizi hizli sunuculardan gecirir."
    Write-Host ""
    Write-Host "  2. Olmazsa Olmazlar (Techolay Onerileri):" -ForegroundColor Yellow
    Write-Host "     - PowerToys: Windows'u modifiye etmek icin en iyi Microsoft araci."
    Write-Host "     - WizTree: Diskinizde neyin yer kapladigini saniyeler icinde bulur."
    Write-Host "     - EarTrumpet: Her uygulama icin ayri ses kontrolu saglar."
    Write-Host "     - FxSound: Laptop ve kalitesiz hoparlor sesini devasa artirir."
    Write-Host ""
    Write-Host "  [Enter] Geri don..." -ForegroundColor DarkGray
    Read-Host | Out-Null
}

function Write-Banner {
    Clear-Host
    Write-Host "  ================================================================" -ForegroundColor Cyan
    Write-Host "   WinOptimizer v$($script:Version)  --  Ultimate Edition" -ForegroundColor White
    Write-Host "  ================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-AppStore {
    while ($true) {
        Write-Banner
        Write-Host "  --- KATEGORI SECIN (Techolay & Ninite Listesi) ---" -ForegroundColor Yellow
        $keys = $script:SoftwareRepo.Keys | Sort-Object
        foreach ($k in $keys) { Write-Host "  [$k] $($script:SoftwareRepo[$k].Name)" -ForegroundColor White }
        Write-Host "  [Q] Geri Don" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  Seciminiz: " -NoNewline
        $catInput = Read-Host
        if ($catInput.ToUpper() -eq "Q") { break }

        if ($script:SoftwareRepo.ContainsKey($catInput)) {
            $category = $script:SoftwareRepo[$catInput]
            while ($true) {
                Write-Banner
                Write-Host "  --- $($category.Name) ---" -ForegroundColor Yellow
                Write-Host "  Numaralari yazin (or: 1,3) veya 'A' (Hepsi):" -ForegroundColor Gray
                Write-Host ""
                for ($i=0; $i -lt $category.Apps.Count; $i++) {
                    Write-Host "  [$($i+1)] $($category.Apps[$i].name)" -ForegroundColor White
                }
                Write-Host "  [B] Geri" -NoNewline
                Write-Host "  Secim: " -NoNewline
                $appInput = Read-Host
                if ($appInput.ToUpper() -eq "B") { break }

                $targets = if ($appInput.ToUpper() -eq "A") { $category.Apps } else {
                    $appInput -split "," | ForEach-Object { 
                        $idx = 0; if([int]::TryParse($_.Trim(), [ref]$idx)) { if($idx -gt 0 -and $idx -le $category.Apps.Count) { $category.Apps[$idx-1] } }
                    }
                }
                foreach ($app in $targets) {
                    Write-Host "  [!] Kuruluyor: $($app.name)..." -ForegroundColor Cyan
                    winget install --id $app.id --silent --accept-package-agreements --accept-source-agreements
                }
                Write-Host "  Islem bitti. Enter..." -ForegroundColor Green; Read-Host | Out-Null
                break
            }
        }
    }
}

# ============================================================
#  MAIN LOOP
# ============================================================
$p = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-File `"$($MyInvocation.ScriptName)`""; exit
}

while ($true) {
    Write-Banner
    Write-Host "  [1] HIZLI OPTIMIZE ET (Temizlik & Ayarlar)" -ForegroundColor Cyan
    Write-Host "  [2] YAZILIM MAGAZASI (Techolay & Ninite)" -ForegroundColor Green
    Write-Host "  [3] BILGI BANKASI (Ping & Arac Rehberi)" -ForegroundColor Yellow
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
            Write-Host "  [OK] Bitti!" -ForegroundColor Green; Start-Sleep 2
        }
        "2" { Show-AppStore }
        "3" { Show-PingGuide }
        "4" { winget upgrade --all; Write-Host "Bitti. Enter..."; Read-Host | Out-Null }
        "Q" { break }
    }
}

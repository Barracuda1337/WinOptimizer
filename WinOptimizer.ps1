#Requires -Version 5.1
<#
.SYNOPSIS
    WinOptimizer v2.8 - Clean & Independent Toolbox
.DESCRIPTION
    Professional Windows performance and software management suite.
.AUTHOR
    Barracuda1337 (github.com/Barracuda1337)
.VERSION
    2.8.0
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# ============================================================
#  PROFESSIONAL SOFTWARE REPOSITORY (V2.8)
# ============================================================
$script:Version = "2.8.0"
$script:SoftwareRepo = @{
    "1" = @{ 
        Name = "Web Tarayicilar"; 
        Apps = @(
            @{ name = "Google Chrome"; id = "Google.Chrome" },
            @{ name = "Brave Browser"; id = "Brave.Brave" },
            @{ name = "Mozilla Firefox"; id = "Mozilla.Firefox" },
            @{ name = "Zen Browser"; id = "Zen-Browser.Zen" }
        )
    };
    "2" = @{ 
        Name = "Sistem Bakim & Donanim"; 
        Apps = @(
            @{ name = "DDU (Driver Uninstaller)"; id = "Wagnardsoft.DisplayDriverUninstaller" },
            @{ name = "Revo Uninstaller"; id = "RevoUninstaller.RevoUninstaller" },
            @{ name = "MS PC Manager"; id = "Microsoft.PCManager" },
            @{ name = "Rufus (USB Boot)"; id = "PeteBatard.Rufus" },
            @{ name = "HWiNFO64"; id = "REALiX.HWiNFO64" },
            @{ name = "CPU-Z"; id = "CPUID.CPU-Z" }
        )
    };
    "3" = @{ 
        Name = "Uretkenlik & Araclar"; 
        Apps = @(
            @{ name = "Everything (Hizli Arama)"; id = "voidtools.Everything" },
            @{ name = "PowerToys"; id = "Microsoft.PowerToys" },
            @{ name = "Notepad++"; id = "Notepad++.Notepad++" },
            @{ name = "7-Zip"; id = "7zip.7zip" },
            @{ name = "WizTree (Disk)"; id = "AntibodySoftware.WizTree" }
        )
    };
    "4" = @{ 
        Name = "Medya & Iletisim"; 
        Apps = @(
            @{ name = "VLC Player"; id = "VideoLAN.VLC" },
            @{ name = "Spotify"; id = "Spotify.Spotify" },
            @{ name = "Discord"; id = "Discord.Discord" },
            @{ name = "ShareX (Ekran)"; id = "ShareX.ShareX" }
        )
    };
    "5" = @{ 
        Name = "Oyun & Baglanti Hizlandirma"; 
        Apps = @(
            @{ name = "ExitLag"; id = "ExitLag.ExitLag" },
            @{ name = "LagoFast"; id = "LagoFast.LagoFast" },
            @{ name = "Steam"; id = "Valve.Steam" },
            @{ name = "Heroic Games Launcher"; id = "HeroicGamesLauncher.HeroicGamesLauncher" }
        )
    }
}

# ============================================================
#  LOGIC & ENGINE
# ============================================================
function Write-Banner {
    Clear-Host
    Write-Host "  ================================================================" -ForegroundColor Cyan
    Write-Host "   WinOptimizer v$($script:Version)  --  Windows Management Suite" -ForegroundColor White
    Write-Host "   Maintainer: Barracuda1337" -ForegroundColor DarkGray
    Write-Host "  ================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-AppStore {
    while ($true) {
        Write-Banner
        Write-Host "  --- YAZILIM KATEGORILERI ---" -ForegroundColor Yellow
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
            Write-Host "  Numaralari yazin (or: 1,3) veya 'A' (Hepsi). [B] Geri." -ForegroundColor DarkGray
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
                    Write-Host "  [!] Kuruluyor: $($app.name)..." -ForegroundColor Cyan
                    winget install --id $app.id --silent --accept-package-agreements --accept-source-agreements
                }
            }
            Write-Host "  Bitti. Devam etmek için Enter..." -ForegroundColor Green; Read-Host | Out-Null
        }
    }
}

# ============================================================
#  MAIN LOOP
# ============================================================
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-File `"$($MyInvocation.ScriptName)`"" ; exit
}

while ($true) {
    Write-Banner
    Write-Host "  [1] SISTEMI OPTIMIZE ET (Hizli)" -ForegroundColor Cyan
    Write-Host "  [2] UYGULAMA KURULUM MERKEZI" -ForegroundColor Green
    Write-Host "  [3] SISTEM BILGI BANKASI (Ping & Performans)" -ForegroundColor Yellow
    Write-Host "  [4] TUM UYGULAMALARI GUNCELLE" -ForegroundColor White
    Write-Host "  [Q] CIKIS" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Seciminiz: " -NoNewline
    $choice = (Read-Host).ToUpper()

    switch ($choice) {
        "1" { 
            Write-Host "  [!] Islemler yapılıyor..." -ForegroundColor Cyan
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
            Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue 
            Write-Host "  [OK] Basariyla tamamlandi!" -ForegroundColor Green; Start-Sleep 2
        }
        "2" { Show-AppStore }
        "3" { 
            Clear-Host
            Write-Host "  --- SISTEM & PING REHBERI ---" -ForegroundColor Yellow
            Write-Host "  * Ping Dusurucu Programlar: Kotu ISS yonlendirmelerini baypas eder."
            Write-Host "  * Power Throttling: Islemci gucunun kisilmasini onler."
            Write-Host "  * Telemetri: Veri gonderimini durdurarak CPU ve Agi rahatlatir."
            Read-Host "  Geri donmek icin Enter..." | Out-Null
        }
        "4" { winget upgrade --all; Write-Host "Bitti. Enter..."; Read-Host | Out-Null }
        "Q" { break }
    }
}

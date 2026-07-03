#Requires -Version 5.1
<#
.SYNOPSIS
    WinOptimizer v3.0 - The Windows Encyclopedia
.DESCRIPTION
    A massive, categorized software repository and system optimizer.
.AUTHOR
    Barracuda1337 (github.com/Barracuda1337)
.VERSION
    3.0.0
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# ============================================================
#  THE ENCYCLOPEDIA DATABASE (V3.0)
# ============================================================
$script:Version = "3.0.0"
$script:SoftwareRepo = @{
    "1" = @{ 
        Name = "Web Tarayicilar (Browsers)"; 
        Apps = @(
            @{ name = "Google Chrome"; id = "Google.Chrome" },
            @{ name = "Brave Browser"; id = "Brave.Brave" },
            @{ name = "Mozilla Firefox"; id = "Mozilla.Firefox" },
            @{ name = "Zen Browser"; id = "Zen-Browser.Zen" },
            @{ name = "Arc Browser"; id = "TheBrowserCompany.Arc" },
            @{ name = "Vivaldi"; id = "Vivaldi.Vivaldi" },
            @{ name = "Opera GX"; id = "Opera.OperaGX" },
            @{ name = "Tor Browser"; id = "TorProject.TorBrowser" },
            @{ name = "DuckDuckGo"; id = "DuckDuckGo.DesktopBrowser" }
        )
    };
    "2" = @{ 
        Name = "Donanim Izleme & Benchmark"; 
        Apps = @(
            @{ name = "MSI Afterburner"; id = "MSI.Afterburner" },
            @{ name = "HWiNFO64"; id = "REALiX.HWiNFO64" },
            @{ name = "CPU-Z"; id = "CPUID.CPU-Z" },
            @{ name = "GPU-Z"; id = "TechPowerUp.GPU-Z" },
            @{ name = "AIDA64 Extreme"; id = "FinalWire.AIDA64.Extreme" },
            @{ name = "FurMark"; id = "Geeks3D.FurMark" },
            @{ name = "Core Temp"; id = "ALCPU.CoreTemp" },
            @{ name = "HWMonitor"; id = "CPUID.HWMonitor" },
            @{ name = "Cinebench R23"; id = "Maxon.Cinebench.R23" }
        )
    };
    "3" = @{ 
        Name = "Sistem Bakim & Derin Temizlik"; 
        Apps = @(
            @{ name = "DDU (Driver Uninstaller)"; id = "Wagnardsoft.DisplayDriverUninstaller" },
            @{ name = "BCUninstaller (Bulk Crap)"; id = "Klocman.BulkCrapUninstaller" },
            @{ name = "Revo Uninstaller"; id = "RevoUninstaller.RevoUninstaller" },
            @{ name = "BleachBit"; id = "BleachBit.BleachBit" },
            @{ name = "Microsoft PC Manager"; id = "Microsoft.PCManager" },
            @{ name = "Wise Care 365"; id = "WiseCare.WiseCare365" },
            @{ name = "Geek Uninstaller"; id = "GeekProduct.GeekUninstaller" }
        )
    };
    "4" = @{ 
        Name = "Disk & Dosya Yonetimi"; 
        Apps = @(
            @{ name = "WizTree"; id = "AntibodySoftware.WizTree" },
            @{ name = "Everything"; id = "voidtools.Everything" },
            @{ name = "Rufus"; id = "PeteBatard.Rufus" },
            @{ name = "Ventoy"; id = "ventoy.Ventoy" },
            @{ name = "CrystalDiskInfo"; id = "CrystalDewWorld.CrystalDiskInfo" },
            @{ name = "CrystalDiskMark"; id = "CrystalDewWorld.CrystalDiskMark" },
            @{ name = "TreeSize Free"; id = "JAMSoftware.TreeSizeFree" },
            @{ name = "DiskGenius"; id = "Eassos.DiskGenius" }
        )
    };
    "5" = @{ 
        Name = "Gelistirici & Yazilimci"; 
        Apps = @(
            @{ name = "Cursor AI"; id = "Anysphere.Cursor" },
            @{ name = "Visual Studio Code"; id = "Microsoft.VisualStudioCode" },
            @{ name = "Visual Studio 2022"; id = "Microsoft.VisualStudio.2022.Community" },
            @{ name = "Notepad++"; id = "Notepad++.Notepad++" },
            @{ name = "Git & GitHub Desktop"; id = "GitHub.GitHubDesktop" },
            @{ name = "Python 3"; id = "Python.Python.3" },
            @{ name = "Arduino IDE"; id = "Arduino.IDE.2" },
            @{ name = "Docker Desktop"; id = "Docker.DockerDesktop" },
            @{ name = "PuTTY"; id = "PuTTY.PuTTY" }
        )
    };
    "6" = @{ 
        Name = "Medya, Tasarim & OBS"; 
        Apps = @(
            @{ name = "OBS Studio"; id = "OBSProject.OBSStudio" },
            @{ name = "HandBrake"; id = "HandBrake.HandBrake" },
            @{ name = "VLC Media Player"; id = "VideoLAN.VLC" },
            @{ name = "Spotify"; id = "Spotify.Spotify" },
            @{ name = "Audacity"; id = "Audacity.Audacity" },
            @{ name = "Blender"; id = "BlenderFoundation.Blender" },
            @{ name = "GIMP"; id = "GIMP.GIMP" },
            @{ name = "Krita"; id = "KritaFoundation.Krita" },
            @{ name = "CapCut"; id = "ByteDance.CapCut" }
        )
    };
    "7" = @{ 
        Name = "Iletisimi & Sosyal"; 
        Apps = @(
            @{ name = "Discord"; id = "Discord.Discord" },
            @{ name = "Telegram Desktop"; id = "Telegram.TelegramDesktop" },
            @{ name = "WhatsApp"; id = "WhatsApp.WhatsApp" },
            @{ name = "Zoom"; id = "Zoom.Zoom" },
            @{ name = "Microsoft Teams"; id = "Microsoft.Teams" },
            @{ name = "Slack"; id = "SlackTechnologies.Slack" }
        )
    };
    "8" = @{ 
        Name = "Oyun Platformlari & Araclar"; 
        Apps = @(
            @{ name = "Steam"; id = "Valve.Steam" },
            @{ name = "Epic Games Launcher"; id = "EpicGames.EpicGamesLauncher" },
            @{ name = "Heroic Games Launcher"; id = "HeroicGamesLauncher.HeroicGamesLauncher" },
            @{ name = "EA App"; id = "ElectronicArts.EADesktop" },
            @{ name = "Ubisoft Connect"; id = "Ubisoft.Connect" },
            @{ name = "Battle.net"; id = "Blizzard.BattleNet" }
        )
    };
    "9" = @{ 
        Name = "Baglanti & Network (Ping)"; 
        Apps = @(
            @{ name = "ExitLag"; id = "ExitLag.ExitLag" },
            @{ name = "LagoFast"; id = "LagoFast.LagoFast" },
            @{ name = "Cloudflare WARP (1.1.1.1)"; id = "Cloudflare.Warp" },
            @{ name = "Advanced IP Scanner"; id = "Famatech.AdvancedIPScanner" },
            @{ name = "Wireshark"; id = "WiresharkFoundation.Wireshark" },
            @{ name = "GoodbyeDPI"; id = "ValdikSS.GoodbyeDPI" }
        )
    };
    "10" = @{ 
        Name = "Araclar & Sıkıstırma"; 
        Apps = @(
            @{ name = "PowerToys"; id = "Microsoft.PowerToys" },
            @{ name = "7-Zip"; id = "7zip.7zip" },
            @{ name = "WinRAR"; id = "RARLab.WinRAR" },
            @{ name = "IDM (Internet Download Manager)"; id = "Tonec.InternetDownloadManager" },
            @{ name = "Free Download Manager"; id = "SoftDeluxe.FreeDownloadManager" },
            @{ name = "ShareX"; id = "ShareX.ShareX" },
            @{ name = "FxSound"; id = "FxSound.FxSound" }
        )
    }
}

# ============================================================
#  CORE FUNCTIONS
# ============================================================

function Write-Banner {
    Clear-Host
    Write-Host "  ================================================================" -ForegroundColor Cyan
    Write-Host "   WinOptimizer v$($script:Version)  --  THE ENCYCLOPEDIA" -ForegroundColor White
    Write-Host "   Initial Creator: Barracuda1337" -ForegroundColor DarkGray
    Write-Host "  ================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-AppStore {
    while ($true) {
        Write-Banner
        Write-Host "  --- UYGULAMA MERKEZI (Kategoriler) ---" -ForegroundColor Yellow
        $keys = $script:SoftwareRepo.Keys | Sort-Object { [int]$_ }
        foreach ($k in $keys) { Write-Host "  [$k] $($script:SoftwareRepo[$k].Name)" -ForegroundColor White }
        Write-Host "  [F] Manuel Arama & Kurulum (Winget)" -ForegroundColor Green
        Write-Host "  [Q] Ana Menuye Don" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  Seciminiz: " -NoNewline
        $catInput = Read-Host
        
        if ($catInput.ToUpper() -eq "Q") { break }
        if ($catInput.ToUpper() -eq "F") {
            Write-Host "  Kurmak istediginiz programin adini yazin: " -NoNewline
            $search = Read-Host
            Write-Host "  Searching for '$search'..." -ForegroundColor Cyan
            winget search $search
            Write-Host "  Tam ID'yi kopyalayip yapistirin (Veya IPTAL icin Enter): " -NoNewline
            $id = Read-Host
            if ($id) { winget install --id $id }
            continue
        }

        if ($script:SoftwareRepo.ContainsKey($catInput)) {
            $category = $script:SoftwareRepo[$catInput]
            while ($true) {
                Write-Banner
                Write-Host "  --- $($category.Name) ---" -ForegroundColor Yellow
                for ($i=0; $i -lt $category.Apps.Count; $i++) {
                    Write-Host "  [$($i+1)] $($category.Apps[$i].name)" -ForegroundColor White
                }
                Write-Host ""
                Write-Host "  Secim (or: 1,3) | 'A' (Hepsi) | 'B' (Geri): " -NoNewline
                $appInput = Read-Host
                if ($appInput.ToUpper() -eq "B") { break }

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
                Write-Host "  Islem bitti. Enter..." -ForegroundColor Green; Read-Host | Out-Null
                break
            }
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
    Write-Host "  [1] SISTEMI OPTIMIZE ET (Bakim & Hiz)" -ForegroundColor Cyan
    Write-Host "  [2] DEV YAZILIM ANSIKLOPEDISI" -ForegroundColor Green
    Write-Host "  [3] PING & PERFORMANS BILGI BANKASI" -ForegroundColor Yellow
    Write-Host "  [4] SISTEMI GUNCELLE (Tüm Uygulamalar)" -ForegroundColor White
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
            Write-Host "  [OK] Tamamlandi!" -ForegroundColor Green; Start-Sleep 2
        }
        "2" { Show-AppStore }
        "3" { 
            Clear-Host
            Write-Host "  --- WINOPTIMIZER BILGI BANKASI ---" -ForegroundColor Yellow
            Write-Host "  * Ping: Yonlendirme programlari paket kaybinı onler."
            Write-Host "  * Bakim: DDU ve Revo ile kalintisiz temizlik yapin."
            Write-Host "  * Araclar: PowerToys ve Everything ile Windows'u ucurun."
            Read-Host "  Geri gelmek icin Enter..." | Out-Null
        }
        "4" { winget upgrade --all; Write-Host "Bitti. Enter..."; Read-Host | Out-Null }
        "Q" { break }
    }
}

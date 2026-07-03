#Requires -Version 5.1
<#
.SYNOPSIS
    WinOptimizer v2.3 - Global CLI Software Store & Optimizer
.DESCRIPTION
    System optimization and a categorized App Store using Winget.
.AUTHOR
    Barracuda1337 (github.com/Barracuda1337)
.VERSION
    2.3.0
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# ============================================================
#  SOFTWARE DATABASE (Categorized)
# ============================================================
$script:Version = "2.3.0"
$script:SoftwareRepo = @{
    "1" = @{ 
        Name = "Web Tarayicilar"; 
        Apps = @(
            @{ name = "Google Chrome"; id = "Google.Chrome" },
            @{ name = "Mozilla Firefox"; id = "Mozilla.Firefox" },
            @{ name = "Brave Browser"; id = "Brave.Brave" },
            @{ name = "Opera Browser"; id = "Opera.Opera" },
            @{ name = "Vivaldi"; id = "Vivaldi.Vivaldi" }
        )
    };
    "2" = @{ 
        Name = "Gelistirici Araçlari"; 
        Apps = @(
            @{ name = "Cursor AI (IDE)"; id = "Anysphere.Cursor" },
            @{ name = "Visual Studio Code"; id = "Microsoft.VisualStudioCode" },
            @{ name = "Notepad++"; id = "Notepad++.Notepad++" },
            @{ name = "Git"; id = "Git.Git" },
            @{ name = "Python 3"; id = "Python.Python.3" },
            @{ name = "FileZilla"; id = "FileZilla.FileZilla" },
            @{ name = "WinSCP"; id = "WinSCP.WinSCP" }
        )
    };
    "3" = @{ 
        Name = "Medya & Tasarim"; 
        Apps = @(
            @{ name = "Spotify"; id = "Spotify.Spotify" },
            @{ name = "VLC Media Player"; id = "VideoLAN.VLC" },
            @{ name = "Audacity"; id = "Audacity.Audacity" },
            @{ name = "Blender"; id = "BlenderFoundation.Blender" },
            @{ name = "Krita"; id = "KritaFoundation.Krita" },
            @{ name = "GIMP"; id = "GIMP.GIMP" }
        )
    };
    "4" = @{ 
        Name = "Iletisimi & Mesajlasma"; 
        Apps = @(
            @{ name = "Discord"; id = "Discord.Discord" },
            @{ name = "Zoom"; id = "Zoom.Zoom" },
            @{ name = "Microsoft Teams"; id = "Microsoft.Teams" },
            @{ name = "Telegram Desktop"; id = "Telegram.TelegramDesktop" }
        )
    };
    "5" = @{ 
        Name = "Araclar & Sıkıstırma"; 
        Apps = @(
            @{ name = "7-Zip"; id = "7zip.7zip" },
            @{ name = "WinRAR"; id = "RARLab.WinRAR" },
            @{ name = "WizTree (Disk)"; id = "AntibodySoftware.WizTree" },
            @{ name = "AnyDesk"; id = "AnyDeskSoftwareGmbH.AnyDesk" },
            @{ name = "Everything (Search)"; id = "voidtools.Everything" },
            @{ name = "qBittorrent"; id = "qBittorrent.qBittorrent" }
        )
    }
}

# ============================================================
#  UI & ENGINE
# ============================================================
function Write-Banner {
    Clear-Host
    Write-Host "  ================================================================" -ForegroundColor Cyan
    Write-Host "   WinOptimizer v$($script:Version)  --  Software Store" -ForegroundColor White
    Write-Host "  ================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-AppStore {
    while ($true) {
        Write-Banner
        Write-Host "  --- KATEGORI SECIN ---" -ForegroundColor Yellow
        foreach ($key in ($script:SoftwareRepo.Keys | Sort-Object)) {
            Write-Host "  [$key] $($script:SoftwareRepo[$key].Name)" -ForegroundColor White
        }
        Write-Host "  [Q] Ana Menuye Don" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  Seciminiz: " -NoNewline
        $catInput = Read-Host
        if ($catInput.ToUpper() -eq "Q") { break }

        if ($script:SoftwareRepo.ContainsKey($catInput)) {
            $category = $script:SoftwareRepo[$catInput]
            Write-Banner
            Write-Host "  --- $($category.Name) ---" -ForegroundColor Yellow
            Write-Host "  Yuklenecekleri seçin (or: 1,3) veya 'A' (Hepsi):" -ForegroundColor Gray
            Write-Host ""
            
            for ($i=0; $i -lt $category.Apps.Count; $i++) {
                Write-Host "  [$($i+1)] $($category.Apps[$i].name)" -ForegroundColor White
            }
            Write-Host "  [B] Geri Git" -ForegroundColor DarkGray
            Write-Host ""
            Write-Host "  Seciminiz: " -NoNewline
            $appInput = Read-Host
            if ($appInput.ToUpper() -eq "B") { continue }

            $targets = @()
            if ($appInput.ToUpper() -eq "A") {
                $targets = $category.Apps
            } else {
                $indexes = $appInput -split ","
                foreach ($idxStr in $indexes) {
                    $idx = 0
                    if ([int]::TryParse($idxStr.Trim(), [ref]$idx)) {
                        if ($idx -gt 0 -and $idx -le $category.Apps.Count) {
                            $targets += $category.Apps[$idx-1]
                        }
                    }
                }
            }

            foreach ($app in $targets) {
                Write-Host "  [!] Yukleniyor: $($app.name)..." -ForegroundColor Cyan
                winget install --id $app.id --silent --accept-package-agreements --accept-source-agreements
            }
            Write-Host "`n  Islemler bitti. Devam etmek için Enter..." -ForegroundColor Green
            Read-Host | Out-Null
        }
    }
}

function Invoke-QuickOptimize {
    Write-Banner
    Write-Host "  [!] Optimizasyon yapılıyor..." -ForegroundColor Cyan
    # Telemetry
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    # Power Plan
    powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
    # Temp Clean
    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  [OK] Bitti!" -ForegroundColor Green
    Start-Sleep -Seconds 2
}

# ============================================================
#  MAIN MENU
# ============================================================
$p = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-File `"$($MyInvocation.ScriptName)`""
    exit
}

while ($true) {
    Write-Banner
    Write-Host "  [1] TEK TIKLA OPTIMIZE ET (Hizli)" -ForegroundColor Cyan
    Write-Host "  [2] YAZILIM MAGAZASI (Ninite Tarzi)" -ForegroundColor Green
    Write-Host "  [3] TUM UYGULAMALARI GUNCELLE" -ForegroundColor White
    Write-Host "  [Q] CIKIS" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Seciminiz: " -NoNewline
    $choice = (Read-Host).ToUpper()

    switch ($choice) {
        "1" { Invoke-QuickOptimize }
        "2" { Show-AppStore }
        "3" { winget upgrade --all; Write-Host "Bitti. Enter..."; Read-Host | Out-Null }
        "Q" { break }
    }
}

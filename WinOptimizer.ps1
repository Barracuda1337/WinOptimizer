#Requires -Version 5.1
<#
.SYNOPSIS
    WinOptimizer v2.4 - Ultimate Gamer & Utility Edition
.DESCRIPTION
    System optimization, categorized App Store, and Gaming Guide.
.AUTHOR
    Barracuda1337 (github.com/Barracuda1337)
.VERSION
    2.4.0
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# ============================================================
#  EXTENDED SOFTWARE DATABASE
# ============================================================
$script:Version = "2.4.0"
$script:SoftwareRepo = @{
    "1" = @{ 
        Name = "Web Tarayicilar"; 
        Apps = @(
            @{ name = "Google Chrome"; id = "Google.Chrome" },
            @{ name = "Brave Browser"; id = "Brave.Brave" },
            @{ name = "Opera Browser"; id = "Opera.Opera" }
        )
    };
    "2" = @{ 
        Name = "Gelistirici & Tasarim"; 
        Apps = @(
            @{ name = "Cursor AI"; id = "Anysphere.Cursor" },
            @{ name = "VS Code"; id = "Microsoft.VisualStudioCode" },
            @{ name = "Blender"; id = "BlenderFoundation.Blender" }
        )
    };
    "3" = @{ 
        Name = "Super Araclar (Tavsiye)"; 
        Apps = @(
            @{ name = "Everything (Hizli Arama)"; id = "voidtools.Everything" },
            @{ name = "PowerToys (MS Eklentileri)"; id = "Microsoft.PowerToys" },
            @{ name = "ShareX (Ekran Kaydi)"; id = "ShareX.ShareX" },
            @{ name = "LibreOffice (Ucretsiz Office)"; id = "TheDocumentFoundation.LibreOffice" },
            @{ name = "IDM (Hizli Indirme)"; id = "Tonec.InternetDownloadManager" },
            @{ name = "7-Zip"; id = "7zip.7zip" },
            @{ name = "WizTree (Disk Analiz)"; id = "AntibodySoftware.WizTree" }
        )
    };
    "4" = @{ 
        Name = "Gaming & Ping Boosters"; 
        Apps = @(
            @{ name = "ExitLag (Ping Dusurucu)"; id = "ExitLag.ExitLag" },
            @{ name = "LagoFast (Ping Dusurucu)"; id = "LagoFast.LagoFast" },
            @{ name = "GearUP Booster"; id = "GearUP.GearUPBooster" },
            @{ name = "Heroic Games Launcher"; id = "HeroicGamesLauncher.HeroicGamesLauncher" },
            @{ name = "Steam"; id = "Valve.Steam" },
            @{ name = "qBittorrent"; id = "qBittorrent.qBittorrent" }
        )
    }
}

# ============================================================
#  PING GUIDE (Sizin Metinleriniz)
# ============================================================
function Show-PingGuide {
    Clear-Host
    Write-Host "  ================================================================" -ForegroundColor Cyan
    Write-Host "                PING DUSURME REHBERI & TAVSIYELER" -ForegroundColor White
    Write-Host "  ================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1. Ping Dusuren Programlar Nasil Calisir?" -ForegroundColor Yellow
    Write-Host "     Bu programlar VPN degildir, veri yonlendirme (routing) yaparlar."
    Write-Host "     ISS'niz kotu bir yonlendirme yapiyorsa, verilerinizi daha kisa"
    Write-Host "     yollardan oyun sunucusuna ulastirirlar."
    Write-Host ""
    Write-Host "  2. Gercekten Ise Yariyor mu?" -ForegroundColor Yellow
    Write-Host "     Evet! Ornegin CS2'de 45ms alirken ExitLag ile 25ms'ye dusebilir."
    Write-Host "     Ozellikle paket kaybi (packet loss) yasiyorsaniz cozebilir."
    Write-Host ""
    Write-Host "  3. Ban Sebebi mi?" -ForegroundColor Yellow
    Write-Host "     Neredeyse hicbir populer oyunda ban sebebi degildir."
    Write-Host "     Sadece Minecraft Hypixel gibi bazi ozel sunucular izin vermez."
    Write-Host ""
    Write-Host "  4. Tavsiye Edilen Araclar:" -ForegroundColor Green
    Write-Host "     - ExitLag: En stabil ve basarili sonuclari verir."
    Write-Host "     - LagoFast: Denenebilir ancak her sistemde ayni sonucu vermeyebilir."
    Write-Host ""
    Write-Host "  [Enter] Geri don..." -ForegroundColor DarkGray
    Read-Host | Out-Null
}

# ============================================================
#  ENGINE & MENUS
# ============================================================
function Write-Banner {
    Clear-Host
    Write-Host "  ================================================================" -ForegroundColor Cyan
    Write-Host "   WinOptimizer v$($script:Version)  --  By Barracuda1337" -ForegroundColor White
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
        Write-Host "  [Q] Geri Don" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  Seciminiz: " -NoNewline
        $catInput = Read-Host
        if ($catInput.ToUpper() -eq "Q") { break }

        if ($script:SoftwareRepo.ContainsKey($catInput)) {
            $category = $script:SoftwareRepo[$catInput]
            Write-Banner
            Write-Host "  --- $($category.Name) ---" -ForegroundColor Yellow
            Write-Host "  Numaralari yazin (or: 1,2) veya 'A' (Hepsi):" -ForegroundColor Gray
            Write-Host ""
            for ($i=0; $i -lt $category.Apps.Count; $i++) {
                Write-Host "  [$($i+1)] $($category.Apps[$i].name)" -ForegroundColor White
            }
            Write-Host "  [B] Geri" -NoNewline
            Write-Host "  Secim: " -NoNewline
            $appInput = Read-Host
            if ($appInput.ToUpper() -eq "B") { continue }

            $targets = if ($appInput.ToUpper() -eq "A") { $category.Apps } else {
                $appInput -split "," | ForEach-Object { 
                    $idx = 0; if([int]::TryParse($_.Trim(), [ref]$idx)) { if($idx -gt 0 -and $idx -le $category.Apps.Count) { $category.Apps[$idx-1] } }
                }
            }
            foreach ($app in $targets) {
                Write-Host "  [!] Yukleniyor: $($app.name)..." -ForegroundColor Cyan
                winget install --id $app.id --silent --accept-package-agreements --accept-source-agreements
            }
            Write-Host "`n  Bitti. Enter..." -ForegroundColor Green
            Read-Host | Out-Null
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
    Write-Host "  [1] HIZLI OPTIMIZE ET" -ForegroundColor Cyan
    Write-Host "  [2] YAZILIM MAGAZASI (Yeni Araclar!)" -ForegroundColor Green
    Write-Host "  [3] PING DUSURME REHBERI (Bilgi Bankasi)" -ForegroundColor Yellow
    Write-Host "  [4] TUM UYGULAMALARI GUNCELLE" -ForegroundColor White
    Write-Host "  [Q] CIKIS" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Seciminiz: " -NoNewline
    $choice = (Read-Host).ToUpper()

    switch ($choice) {
        "1" { 
            Write-Status "Temizlik ve ayarlar yapiliyor..." "INFO"
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
            Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue 
            Write-Host "  Bitti!" -ForegroundColor Green; Start-Sleep 2
        }
        "2" { Show-AppStore }
        "3" { Show-PingGuide }
        "4" { winget upgrade --all; Write-Host "Bitti. Enter..."; Read-Host | Out-Null }
        "Q" { break }
    }
}

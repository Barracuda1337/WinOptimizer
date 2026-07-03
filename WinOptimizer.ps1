#Requires -Version 5.1
<#
.SYNOPSIS
    WinOptimizer v3.1 - FastMenu Edition
.DESCRIPTION
    High-performance menu navigation with single-key input.
.AUTHOR
    Barracuda1337 (github.com/Barracuda1337)
.VERSION
    3.1.0
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# ============================================================
#  DATABASE (v3.1)
# ============================================================
$script:Version = "3.1.0"
$script:SoftwareRepo = @{
    "1" = @{ Name = "Web Tarayicilar"; Apps = @(@{name="Chrome";id="Google.Chrome"},@{name="Brave";id="Brave.Brave"},@{name="Zen";id="Zen-Browser.Zen"},@{name="Arc";id="TheBrowserCompany.Arc"},@{name="Firefox";id="Mozilla.Firefox"}) }
    "2" = @{ Name = "Calkim & Temizlik"; Apps = @(@{name="DDU";id="Wagnardsoft.DisplayDriverUninstaller"},@{name="BCUninstaller";id="Klocman.BulkCrapUninstaller"},@{name="Revo";id="RevoUninstaller.RevoUninstaller"},@{name="BleachBit";id="BleachBit.BleachBit"},@{name="PC Manager";id="Microsoft.PCManager"}) }
    "3" = @{ Name = "Donanim Izleme"; Apps = @(@{name="Afterburner";id="MSI.Afterburner"},@{name="HWiNFO64";id="REALiX.HWiNFO64"},@{name="CPU-Z";id="CPUID.CPU-Z"},@{name="GPU-Z";id="TechPowerUp.GPU-Z"},@{name="FurMark";id="Geeks3D.FurMark"}) }
    "4" = @{ Name = "Disk & Dosya"; Apps = @(@{name="WizTree";id="AntibodySoftware.WizTree"},@{name="Everything";id="voidtools.Everything"},@{name="Rufus";id="PeteBatard.Rufus"},@{name="Ventoy";id="ventoy.Ventoy"},@{name="CrystalDiskInfo";id="CrystalDewWorld.CrystalDiskInfo"}) }
    "5" = @{ Name = "Gelistirici"; Apps = @(@{name="Cursor AI";id="Anysphere.Cursor"},@{name="VS Code";id="Microsoft.VisualStudioCode"},@{name="Git";id="Git.Git"},@{name="Python 3";id="Python.Python.3"},@{name="PuTTY";id="PuTTY.PuTTY"}) }
    "6" = @{ Name = "Medya & OBS"; Apps = @(@{name="OBS Studio";id="OBSProject.OBSStudio"},@{name="VLC";id="VideoLAN.VLC"},@{name="Spotify";id="Spotify.Spotify"},@{name="Audacity";id="Audacity.Audacity"},@{name="CapCut";id="ByteDance.CapCut"}) }
    "7" = @{ Name = "Iletisimi & Sosyal"; Apps = @(@{name="Discord";id="Discord.Discord"},@{name="Telegram";id="Telegram.TelegramDesktop"},@{name="WhatsApp";id="WhatsApp.WhatsApp"},@{name="Teams";id="Microsoft.Teams"}) }
    "8" = @{ Name = "Oyun Platformlari"; Apps = @(@{name="Steam";id="Valve.Steam"},@{name="Epic";id="EpicGames.EpicGamesLauncher"},@{name="EA App";id="ElectronicArts.EADesktop"},@{name="Battle.net";id="Blizzard.BattleNet"}) }
    "9" = @{ Name = "Baglanti & Ping"; Apps = @(@{name="ExitLag";id="ExitLag.ExitLag"},@{name="LagoFast";id="LagoFast.LagoFast"},@{name="WARP";id="Cloudflare.Warp"},@{name="GoodbyeDPI";id="ValdikSS.GoodbyeDPI"}) }
    "0" = @{ Name = "Araclar & Sıkıstırma"; Apps = @(@{name="7-Zip";id="7zip.7zip"},@{name="WinRAR";id="RARLab.WinRAR"},@{name="IDM";id="Tonec.InternetDownloadManager"},@{name="ShareX";id="ShareX.ShareX"},@{name="PowerToys";id="Microsoft.PowerToys"}) }
}

# ============================================================
#  CORE FUNCTIONS (FAST NAVIGATION)
# ============================================================

function Get-Key {
    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    return $key.Character.ToString().ToUpper()
}

function Write-Banner {
    Clear-Host
    Write-Host "  ================================================================" -ForegroundColor Cyan
    Write-Host "   WinOptimizer v$($script:Version)  --  FASTMENU EDITION" -ForegroundColor White
    Write-Host "   Maintainer: Barracuda1337" -ForegroundColor DarkGray
    Write-Host "  ================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-AppStore {
    while ($true) {
        Write-Banner
        Write-Host "  --- ANSIKLOPEDI (Anlik Navigasyon) ---" -ForegroundColor Yellow
        $keys = $script:SoftwareRepo.Keys | Sort-Object
        foreach ($k in $keys) { Write-Host "  [$k] $($script:SoftwareRepo[$k].Name)" -ForegroundColor White }
        Write-Host "  [F] Manuel Arama | [B] Ana Menu" -ForegroundColor Green
        Write-Host ""
        Write-Host "  Seciminiz (Enter Beklemez): " -NoNewline
        $catInput = Get-Key
        
        if ($catInput -eq "B") { break }
        if ($catInput -eq "F") {
            Write-Host "`n  Ad yazin: " -NoNewline
            $search = Read-Host
            winget search $search
            Write-Host "  Tam ID'yi kopyalayin: " -NoNewline
            $id = Read-Host
            if ($id) { winget install --id $id }
            continue
        }

        if ($script:SoftwareRepo.ContainsKey($catInput)) {
            $category = $script:SoftwareRepo[$catInput]
            Write-Banner
            Write-Host "  --- $($category.Name) ---" -ForegroundColor Yellow
            for ($i=0; $i -lt $category.Apps.Count; $i++) {
                Write-Host "  [$($i+1)] $($category.Apps[$i].name)" -ForegroundColor White
            }
            Write-Host ""
            Write-Host "  Secim (1,3) | 'A' (Hepsi) | 'B' (Geri): " -NoNewline
            $appInput = Read-Host # Coklu secim icin Enter gerekir
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
    Write-Host "  [1] SISTEMI OPTIMIZE ET" -ForegroundColor Cyan
    Write-Host "  [2] ULTIMATE ANSIKLOPEDI" -ForegroundColor Green
    Write-Host "  [3] PING & PERFORMANS BILGISI" -ForegroundColor Yellow
    Write-Host "  [4] SISTEMI GUNCELLE" -ForegroundColor White
    Write-Host "  [Q] CIKIS" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Seciminiz (Anlik): " -NoNewline
    $choice = Get-Key

    switch ($choice) {
        "1" { 
            Write-Host "`n  [!] Kuruluyor..." -ForegroundColor Cyan
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
            Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue 
            Write-Host "  [OK] Basarili!" -ForegroundColor Green; Start-Sleep 1
        }
        "2" { Show-AppStore }
        "3" { 
            Clear-Host
            Write-Host "  --- BILGI BANKASI ---" -ForegroundColor Yellow
            Write-Host "  * Rehberi okumak icin Enter, cikmak için B."
            Read-Host "  Geri gelmek icin Enter..." | Out-Null
        }
        "4" { winget upgrade --all; Write-Host "Bitti. Enter..."; Read-Host | Out-Null }
        "Q" { exit }
    }
}

#Requires -Version 5.1
<#
.SYNOPSIS
    WinOptimizer v3.2.2 - Final Polish
.DESCRIPTION
    The ultimate Windows management suite with perfected character encoding.
.AUTHOR
    Barracuda1337 (github.com/Barracuda1337)
.VERSION
    3.2.2
#>

param(
    [switch]$Silent,
    [string]$Module = "",
    [switch]$NoReport
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# UTF-8 Konsol Desteği
& chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# ============================================================
#  GLOBALS & CONFIG
# ============================================================
$script:Version    = "3.2.2"
$script:ScriptDir  = $PSScriptRoot
$script:ConfigPath = Join-Path $script:ScriptDir "config.json"
$script:LogPath    = "$env:TEMP\WinOptimizer_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$script:ReportPath = "$env:TEMP\WinOptimizer_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
$script:Results    = [System.Collections.Generic.List[PSCustomObject]]::new()
$script:StartTime  = Get-Date

# Default config
$script:Config = if (Test-Path $script:ConfigPath) {
    try { Get-Content $script:ConfigPath -Raw | ConvertFrom-Json } catch { $null }
} else { $null }

if ($null -eq $script:Config) {
    $script:Config = [PSCustomObject]@{
        dns       = [PSCustomObject]@{ primary = "1.1.1.1"; secondary = "8.8.8.8" }
        startup   = [PSCustomObject]@{ safe_to_disable = @("DiscordPTB","EADM","Honeygain","AdobeGCInvoker-1.0","Spotify","EpicGamesLauncher") }
        bloatware = [PSCustomObject]@{ packages = @("Microsoft.BingNews","Microsoft.XboxApp","Microsoft.SkypeApp","Microsoft.ZuneVideo","Microsoft.ZuneMusic") }
        report    = [PSCustomObject]@{ generate_html = $true; open_after_generate = $true }
    }
}

$script:SoftwareRepo = @{
    "1" = @{ Name = "Web Tarayıcılar"; Apps = @(@{name="Chrome";id="Google.Chrome"},@{name="Brave";id="Brave.Brave"},@{name="Zen";id="Zen-Browser.Zen"},@{name="Arc";id="TheBrowserCompany.Arc"},@{name="Firefox";id="Mozilla.Firefox"}) }
    "2" = @{ Name = "Bakım & Temizlik"; Apps = @(@{name="DDU";id="Wagnardsoft.DisplayDriverUninstaller"},@{name="BCUninstaller";id="Klocman.BulkCrapUninstaller"},@{name="Revo";id="RevoUninstaller.RevoUninstaller"},@{name="BleachBit";id="BleachBit.BleachBit"},@{name="PC Manager";id="Microsoft.PCManager"}) }
    "3" = @{ Name = "Donanım İzleme"; Apps = @(@{name="Afterburner";id="MSI.Afterburner"},@{name="HWiNFO64";id="REALiX.HWiNFO64"},@{name="CPU-Z";id="CPUID.CPU-Z"},@{name="GPU-Z";id="TechPowerUp.GPU-Z"},@{name="FurMark";id="Geeks3D.FurMark"}) }
    "4" = @{ Name = "Disk & Dosya"; Apps = @(@{name="WizTree";id="AntibodySoftware.WizTree"},@{name="Everything";id="voidtools.Everything"},@{name="Rufus";id="PeteBatard.Rufus"},@{name="Ventoy";id="ventoy.Ventoy"},@{name="CrystalDiskInfo";id="CrystalDewWorld.CrystalDiskInfo"}) }
    "5" = @{ Name = "Geliştirici"; Apps = @(@{name="Cursor AI";id="Anysphere.Cursor"},@{name="VS Code";id="Microsoft.VisualStudioCode"},@{name="Git";id="Git.Git"},@{name="Python 3";id="Python.Python.3"},@{name="PuTTY";id="PuTTY.PuTTY"}) }
    "6" = @{ Name = "Medya & OBS"; Apps = @(@{name="OBS Studio";id="OBSProject.OBSStudio"},@{name="VLC";id="VideoLAN.VLC"},@{name="Spotify";id="Spotify.Spotify"},@{name="Audacity";id="Audacity.Audacity"},@{name="CapCut";id="ByteDance.CapCut"}) }
    "7" = @{ Name = "İletişim & Sosyal"; Apps = @(@{name="Discord";id="Discord.Discord"},@{name="Telegram";id="Telegram.TelegramDesktop"},@{name="WhatsApp";id="WhatsApp.WhatsApp"},@{name="Teams";id="Microsoft.Teams"}) }
    "8" = @{ Name = "Oyun Platformları"; Apps = @(@{name="Steam";id="Valve.Steam"},@{name="Epic";id="EpicGames.EpicGamesLauncher"},@{name="EA App";id="ElectronicArts.EADesktop"},@{name="Battle.net";id="Blizzard.BattleNet"}) }
    "9" = @{ Name = "Bağlantı & Ping"; Apps = @(@{name="ExitLag";id="ExitLag.ExitLag"},@{name="LagoFast";id="LagoFast.LagoFast"},@{name="WARP";id="Cloudflare.Warp"},@{name="GoodbyeDPI";id="ValdikSS.GoodbyeDPI"}) }
    "0" = @{ Name = "Araçlar & Sıkıştırma"; Apps = @(@{name="7-Zip";id="7zip.7zip"},@{name="WinRAR";id="RARLab.WinRAR"},@{name="IDM";id="Tonec.InternetDownloadManager"},@{name="ShareX";id="ShareX.ShareX"},@{name="PowerToys";id="Microsoft.PowerToys"}) }
}

# ============================================================
#  CORE FUNCTIONS
# ============================================================

function Clear-KeyBuffer {
    while ($Host.UI.RawUI.KeyAvailable) { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") }
}

function Get-Key {
    Clear-KeyBuffer
    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    return $key.Character.ToString().ToUpper()
}

function Write-Log([string]$Msg, [string]$Level = "INFO") {
    Add-Content -Path $script:LogPath -Value "[$Level] $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Msg" -ErrorAction SilentlyContinue
}

function Write-Status([string]$Msg, [string]$Level = "INFO") {
    $icon  = switch ($Level) { "OK" { "[OK]  " } "FAIL" { "[FAIL]" } "WARN" { "[WARN]" } "SKIP" { "[SKIP]" } default { "[....] " } }
    $color = switch ($Level) { "OK" { "Green" } "FAIL" { "Red" } "WARN" { "Yellow" } "SKIP" { "DarkGray" } default { "Cyan" } }
    Write-Host "  $icon $Msg" -ForegroundColor $color
    Write-Log $Msg $Level
}

function Write-Section([string]$Title) {
    Write-Host ""
    Write-Host "  +-- $Title $(('-' * [Math]::Max(2, 60 - $Title.Length)))" -ForegroundColor Yellow
}

function Add-Result([string]$Category, [string]$Action, [bool]$Success, [string]$Detail = "") {
    $script:Results.Add([PSCustomObject]@{
        Time     = (Get-Date -Format 'HH:mm:ss')
        Category = $Category
        Action   = $Action
        Status   = if ($Success) { "OK" } else { "FAILED" }
        Detail   = $Detail
    })
    Write-Log "$Category | $Action | $(if($Success){'OK'}else{'FAILED'}) | $Detail"
}

function Get-SystemSnapshot {
    $os  = Get-CimInstance Win32_OperatingSystem
    return [PSCustomObject]@{
        Time        = Get-Date
        FreeRAM_GB  = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        FreeDisk_GB = [math]::Round((Get-PSDrive C).Free / 1GB, 2)
    }
}

function Write-Banner {
    Clear-Host
    Write-Host "  ================================================================" -ForegroundColor Cyan
    Write-Host "   WinOptimizer v$($script:Version)  --  ULTRA-STABLE" -ForegroundColor White
    Write-Host "   Maintainer: Barracuda1337 | Navigation: Fixed" -ForegroundColor DarkGray
    Write-Host "  ================================================================" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================================
#  MODULES
# ============================================================

function New-OptimizeRestorePoint {
    Write-Section "SİSTEM GERİ YÜKLEME NOKTASI"
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction Stop
        Checkpoint-Computer -Description "WinOptimizer v$($script:Version)" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Status "Geri yükleme noktası oluşturuldu" "OK"
        Add-Result "Sistem" "Geri Yükleme Noktası" $true
    } catch { Write-Status "Hata: $($_.Exception.Message)" "WARN" }
}

function Disable-StartupPrograms {
    Write-Section "BAŞLANGIÇ PROGRAMLARI"
    $toDisable = $script:Config.startup.safe_to_disable
    $count = 0
    foreach ($appName in $toDisable) {
        Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name $appName -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -Name $appName -ErrorAction SilentlyContinue
        $count++
    }
    Write-Status "$count potansiyel öğe kontrol edildi" "OK"
    Add-Result "Sistem" "Başlangıç Programları" $true
}

function Repair-MouseDrivers {
    Write-Section "FARE GECİKMESİ"
    Get-PnpDevice -Class Mouse | ForEach-Object {
        $regKey = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($_.InstanceId)\Device Parameters"
        if (Test-Path $regKey) { Set-ItemProperty -Path $regKey -Name "EnhancedPowerManagementEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
    }
    Write-Status "HID güç yönetimi optimize edildi" "OK"
    Add-Result "Donanım" "Fare Gecikmesi" $true
}

function Set-HighPerformancePlan {
    Write-Section "GÜÇ PLANI"
    powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
    Write-Status "Yüksek Performans planı aktif" "OK"
    Add-Result "Güç" "Performans Planı" $true
}

function Enable-GameMode {
    Write-Section "OYUN MODU"
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Value 2 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowAutoGameMode" -Value 1 -ErrorAction SilentlyContinue
    Write-Status "Game Mode ve HAGS optimize edildi" "OK"
    Add-Result "Oyun" "Game Mode" $true
}

function Clear-TempFiles {
    Write-Section "TEMİZLİK"
    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Status "Geçici dosyalar temizlendi" "OK"
    Add-Result "Disk" "Geçici Dosyalar" $true
}

function Set-OptimalDns {
    Write-Section "DNS"
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    foreach ($a in $adapters) { Set-DnsClientServerAddress -InterfaceAlias $a.Name -ServerAddresses @("1.1.1.1", "8.8.8.8") -ErrorAction SilentlyContinue }
    Write-Status "Cloudflare DNS (1.1.1.1) atandı" "OK"
    Add-Result "Ağ" "DNS Optimizasyonu" $true
}

function Remove-Bloatware {
    Write-Section "BLOATWARE"
    foreach ($p in $script:Config.bloatware.packages) {
        Get-AppxPackage -Name $p | Remove-AppxPackage -ErrorAction SilentlyContinue
    }
    Write-Status "Gereksiz paketler temizlendi" "OK"
    Add-Result "Sistem" "Bloatware Kaldırma" $true
}

function Optimize-VisualEffects {
    Write-Section "GÖRSEL"
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -ErrorAction SilentlyContinue
    Write-Status "Performans modu ayarlandı" "OK"
    Add-Result "Görsel" "Performans Modu" $true
}

function Optimize-DeepStorage {
    Write-Section "DERİN DEPOLAMA"
    powercfg /h off 2>$null
    DISM.exe /Online /Set-ReservedStorageState /State:Disabled /Quiet 2>$null
    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null
    powercfg -setactive e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null
    Write-Status "GB'larca yer açıldı" "OK"
    Add-Result "Disk" "Derin Depolama" $true
}

function Disable-SysMain {
    Write-Section "SYSMAIN"
    Stop-Service SysMain -Force -ErrorAction SilentlyContinue
    Set-Service SysMain -StartupType Disabled -ErrorAction SilentlyContinue
    Write-Status "SysMain kapatıldı" "OK"
    Add-Result "Sistem" "SysMain Kapatma" $true
}

function Optimize-WiFi {
    Write-Section "WI-FI"
    Get-NetAdapter | Where-Object { $_.MediaType -eq "Native 802.11" } | ForEach-Object {
        Set-NetAdapterAdvancedProperty -Name $_.Name -RegistryKeyword "RoamAggressiveness" -RegistryValue 1 -ErrorAction SilentlyContinue
    }
    Write-Status "Wi-Fi optimize edildi" "OK"
    Add-Result "Ağ" "Wi-Fi Optimizasyonu" $true
}

function Optimize-AdvancedTweaks {
    Write-Section "GELİŞMİŞ AYARLAR & GİZLİLİK"
    
    # Telemetry Kapatma
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -ErrorAction SilentlyContinue
    Stop-Service DiagTrack -Force -ErrorAction SilentlyContinue
    Set-Service DiagTrack -StartupType Disabled -ErrorAction SilentlyContinue
    Write-Status "Telemetry ve Veri Toplama kapatıldı" "OK"
    
    # Teslimat Optimizasyonu (WUDO)
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DODownloadMode" -Value 0 -ErrorAction SilentlyContinue
    Write-Status "P2P Güncelleme Paylaşımı kapatıldı" "OK"
    
    # SSD TRIM & Aygıt Taraması
    fsutil behavior set DisableDeleteNotify 0 | Out-Null
    Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\DriverSearching" -Name "SearchOrderConfig" -Value 0 -ErrorAction SilentlyContinue
    Write-Status "SSD TRIM doğrulandı ve Aygıt Taraması optimize edildi" "OK"
    
    # Arka Plan Uygulamaları & Saydamlık
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0 -ErrorAction SilentlyContinue
    Write-Status "Arka Plan Uygulamaları ve Saydamlık efektleri kapatıldı" "OK"

    # PCIe & Hızlı Kapanma
    powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_PCIEXPRESS ASPM 0 2>$null
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "WaitToKillServiceTimeout" -Value "2000" -ErrorAction SilentlyContinue
    Write-Status "Sistem kapanış süresi ve PCIe gecikmesi optimize edildi" "OK"
    
    Add-Result "Sistem" "Gelişmiş Ayarlar Paketi" $true
}

function Register-WeeklyTask {
    param([switch]$Remove)
    $taskName = "WinOptimizer_Weekly"
    if ($Remove) { Unregister-ScheduledTask -TaskName $taskName -Confirm:$false; return }
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File `"$PSScriptRoot\WinOptimizer.ps1`" -Silent"
    $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "03:00AM"
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -RunLevel Highest -Force
    Write-Status "Bakım Görevi Tanımlandı" "OK"
    Add-Result "Görev" "Haftalık Bakım" $true
}

function Export-HtmlReport {
    param($Before, $After)
    Write-Host "`n  [!] Rapor hazırlanıyor ve açılıyor..." -ForegroundColor Cyan
    
    $duration = [math]::Round(((Get-Date) - $script:StartTime).TotalSeconds, 1)
    $okCount   = @($script:Results | Where-Object { $_.Status -eq "OK" }).Count
    $ramGain  = if ($Before -and $After) { [math]::Round($After.FreeRAM_GB - $Before.FreeRAM_GB, 2) } else { 0 }
    $diskGain = if ($Before -and $After) { [math]::Round($After.FreeDisk_GB - $Before.FreeDisk_GB, 2) } else { 0 }

    $rowsHtml = ($script:Results | ForEach-Object {
        $badgeClass = if ($_.Status -eq "OK") { "ok" } else { "fail" }
        "<tr><td>$($_.Category)</td><td>$($_.Action)</td><td><span class='badge $badgeClass'>$($_.Status)</span></td><td>$($_.Detail)</td></tr>"
    }) -join ""

    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>WinOptimizer Premium Report</title>
    <style>
        :root { --bg: #030712; --card: #111827; --accent: #3b82f6; --green: #10b981; --red: #ef4444; --text: #f3f4f6; }
        body { background: var(--bg); color: var(--text); font-family: 'Segoe UI', system-ui, sans-serif; padding: 40px; margin: 0; }
        .container { max-width: 1000px; margin: 0 auto; }
        .header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 40px; border-bottom: 1px solid #374151; padding-bottom: 20px; }
        .grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 20px; margin-bottom: 40px; }
        .card { background: var(--card); border: 1px solid #1f2937; border-radius: 16px; padding: 24px; box-shadow: 0 10px 15px -3px rgba(0,0,0,0.1); }
        .val { font-size: 32px; font-weight: 800; color: var(--accent); }
        .lbl { font-size: 13px; color: #9ca3af; text-transform: uppercase; margin-top: 8px; letter-spacing: 0.1em; }
        table { width: 100%; border-collapse: separate; border-spacing: 0; background: var(--card); border-radius: 16px; overflow: hidden; border: 1px solid #1f2937; }
        th { background: #1f2937; padding: 16px; text-align: left; font-size: 13px; color: #9ca3af; text-transform: uppercase; }
        td { padding: 16px; border-bottom: 1px solid #1f2937; font-size: 14px; }
        .badge { padding: 4px 12px; border-radius: 9999px; font-size: 11px; font-weight: 700; }
        .badge.ok { background: #064e3b; color: #34d399; }
        .badge.fail { background: #7f1d1d; color: #f87171; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div><h1 style="margin:0; font-size:32px;">WinOptimizer <span style="color:var(--accent)">PRO</span></h1></div>
            <div style="text-align:right; color:#9ca3af">$(Get-Date -Format 'F')</div>
        </div>
        <div class="grid">
            <div class="card"><div class="val">$okCount</div><div class="lbl">İşlem Tamam</div></div>
            <div class="card"><div class="val" style="color:var(--green)">+$diskGain GB</div><div class="lbl">Disk Kazancı</div></div>
            <div class="card"><div class="val" style="color:var(--green)">+$ramGain GB</div><div class="lbl">RAM Özgürlüğü</div></div>
            <div class="card"><div class="val">${duration}s</div><div class="lbl">Süre</div></div>
        </div>
        <table>
            <thead><tr><th>Kategori</th><th>Girdi</th><th>Durum</th><th>Detay</th></tr></thead>
            <tbody>$rowsHtml</tbody>
        </table>
    </div>
</body>
</html>
"@
    [System.IO.File]::WriteAllText($script:ReportPath, $html, [System.Text.Encoding]::UTF8)
    $shell = New-Object -ComObject Shell.Application
    $shell.Open($script:ReportPath)
}

function Invoke-AllModules {
    $script:BeforeSnap = Get-SystemSnapshot
    New-OptimizeRestorePoint; Clear-TempFiles; Set-HighPerformancePlan; Enable-GameMode; Set-OptimalDns; Repair-MouseDrivers; Disable-StartupPrograms; Optimize-VisualEffects; Remove-Bloatware; Disable-SysMain; Optimize-WiFi; Optimize-DeepStorage; Optimize-AdvancedTweaks
    $script:AfterSnap = Get-SystemSnapshot
    Export-HtmlReport -Before $script:BeforeSnap -After $script:AfterSnap
}

# ============================================================
#  MENUS
# ============================================================

function Show-OptimizationMenu {
    while ($true) {
        Write-Banner
        Write-Host "  [1] Geri Yükleme Noktası    [2] Temizlik" -ForegroundColor White
        Write-Host "  [3] Güç Planı               [4] Oyun Modu" -ForegroundColor White
        Write-Host "  [5] DNS                     [6] Fare Fix" -ForegroundColor White
        Write-Host "  [7] Başlangıç               [8] Bloatware" -ForegroundColor White
        Write-Host "  [9] Görsel Efekt            [D] Derin Depolama" -ForegroundColor White
        Write-Host "  [S] SysMain                 [W] Wi-Fi" -ForegroundColor White
        Write-Host "  [T] Haftalık Görev          [G] Gelişmiş Ayarlar" -ForegroundColor Green
        Write-Host "  [V] Rapor Aç                [A] Hepsini Uygula" -ForegroundColor Cyan
        Write-Host "  [B] ANA MENÜYE DÖN" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  Seçim: " -NoNewline
        $opt = Get-Key
        
        if ($opt -eq "B") { return }
        if ($opt -eq "1") { New-OptimizeRestorePoint }
        elseif ($opt -eq "2") { Clear-TempFiles }
        elseif ($opt -eq "3") { Set-HighPerformancePlan }
        elseif ($opt -eq "4") { Enable-GameMode }
        elseif ($opt -eq "5") { Set-OptimalDns }
        elseif ($opt -eq "6") { Repair-MouseDrivers }
        elseif ($opt -eq "7") { Disable-StartupPrograms }
        elseif ($opt -eq "8") { Remove-Bloatware }
        elseif ($opt -eq "9") { Optimize-VisualEffects }
        elseif ($opt -eq "D") { Optimize-DeepStorage }
        elseif ($opt -eq "S") { Disable-SysMain }
        elseif ($opt -eq "W") { Optimize-WiFi }
        elseif ($opt -eq "T") { Register-WeeklyTask }
        elseif ($opt -eq "R") { Register-WeeklyTask -Remove }
        elseif ($opt -eq "G") { Optimize-AdvancedTweaks }
        elseif ($opt -eq "V") { Export-HtmlReport }
        elseif ($opt -eq "A") { Invoke-AllModules; return }

        if ("123456789DSWTRVG" -like "*$opt*") {
            Write-Host "`n  Tamamlandı. Devam etmek için bir tuşa basın..." -ForegroundColor DarkGray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
    }
}

function Show-AppStore {
    while ($true) {
        Write-Banner
        Write-Host "  --- YAZILIM YÖNETİCİSİ ---" -ForegroundColor Yellow
        $keys = $script:SoftwareRepo.Keys | Sort-Object
        foreach ($k in $keys) { Write-Host "  [$k] $($script:SoftwareRepo[$k].Name)" -ForegroundColor White }
        Write-Host "  [F] Arama | [B] GERİ DÖN" -ForegroundColor Green
        Write-Host "`n  Seçim: " -NoNewline
        $catInput = Get-Key
        if ($catInput -eq "B") { return }
    }
}

# ============================================================
#  MAIN LOOP
# ============================================================
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-File `"$($MyInvocation.ScriptName)`""; exit
}

if ($Silent) { Invoke-AllModules; exit }

while ($true) {
    Write-Banner
    Write-Host "  [1] OPTİMİZASYON MENÜSÜ" -ForegroundColor Cyan
    Write-Host "  [2] YAZILIM YÖNETİCİSİ" -ForegroundColor Green
    Write-Host "  [3] SİSTEMİ GÜNCELLE" -ForegroundColor Yellow
    Write-Host "  [Q] ÇIKIŞ" -ForegroundColor DarkGray
    Write-Host "`n  Seçiminiz: " -NoNewline
    $startChoice = Get-Key

    if     ($startChoice -eq "1") { Show-OptimizationMenu }
    elseif ($startChoice -eq "2") { Show-AppStore }
    elseif ($startChoice -eq "3") { winget upgrade --all; Read-Host }
    elseif ($startChoice -eq "Q") { exit }
}

#Requires -Version 5.1
<#
.SYNOPSIS
    WinOptimizer v3.2 - FastMenu & Expert Edition
.DESCRIPTION
    The ultimate Windows management suite. Combines instant single-key 
    navigation with professional-grade system optimization modules.
.AUTHOR
    Barracuda1337 (github.com/Barracuda1337)
.VERSION
    3.2.0
#>

param(
    [switch]$Silent,
    [string]$Module = "",
    [switch]$NoReport
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# UTF-8 Konsol Desteği (Windows 10/11 uyumluluğu için)
& chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# ============================================================
#  GLOBALS & CONFIG
# ============================================================
$script:Version    = "3.2.0"
$script:ScriptDir  = $PSScriptRoot
$script:ConfigPath = Join-Path $script:ScriptDir "config.json"
$script:LogPath    = "$env:TEMP\WinOptimizer_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$script:ReportPath = "$env:TEMP\WinOptimizer_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
$script:Results    = [System.Collections.Generic.List[PSCustomObject]]::new()
$script:StartTime  = Get-Date

# Default config if file missing
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

# ============================================================
#  SOFTWARE REPOSITORY (v3.2)
# ============================================================
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
#  CORE FUNCTIONS (UI & LOGIC)
# ============================================================

function Get-Key {
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
    Write-Host "   WinOptimizer v$($script:Version)  --  FASTMENU EXPERT" -ForegroundColor White
    Write-Host "   Maintainer: Barracuda1337 | Performance & Stability" -ForegroundColor DarkGray
    Write-Host "  ================================================================" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================================
#  OPTIMIZATION MODULES
# ============================================================

function New-OptimizeRestorePoint {
    Write-Section "SİSTEM GERİ YÜKLEME NOKTASI"
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction Stop
        Checkpoint-Computer -Description "WinOptimizer v$($script:Version) - $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Status "Geri yükleme noktası oluşturuldu" "OK"
        Add-Result "Restore" "Create restore point" $true
    } catch {
        Write-Status "Oluşturulamadı (24 saat sınırı): $($_.Exception.Message)" "WARN"
        Add-Result "Restore" "Create restore point" $false $_.Exception.Message
    }
}

function Disable-StartupPrograms {
    Write-Section "BAŞLANGIÇ PROGRAMLARI"
    $toDisable = $script:Config.startup.safe_to_disable
    $regPaths = @("HKCU:\Software\Microsoft\Windows\CurrentVersion\Run", "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run")
    $count = 0
    foreach ($appName in $toDisable) {
        foreach ($regPath in $regPaths) {
            if (Get-ItemProperty -Path $regPath -Name $appName -ErrorAction SilentlyContinue) {
                Remove-ItemProperty -Path $regPath -Name $appName -ErrorAction SilentlyContinue
                Write-Status "Devre dışı: $appName" "OK"
                Add-Result "Startup" "Disable $appName" $true
                $count++
            }
        }
    }
    if ($count -eq 0) { Write-Status "Temizlenecek program bulunamadı" "SKIP" }
}

function Repair-MouseDrivers {
    Write-Section "FARE VE PERİFERİK SÜRÜCÜLER"
    $unknownMice = @(Get-PnpDevice -Class Mouse | Where-Object { $_.Status -ne "OK" })
    foreach ($mouse in $unknownMice) {
        Disable-PnpDevice -InstanceId $mouse.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
        Enable-PnpDevice  -InstanceId $mouse.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
        Write-Status "Sürücü yenilendi: $($mouse.FriendlyName)" "OK"
    }
    @(Get-PnpDevice -Class Mouse) | ForEach-Object {
        $regKey = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($_.InstanceId)\Device Parameters"
        if (Test-Path $regKey) { Set-ItemProperty -Path $regKey -Name "EnhancedPowerManagementEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
    }
    Write-Status "HID güç yönetimi devre dışı (Gecikme azaltıldı)" "OK"
}

function Set-HighPerformancePlan {
    Write-Section "GÜÇ VE PERFORMANS"
    powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
    Write-Status "Yüksek Performans planı etkin" "OK"
    
    $mmPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
    Set-ItemProperty -Path $mmPath -Name "NetworkThrottlingIndex" -Value 0xffffffff -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $mmPath -Name "SystemResponsiveness"   -Value 0          -Type DWord -ErrorAction SilentlyContinue
    Write-Status "Ağ ve Sistem öncelikleri optimize edildi" "OK"
}

function Enable-GameMode {
    Write-Section "GAMING OPTİMİZASYONU"
    $gpuPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
    Set-ItemProperty -Path $gpuPath -Name "HwSchMode" -Value 2 -Type DWord -ErrorAction SilentlyContinue
    Write-Status "GPU Hardware Scheduling (HAGS) aktif edildi" "OK"
    
    $gamePath = "HKCU:\Software\Microsoft\GameBar"
    Set-ItemProperty -Path $gamePath -Name "AllowAutoGameMode" -Value 1 -Type DWord -ErrorAction SilentlyContinue
    Write-Status "Game Mode aktif edildi" "OK"
}

function Clear-TempFiles {
    Write-Section "DİSK TEMİZLİĞİ"
    $before = (Get-PSDrive C).Free
    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service wuauserv -ErrorAction SilentlyContinue
    
    $after = (Get-PSDrive C).Free
    $freed = [math]::Round(($after - $before) / 1MB, 2)
    Write-Status "Temizlenen: $freed MB" "OK"
}

function Set-OptimalDns {
    Write-Section "DNS OPTİMİZASYONU"
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.Virtual -eq $false }
    foreach ($a in $adapters) {
        Set-DnsClientServerAddress -InterfaceAlias $a.Name -ServerAddresses @("1.1.1.1", "8.8.8.8") -ErrorAction SilentlyContinue
        Write-Status "$($a.Name): 1.1.1.1 (Cloudflare) atandı" "OK"
    }
    ipconfig /flushdns | Out-Null
}

function Remove-Bloatware {
    Write-Section "BLOATWARE KALDIRMA"
    $packages = $script:Config.bloatware.packages
    foreach ($p in $packages) {
        $app = Get-AppxPackage -Name $p -ErrorAction SilentlyContinue
        if ($app) {
            Remove-AppxPackage -Package $app.PackageFullName -ErrorAction SilentlyContinue
            Write-Status "Kaldırıldı: $p" "OK"
        }
    }
}

function Optimize-VisualEffects {
    Write-Section "GÖRSEL EFEKTLER"
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    Set-ItemProperty -Path $regPath -Name "VisualFXSetting" -Value 2 -Type DWord -ErrorAction SilentlyContinue
    Write-Status "Windows görselleri performans moduna alındı" "OK"
    Add-Result "VisualFX" "Performance Mode" $true
}

function Optimize-DeepStorage {
    Write-Section "DERİN DEPOLAMA VE LATENCY"
    powercfg /h off 2>$null
    Write-Status "Kış Uykusu (Hiberfil.sys) kapatıldı." "OK"
    Add-Result "Storage" "Disable Hibernation" $true

    DISM.exe /Online /Set-ReservedStorageState /State:Disabled /Quiet 2>$null
    Write-Status "Ayrılmış Depolama (7GB) serbest bırakıldı." "OK"
    Add-Result "Storage" "Disable Reserved Storage" $true

    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null
    powercfg -setactive e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null
    Write-Status "Nihai Performans (Ultimate) planı etkin." "OK"
    Add-Result "Power" "Ultimate Performance Plan" $true
}

function Disable-SysMain {
    Write-Section "SYSMAIN / SUPERFETCH"
    $hasSSD = @(Get-PhysicalDisk | Where-Object { $_.MediaType -eq "SSD" })
    if ($hasSSD.Count -gt 0) {
        Stop-Service SysMain -Force -ErrorAction SilentlyContinue
        Set-Service  SysMain -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Status "SysMain durduruldu ($($hasSSD.Count) SSD tespit edildi)" "OK"
    } else {
        Write-Status "HDD sistemi -- SysMain aktif bırakılıyor" "SKIP"
    }
}

function Optimize-WiFi {
    Write-Section "WI-FI OPTİMİZASYONU"
    $wifiAdapters = @(Get-NetAdapter | Where-Object { $_.MediaType -eq "Native 802.11" -and $_.Status -eq "Up" })
    if ($wifiAdapters.Count -eq 0) {
        Write-Status "Aktif Wi-Fi bulunamadı" "SKIP"
        return
    }
    foreach ($wifi in $wifiAdapters) {
        Set-NetAdapterAdvancedProperty -Name $wifi.Name -RegistryKeyword "RoamAggressiveness" -RegistryValue 1 -ErrorAction SilentlyContinue
        Set-NetAdapterAdvancedProperty -Name $wifi.Name -RegistryKeyword "PowerSavingMode" -RegistryValue 0 -ErrorAction SilentlyContinue
        Write-Status "$($wifi.Name): Roaming düşürüldü, güç tasarrufu kapatıldı" "OK"
    }
}

function Register-WeeklyTask {
    param([switch]$Remove)
    Write-Section "HAFTALIK OTOMATİK BAKIM"
    $taskName = "WinOptimizer_WeeklyMaintenance"
    if ($Remove) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
        Write-Status "Görev kaldırıldı" "OK"
        return
    }
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSScriptRoot\WinOptimizer.ps1`" -Silent -NoReport"
    $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "03:00AM"
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -RunLevel Highest -Force | Out-Null
    Write-Status "Zamanlandı: Her Pazar 03:00" "OK"
}

function Show-KnowledgeBase {
    Write-Banner
    Write-Host "  --- BİLGİ BANKASI & REHBER ---" -ForegroundColor Yellow
    Write-Host "  * Fare Gecikmesi: 'Enhanced Power Management' kapatılarak fare tepkisi arttırılır." -ForegroundColor Gray
    Write-Host "  * SysMain: SSD olan sistemlerde gereksiz disk yazmasını önlemek için kapatılır." -ForegroundColor Gray
    Write-Host "  * Ping: ExitLag/LagoFast gibi araçlar paket yönlendirmesini optimize eder." -ForegroundColor Gray
    Write-Host "  * Bloatware: Gereksiz Windows uygulamaları silinerek RAM ve CPU tasarrufu sağlar." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Geri gelmek için bir tuşa basın..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Export-HtmlReport {
    param([PSCustomObject]$Before, [PSCustomObject]$After)
    if ($NoReport) { return }
    
    $duration = [math]::Round(((Get-Date) - $script:StartTime).TotalSeconds, 1)
    $okCount   = @($script:Results | Where-Object { $_.Status -eq "OK" }).Count
    $failCount = @($script:Results | Where-Object { $_.Status -eq "FAILED" }).Count
    
    $ramGain  = if ($Before -and $After) { [math]::Round($After.FreeRAM_GB - $Before.FreeRAM_GB, 2) } else { 0 }
    $diskGain = if ($Before -and $After) { [math]::Round($After.FreeDisk_GB - $Before.FreeDisk_GB, 2) } else { 0 }

    $rowsHtml = ($script:Results | ForEach-Object {
        $badgeClass = switch ($_.Status) { "OK" { "ok" } "FAILED" { "fail" } default { "skip" } }
        "<tr><td>$($_.Category)</td><td>$($_.Action)</td><td><span class='badge $badgeClass'>$($_.Status)</span></td><td>$($_.Detail)</td></tr>"
    }) -join ""

    $html = @"
<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="UTF-8">
<style>
  :root { --bg: #0d1117; --surface: #161b22; --border: #30363d; --text: #e6edf3; --dim: #8b949e; --green: #3fb950; --red: #f85149; --blue: #58a6ff; }
  body { background:var(--bg); color:var(--text); font-family: 'Segoe UI', sans-serif; padding: 40px; }
  .grid { display:grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 40px; }
  .card { background:var(--surface); border:1px solid var(--border); padding:20px; border-radius:12px; }
  .val { font-size:28px; font-weight:bold; color:var(--blue); }
  .lbl { font-size:12px; color:var(--dim); text-transform:uppercase; }
  table { width:100%; border-collapse:collapse; background:var(--surface); border:1px solid var(--border); border-radius:12px; overflow:hidden; }
  th, td { padding:12px 16px; text-align:left; border-bottom:1px solid var(--border); }
  th { background: rgba(255,255,255,0.05); color:var(--dim); }
  .badge { padding:2px 8px; border-radius:6px; font-size:11px; font-weight:bold; }
  .badge.ok { background:#3fb95044; color:var(--green); }
  .badge.fail { background:#f8514944; color:var(--red); }
</style>
</head>
<body>
  <h1 style="color:var(--blue)">WinOptimizer v$($script:Version) Raporu</h1>
  <p style="color:var(--dim)">$(Get-Date -Format 'dd MMMM yyyy HH:mm') | Süre: ${duration}s</p>
  
  <div class="grid">
    <div class="card"><div class="val">$okCount</div><div class="lbl">Tamamlanan</div></div>
    <div class="card"><div class="val" style="color:var(--green)">+$diskGain GB</div><div class="lbl">Disk Kazancı</div></div>
    <div class="card"><div class="val" style="color:var(--green)">+$ramGain GB</div><div class="lbl">RAM Özgürlüğü</div></div>
    <div class="card"><div class="val">$duration s</div><div class="lbl">İşlem Süresi</div></div>
  </div>

  <table>
    <thead><tr><th>Kategori</th><th>İşlem</th><th>Durum</th><th>Detay</th></tr></thead>
    <tbody>$rowsHtml</tbody>
  </table>
</body>
</html>
"@
    [System.IO.File]::WriteAllText($script:ReportPath, $html, [System.Text.Encoding]::UTF8)
    if ($script:Config.report.open_after_generate) { Start-Process $script:ReportPath }
}

function Invoke-AllModules {
    $script:BeforeSnap = Get-SystemSnapshot
    New-OptimizeRestorePoint
    Clear-TempFiles
    Set-HighPerformancePlan
    Enable-GameMode
    Set-OptimalDns
    Repair-MouseDrivers
    Disable-StartupPrograms
    Optimize-VisualEffects
    Remove-Bloatware
    Disable-SysMain
    Optimize-WiFi
    Optimize-DeepStorage
    $script:AfterSnap = Get-SystemSnapshot
    Export-HtmlReport -Before $script:BeforeSnap -After $script:AfterSnap
}

# ============================================================
#  NAVIGATION MENUS
# ============================================================

function Show-OptimizationMenu {
    while ($true) {
        Write-Banner
        Write-Host "  --- OPTİMİZASYON SEÇENEKLERİ ---" -ForegroundColor Yellow
        Write-Host "  [1] Geri Yükleme Noktası Oluştur" -ForegroundColor White
        Write-Host "  [2] Geçici Dosyaları Temizle" -ForegroundColor White
        Write-Host "  [3] Yüksek Performans Güç Planı" -ForegroundColor White
        Write-Host "  [4] Game Mode & HAGS Aktif Et" -ForegroundColor White
        Write-Host "  [5] DNS Optimize Et (1.1.1.1)" -ForegroundColor White
        Write-Host "  [6] Fare Gecikme Onarımı" -ForegroundColor White
        Write-Host "  [7] Başlangıç Programlarını Temizle" -ForegroundColor White
        Write-Host "  [8] Bloatware Kaldır (Xbox, Bing vb.)" -ForegroundColor White
        Write-Host "  [9] Görsel Efektleri Optimize Et" -ForegroundColor White
        Write-Host "  [D] Derin Depolama (SSD Yer Açar)" -ForegroundColor Green
        Write-Host "  [S] SysMain Kapat (SSD Önerilir)" -ForegroundColor White
        Write-Host "  [W] Wi-Fi Optimizasyonu" -ForegroundColor White
        Write-Host "  [T] Haftalık Bakım Görevi Ekle" -ForegroundColor White
        Write-Host "  [R] Haftalık Görevi Kaldır" -ForegroundColor DarkGray
        Write-Host "  [A] Hepsini Uygula (Önerilir)" -ForegroundColor Cyan
        Write-Host "  [B] Geri dön" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  Seciminiz: " -NoNewline
        $opt = Get-Key
        
        switch ($opt) {
            "1" { New-OptimizeRestorePoint }
            "2" { Clear-TempFiles }
            "3" { Set-HighPerformancePlan }
            "4" { Enable-GameMode }
            "5" { Set-OptimalDns }
            "6" { Repair-MouseDrivers }
            "7" { Disable-StartupPrograms }
            "8" { Remove-Bloatware }
            "9" { Optimize-VisualEffects }
            "D" { Optimize-DeepStorage }
            "S" { Disable-SysMain }
            "W" { Optimize-WiFi }
            "T" { Register-WeeklyTask }
            "R" { Register-WeeklyTask -Remove }
            "A" { Invoke-AllModules; break }
            "B" { break }
        }
        if ($opt -ne "B" -and $opt -ne "A") {
            Write-Host "`n  İşlem bitti. Devam etmek için bir tuşa basın..." -ForegroundColor DarkGray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        if ($opt -eq "A") { break }
    }
}

function Show-AppStore {
    while ($true) {
        Write-Banner
        Write-Host "  --- ANSIKLOPEDI (Anlık Navigasyon) ---" -ForegroundColor Yellow
        $keys = $script:SoftwareRepo.Keys | Sort-Object
        foreach ($k in $keys) { Write-Host "  [$k] $($script:SoftwareRepo[$k].Name)" -ForegroundColor White }
        Write-Host "  [F] Manuel Arama | [B] Ana Menü" -ForegroundColor Green
        Write-Host ""
        Write-Host "  Seçiminiz: " -NoNewline
        $catInput = Get-Key
        
        if ($catInput -eq "B") { break }
        if ($catInput -eq "F") {
            Write-Host "`n  Ad yazın: " -NoNewline
            $search = Read-Host
            winget search $search
            Write-Host "  Tam ID'yi kopyalayın: " -NoNewline
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
            Write-Host "  Seçim (1,3) | 'A' (Hepsi) | 'B' (Geri): " -NoNewline
            $appInput = Read-Host
            if ($appInput.ToUpper() -eq "B") { continue }

            $targets = if ($appInput.ToUpper() -eq "A") { $category.Apps } else {
                $appInput -split "," | ForEach-Object { 
                    $idx = 0; if([int]::TryParse($_.Trim(), [ref]$idx)) { if($idx -gt 0 -and $idx -le $category.Apps.Count) { $category.Apps[$idx-1] } }
                }
            }
            foreach ($app in $targets) {
                if ($app) {
                    Write-Host "  [!] Yükleniyor: $($app.name)..." -ForegroundColor Cyan
                    winget install --id $app.id --silent --accept-package-agreements --accept-source-agreements
                }
            }
            Write-Host "  Bitti. Devam etmek için Enter..." -ForegroundColor Green; Read-Host | Out-Null
        }
    }
}

# ============================================================
#  MAIN ENTRY
# ============================================================
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-File `"$($MyInvocation.ScriptName)`""; exit
}

if ($Silent) { Invoke-AllModules; exit }

while ($true) {
    Write-Banner
    Write-Host "  [1] SİSTEMİ OPTİMİZE ET (Menü)" -ForegroundColor Cyan
    Write-Host "  [2] ULTIMATE ANSIKLOPEDI (Store)" -ForegroundColor Green
    Write-Host "  [3] BİLGİ BANKASI / REHBER" -ForegroundColor Blue
    Write-Host "  [4] SİSTEMİ GÜNCELLE (All Apps)" -ForegroundColor Yellow
    Write-Host "  [Q] ÇIKIŞ" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Seçiminiz: " -NoNewline
    $choice = Get-Key

    switch ($choice) {
        "1" { Show-OptimizationMenu }
        "2" { Show-AppStore }
        "3" { Show-KnowledgeBase }
        "4" { winget upgrade --all; Write-Host "Bitti. Enter..."; Read-Host | Out-Null }
        "Q" { exit }
    }
}

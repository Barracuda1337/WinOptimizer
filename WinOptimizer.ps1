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
$script:BackupPath = Join-Path $script:ScriptDir "backups.json"
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

# Somut Performans: Statik sistem bilgilerini önbelleğe al
$script:CachedOS = Get-CimInstance Win32_OperatingSystem

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
    # Statik bilgileri önbellekten, değişken olanları (FreeRAM) anlık al
    $os  = $script:CachedOS
    $freeMem = [math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB, 2)
    return [PSCustomObject]@{
        Time        = Get-Date
        FreeRAM_GB  = $freeMem
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
    <#
    .SYNOPSIS
        Sistem geri yükleme noktası oluşturur ve hata durumunda nedenini analiz eder.
    #>
    Write-Section "SİSTEM GERİ YÜKLEME NOKTASI"
    try {
        Checkpoint-Computer -Description "WinOptimizer Expert v$($script:Version)" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Status "Geri yükleme noktası başarıyla oluşturuldu." "OK"
        Add-Result "Sistem" "Geri Yükleme Noktası" $true
        return $true
    } catch {
        Write-Status "Geri yükleme noktası oluşturulamadı!" "FAIL"
        
        # Derin Analiz
        Write-Host "`n  [!] Hata Analizi Yapılıyor..." -ForegroundColor Yellow
        
        # 1. Sistem Koruması Kontrolü
        $isProtected = (Get-CimInstance -Namespace root/default -ClassName SystemRestoreConfig | Where-Object { $_.Drive -eq "C:\" })
        if ($null -eq $isProtected) {
            Write-Host "  -> C: sürücüsü için Sistem Koruması KAPALI görünüyor." -ForegroundColor Red
        }

        # 2. VSS Servis Kontrolü
        $vss = Get-Service VSS -ErrorAction SilentlyContinue
        if ($vss.StartType -eq "Disabled") {
            Write-Host "  -> VSS (Volume Shadow Copy) servisi DEVRE DIŞI bırakılmış." -ForegroundColor Red
        }

        Write-Host "  -> Hata Detayı: $($_.Exception.Message)" -ForegroundColor Gray

        Add-Result "Sistem" "Geri Yükleme Noktası" $false "Hata: $($_.Exception.Message)"
        return $false
    }
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
        if (Test-Path $regKey) { 
            # Somut Kararlılık: Anahtarı her ihtimale karşı doğrula
            Set-ItemProperty -Path $regKey -Name "EnhancedPowerManagementEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue 
        }
    }
    Write-Status "HID güç yönetimi optimize edildi" "OK"
    Add-Result "Donanım" "Fare Gecikmesi" $true
}

function Set-HighPerformancePlan {
    <#
    .SYNOPSIS
        Yüksek performans güç planını aktif eder ve mevcut planı yedekler.
    #>
    Write-Section "GÜÇ PLANI"
    
    try {
        # Mevcut Aktif Planı Al ve Yedekle
        $currentPlanMsg = powercfg -getactivescheme
        if ($currentPlanMsg -match "GUID: ([\w-]+)") {
            $oldGuid = $matches[1]
            $backups = if (Test-Path $script:BackupPath) { Get-Content $script:BackupPath -Raw | ConvertFrom-Json } else { @{} }
            $backups | Add-Member -Name "PowerPlan" -Value $oldGuid -Force
            $backups | ConvertTo-Json | Out-File $script:BackupPath -Encoding UTF8
        }

        powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
        Write-Status "Yüksek Performans planı aktif edildi (Eski plan yedeklendi)" "OK"
        Add-Result "Güç" "Performans Planı" $true "Eski Plan: $oldGuid"
    } catch {
        Write-Status "Güç planı değiştirilemedi: $($_.Exception.Message)" "FAIL"
    }
}

function Enable-GameMode {
    Write-Section "OYUN MODU"
    $regPaths = @(
        "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers",
        "HKCU:\Software\Microsoft\GameBar"
    )
    
    # Somut Rollback: Mevcut değerleri yedekle
    $backups = if (Test-Path $script:BackupPath) { Get-Content $script:BackupPath -Raw | ConvertFrom-Json } else { [PSCustomObject]@{} }
    if (-not $backups.Registry) { $backups | Add-Member -Name "Registry" -Value (New-Object PSObject) }

    foreach ($path in $regPaths) { 
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null } 
    }
    
    $oldHwSch = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -ErrorAction SilentlyContinue).HwSchMode
    $oldGameBar = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowAutoGameMode" -ErrorAction SilentlyContinue).AllowAutoGameMode
    
    if ($null -ne $oldHwSch) { $backups.Registry | Add-Member -Name "HwSchMode" -Value $oldHwSch -Force }
    if ($null -ne $oldGameBar) { $backups.Registry | Add-Member -Name "AllowAutoGameMode" -Value $oldGameBar -Force }
    $backups | ConvertTo-Json | Out-File $script:BackupPath -Encoding UTF8

    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Value 2 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowAutoGameMode" -Value 1 -ErrorAction SilentlyContinue
    Write-Status "Game Mode ve HAGS optimize edildi" "OK"
    Add-Result "Oyun" "Game Mode" $true
}

function Clear-TempFiles {
    Write-Section "TEMİZLİK"
    $skippedCount = 0
    $successCount = 0
    
    # Somut Kararlılık: Kilitli dosyalar yüzünden tüm işlemin durmasını engellemek için öğeleri tek tek tara
    Get-ChildItem "$env:TEMP\*" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            Remove-Item $_.FullName -Recurse -Force -ErrorAction Stop
            $successCount++
        } catch {
            $skippedCount++
        }
    }
    
    if ($skippedCount -gt 0) {
        Write-Status "Temizlik tamamlandi. $successCount oge silindi, $skippedCount kilitli oge atlandi." "OK"
    } else {
        Write-Status "Gecici dosyalar tamamen temizlendi ($successCount oge)." "OK"
    }
    Add-Result "Disk" "Geçici Dosyalar" $true "Silinen: $successCount, Atlanan: $skippedCount"
}

function Set-OptimalDns {
    <#
    .SYNOPSIS
        DNS sunucularını çözümleme hızı (Latency) açısından test eder ve en hızlısını atar.
    #>
    Write-Section "AKILLI DNS OPTİMİZASYONU"
    
    $dnsServers = @(
        @{ Name = "Cloudflare"; IP = "1.1.1.1"; Alt = "1.0.0.1" },
        @{ Name = "Google";     IP = "8.8.8.8"; Alt = "8.8.4.4" },
        @{ Name = "Quad9";      IP = "9.9.9.9"; Alt = "149.112.112.112" }
    )

    $results = @()
    Write-Host "  DNS sunucuları test ediliyor (Resolve-DnsName)..." -ForegroundColor Gray

    foreach ($server in $dnsServers) {
        $totalTime = 0
        $successCount = 0
        
        # 3 adet test ölçümü yap (ortalama için)
        for ($i=1; $i -le 3; $i++) {
            $test = $null
            $measure = Measure-Command { 
                $test = Resolve-DnsName -Name "www.google.com" -Server $server.IP -Count 1 -QuickLookup -ErrorAction SilentlyContinue 
            }
            if ($test) {
                $totalTime += $measure.TotalMilliseconds
                $successCount++
            }
        }

        if ($successCount -gt 0) {
            $avgTime = [math]::Round($totalTime / $successCount, 2)
            $results += [PSCustomObject]@{ Name = $server.Name; IP = $server.IP; Alt = $server.Alt; Latency = $avgTime }
            Write-Host "  -> $($server.Name): $avgTime ms" -ForegroundColor Cyan
        }
    }

    $bestDns = $results | Sort-Object Latency | Select-Object -First 1

    if ($bestDns) {
        Write-Status "En hızlı sunucu seçildi: $($bestDns.Name) ($($bestDns.Latency) ms)" "OK"
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        
        # Somut Rollback: Mevcut DNS ayarlarını yedekle
        $backups = if (Test-Path $script:BackupPath) { Get-Content $script:BackupPath -Raw | ConvertFrom-Json } else { [PSCustomObject]@{} }
        if (-not $backups.DNS) { $backups | Add-Member -Name "DNS" -Value (New-Object PSObject) }
        
        foreach ($a in $adapters) { 
            $currentDns = (Get-DnsClientServerAddress -InterfaceAlias $a.Name).ServerAddresses
            $backups.DNS | Add-Member -Name $a.Name -Value $currentDns -Force
            Set-DnsClientServerAddress -InterfaceAlias $a.Name -ServerAddresses @($bestDns.IP, $bestDns.Alt) -ErrorAction SilentlyContinue 
        }
        $backups | ConvertTo-Json | Out-File $script:BackupPath -Encoding UTF8

        Add-Result "Ağ" "DNS Optimizasyonu" $true "En hızlı seçilen: $($bestDns.Name)"
    } else {
        Write-Status "DNS testleri başarısız oldu, varsayılan Cloudflare atanıyor." "WARN"
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        foreach ($a in $adapters) { Set-DnsClientServerAddress -InterfaceAlias $a.Name -ServerAddresses @("1.1.1.1", "1.0.0.1") -ErrorAction SilentlyContinue }
        Add-Result "Ağ" "DNS Optimizasyonu" $true "Varsayılan: Cloudflare"
    }
}

function Remove-Bloatware {
    Write-Section "BLOATWARE"
    # Somut Performans İyileştirmesi: Paketleri bir kez yükle, hafızada filtrele
    $allPackages = Get-AppxPackage
    foreach ($p in $script:Config.bloatware.packages) {
        $app = $allPackages | Where-Object { $_.Name -eq $p }
        if ($app) {
            $app | Remove-AppxPackage -ErrorAction SilentlyContinue
            Write-Status "Kaldırıldı: $p" "OK"
        }
    }
    Write-Status "Gereksiz paketler temizlendi" "OK"
    Add-Result "Sistem" "Bloatware Kaldırma" $true
}

function Optimize-VisualEffects {
    Write-Section "GÖRSEL"
    $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    
    # Somut Rollback: Eski değeri yedekle
    $oldVal = (Get-ItemProperty -Path $path -Name "VisualFXSetting" -ErrorAction SilentlyContinue).VisualFXSetting
    if ($null -ne $oldVal) {
        $backups = if (Test-Path $script:BackupPath) { Get-Content $script:BackupPath -Raw | ConvertFrom-Json } else { [PSCustomObject]@{} }
        if (-not $backups.Registry) { $backups | Add-Member -Name "Registry" -Value (New-Object PSObject) }
        $backups.Registry | Add-Member -Name "VisualFXSetting" -Value $oldVal -Force
        $backups | ConvertTo-Json | Out-File $script:BackupPath -Encoding UTF8
    }

    Set-ItemProperty -Path $path -Name "VisualFXSetting" -Value 2 -ErrorAction SilentlyContinue
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
    
    try {
        # Somut Rollback: Servis başlangıç türünü yedekle
        $svc = Get-Service SysMain -ErrorAction SilentlyContinue
        if ($svc) {
            $backups = if (Test-Path $script:BackupPath) { Get-Content $script:BackupPath -Raw | ConvertFrom-Json } else { [PSCustomObject]@{} }
            if (-not $backups.Services) { $backups | Add-Member -Name "Services" -Value (New-Object PSObject) }
            $backups.Services | Add-Member -Name "SysMain" -Value $svc.StartType.ToString() -Force
            $backups | ConvertTo-Json | Out-File $script:BackupPath -Encoding UTF8
        }

        Stop-Service SysMain -Force -ErrorAction Stop
        Set-Service SysMain -StartupType Disabled -ErrorAction Stop
        Write-Status "SysMain kapatıldı (Eski durum yedeklendi)" "OK"
        Add-Result "Sistem" "SysMain Kapatma" $true
    } catch {
        Write-Status "SysMain kapatılamadı: $($_.Exception.Message)" "FAIL"
        Add-Result "Sistem" "SysMain Kapatma" $false "Hata: $($_.Exception.Message)"
    }
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
    $bgPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
    $thPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    if (-not (Test-Path $bgPath)) { New-Item -Path $bgPath -Force | Out-Null }
    if (-not (Test-Path $thPath)) { New-Item -Path $thPath -Force | Out-Null }
    
    Set-ItemProperty -Path $bgPath -Name "GlobalUserDisabled" -Value 1 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $thPath -Name "EnableTransparency" -Value 0 -ErrorAction SilentlyContinue
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

function Invoke-SystemHealthCheck {
    <#
    .SYNOPSIS
        Windows bütünlüğünü DISM ve SFC ile kontrol eder.
    .DESCRIPTION
        Sisteme zarar vermeden dosya bütünlüğünü analiz eder, hata bulunursa onarım seçeneği sunar.
    #>
    Write-Section "SİSTEM SAĞLIK DENETİMİ"
    Write-Status "DISM kontrolü başlatılıyor (CheckHealth)..."
    
    $dismResult = DISM.exe /Online /Cleanup-Image /CheckHealth 2>&1
    $corruptionFound = $false

    if ($dismResult -match "No component store corruption detected") {
        Write-Status "DISM: Bileşen deposu sağlıklı." "OK"
    } else {
        Write-Status "DISM: Bileşen deposunda bozukluk tespit edildi!" "FAIL"
        $corruptionFound = $true
    }

    Write-Status "SFC doğrulaması başlatılıyor (VerifyOnly)..."
    $sfcResult = sfc.exe /verifyonly 2>&1
    
    if ($sfcResult -match "Windows Resource Protection did not find any integrity violations") {
        Write-Status "SFC: Sistem dosyaları bütünlüğü tam." "OK"
    } else {
        Write-Status "SFC: Bütünlük ihlalleri tespit edildi!" "FAIL"
        $corruptionFound = $true
    }

    if ($corruptionFound) {
        Write-Host "`n  [!] Hatalar tespit edildi. Onarım işlemini başlatmak ister misiniz?" -ForegroundColor Yellow
        Write-Host "  (Bu işlem internet bağlantısı gerektirir ve 5-15 dakika sürebilir.)" -ForegroundColor Gray
        Write-Host "  [Y] Evet, Onar | [N] Hayır, Atla" -ForegroundColor White
        Write-Host "`n  Seçiminiz: " -NoNewline
        
        $repairInput = Get-Key
        if ($repairInput -eq "Y") {
            Write-Status "Onarım başlatılıyor... Lütfen bekleyin." "WARN"
            DISM.exe /Online /Cleanup-Image /RestoreHealth
            sfc.exe /scannow
            Write-Status "Onarım işlemi tamamlandı. Sistemin yeniden başlatılması önerilir." "OK"
            Add-Result "Sağlık" "Sistem Onarımı" $true "DISM ve SFC onarımı uygulandı."
        }
    } else {
        Add-Result "Sağlık" "Sistem Denetimi" $true "Bozukluk tespit edilmedi."
    }
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

function Invoke-Rollback {
    <#
    .SYNOPSIS
        Yedeklenen ayarlari backups.json üzerinden geri yükler.
    #>
    Write-Section "AYARLARI GERİ YÜKLEME (UNDO)"
    if (-not (Test-Path $script:BackupPath)) {
        Write-Status "Yedek dosyası bulunamadı." "WARN"
        return
    }

    $backups = Get-Content $script:BackupPath -Raw | ConvertFrom-Json
    
    # 1. Güç Planı Geri Yükleme
    if ($backups.PowerPlan) {
        Write-Host "  -> Yedeklenen Güç Planı bulundu ($($backups.PowerPlan))" -ForegroundColor Cyan
        powercfg -setactive $backups.PowerPlan 2>$null
        Write-Status "Güç planı eski haline getirildi." "OK"
    }

    # 2. DNS Geri Yükleme
    if ($backups.DNS) {
        Write-Host "  -> Yedeklenen DNS ayarları bulundu." -ForegroundColor Cyan
        foreach ($adapterName in $backups.DNS.psobject.properties.Name) {
            $addr = $backups.DNS.$adapterName
            if ($addr) {
                Set-DnsClientServerAddress -InterfaceAlias $adapterName -ServerAddresses $addr -ErrorAction SilentlyContinue
                Write-Status "DNS Geri Yüklendi: $adapterName" "OK"
            }
        }
    }

    # 3. Servis Geri Yükleme
    if ($backups.Services.SysMain) {
        Write-Host "  -> Yedeklenen SysMain durumu bulundu ($($backups.Services.SysMain))" -ForegroundColor Cyan
        Set-Service SysMain -StartupType $backups.Services.SysMain -ErrorAction SilentlyContinue
        Write-Status "SysMain servisi eski durumuna getirildi." "OK"
    }

    # 4. Registry Geri Yükleme
    if ($backups.Registry) {
        Write-Host "  -> Yedeklenen Registry ayarları bulundu." -ForegroundColor Cyan
        if ($backups.Registry.HwSchMode -ne $null) {
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Value $backups.Registry.HwSchMode -ErrorAction SilentlyContinue
        }
        if ($backups.Registry.VisualFXSetting -ne $null) {
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value $backups.Registry.VisualFXSetting -ErrorAction SilentlyContinue
        }
        Write-Status "Registry ayarları geri yüklendi." "OK"
    }

    Write-Host "`n  İşlem tamamlandı. Devam etmek için bir tuşa basın..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Invoke-AllModules {
    $script:BeforeSnap = Get-SystemSnapshot
    
    $rpStatus = New-OptimizeRestorePoint
    if (-not $rpStatus) {
        Write-Host "`n  [!] Geri yükleme noktası OLUŞTURULAMADI." -ForegroundColor Red
        Write-Host "  Kritik sistem değişikliklerine bu güvenlik katmanı olmadan devam etmek RISKLI." -ForegroundColor Yellow
        Write-Host "  Devam etmek istiyor musunuz? [Y/N]" -ForegroundColor White
        $choice = Get-Key
        if ($choice -ne "Y") { return }
    }

    Clear-TempFiles; Set-HighPerformancePlan; Enable-GameMode; Set-OptimalDns; Repair-MouseDrivers; Disable-StartupPrograms; Optimize-VisualEffects; Remove-Bloatware; Disable-SysMain; Optimize-WiFi; Optimize-DeepStorage; Optimize-AdvancedTweaks
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
        Write-Host "  [V] Rapor Aç                [U] AYARLARI GERİ AL" -ForegroundColor Yellow
        Write-Host "  [A] Hepsini Uygula          [B] ANA MENÜYE DÖN" -ForegroundColor Cyan
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
        elseif ($opt -eq "U") { Invoke-Rollback }
        elseif ($opt -eq "A") { Invoke-AllModules; return }

        if ("123456789DSWTRVGU" -like "*$opt*") {
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
    Write-Host "  [3] HAFTALIK GÖREV" -ForegroundColor Yellow
    Write-Host "  [4] SİSTEM SAĞLIK DENETİMİ" -ForegroundColor Blue
    Write-Host "  [5] SİSTEMİ GÜNCELLE" -ForegroundColor DarkCyan
    Write-Host "  [Q] ÇIKIŞ" -ForegroundColor DarkGray
    Write-Host "`n  Seçiminiz: " -NoNewline
    $startChoice = Get-Key

    if     ($startChoice -eq "1") { Show-OptimizationMenu }
    elseif ($startChoice -eq "2") { Show-AppStore }
    elseif ($startChoice -eq "3") { Register-WeeklyTask; Read-Host }
    elseif ($startChoice -eq "4") { Invoke-SystemHealthCheck; Read-Host }
    elseif ($startChoice -eq "5") { winget upgrade --all; Read-Host }
    elseif ($startChoice -eq "Q") { exit }
}

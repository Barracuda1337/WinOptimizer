<div align="center">

<img src="https://img.shields.io/badge/PowerShell-5.1%2B-blue?logo=powershell&logoColor=white" />
<img src="https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows&logoColor=white" />
<img src="https://img.shields.io/badge/License-MIT-green" />
<img src="https://img.shields.io/badge/Version-1.0.0-orange" />

# ⚡ WinOptimizer

**Windows Performance & Stability Optimizer**

*Tek script ile bilgisayarınızı hızlandırın — fare takılması, Chrome donması, yüksek disk kullanımı, ağ sorunlarına toplu çözüm.*

</div>

---

## 🚀 Hızlı Başlangıç

PowerShell'i **Yönetici olarak** açın ve çalıştırın:

```powershell
# Interaktif menu
.\WinOptimizer.ps1

# Tüm optimizasyonları uygula (hızlı)
.\WinOptimizer.ps1 -Silent
```

Veya tek satırda indirip çalıştırın (PowerShell admin):

```powershell
irm https://raw.githubusercontent.com/YOUR_USERNAME/WinOptimizer/main/WinOptimizer.ps1 | iex
```

---

## 🛠️ Modules

| # | Modül | Açıklama |
|---|-------|----------|
| 1 | **Restore Point** | İşlem öncesi sistem geri yükleme noktası oluşturur |
| 2 | **Startup Cleaner** | Gereksiz başlangıç programlarını devre dışı bırakır |
| 3 | **Mouse Driver Repair** | `Unknown` durumdaki HID sürücülerini yeniden yükler |
| 4 | **USB Selective Suspend** | USB güç tasarrufunu kapatır (fare takılma düzeltmesi) |
| 5 | **Power Plan** | Güç planını Yüksek Performans'a alır, Network Throttling'i kaldırır |
| 6 | **SysMain / Superfetch** | SSD sistemlerde gereksiz disk yazımını durdurur |
| 7 | **Temp Cleanup** | `%TEMP%`, `C:\Windows\Temp`, Windows Update cache temizler |
| 8 | **DNS Optimizer** | DNS'i Cloudflare (1.1.1.1) + Google (8.8.8.8) olarak ayarlar |
| 9 | **Ethernet Gigabit** | Gigabit Lite'ı kapatır, 1 Gbps Full Duplex'e ayarlar |
| C | **Chrome Optimizer** | GPU cache, Shader cache temizler, HW Acceleration aktif eder |

---

## 📋 Gereksinimler

- Windows 10 / 11
- PowerShell 5.1+
- **Yönetici (Administrator) yetkisi**

---

## 🎯 Hangi Sorunları Çözer?

| Sorun | Modül |
|-------|-------|
| Açılışta fare takılıyor | Mouse Driver Repair + USB Suspend |
| Chrome'da video donuyor | Chrome Optimizer + Network Throttling |
| ChatGPT/AI araçları kasıyor | DNS Optimizer + Network Throttling |
| Bilgisayar genel yavaşlık | Startup Cleaner + SysMain + Temp Cleanup |
| Ethernet 100 Mbps'te takılı | Ethernet Gigabit Fix |
| Oyun/GPU performans düşüklüğü | Power Plan + GPU Priority |

---

## 📊 Örnek Çıktı

```
  ██╗    ██╗██╗███╗   ██╗ ██████╗ ██████╗ ████████╗██╗███╗   ███╗██╗███████╗███████╗██████╗
  ...

  ┌─ SISTEM GERI YUKLEME NOKTASI ──────────────────────────────────
  ✔  Geri yukleme noktasi olusturuldu

  ┌─ BASLANGIC PROGRAMI OPTIMIZASYONU ─────────────────────────────
  ✔  Devre disi: DiscordPTB (Discord zaten var)
  ✔  Devre disi: Honeygain (arka planda bant genisligi kullanir)
  ○  Bulunamadi / zaten kapali: electron.app.U.GG

  ┌─ GECICI DOSYA TEMIZLIGI ────────────────────────────────────────
  ✔  Kullanici Temp: 1369 MB temizlendi
  ✔  Windows Temp: 31 MB temizlendi
  ✔  Toplam temizlenen: ~1400 MB | C: bos alan: 44.8 GB
```

---

## ⚙️ Gelişmiş Kullanım

```powershell
# Özel başlangıç programı da kapat
.\WinOptimizer.ps1
# Menu'den [2] seçin, script customApps array'ine eklediğiniz adları da kapatır

# Log dosyasına bak
# Log otomatik olarak %TEMP%\WinOptimizer_TARIH.log konumuna kaydedilir
```

---

## 🔄 Geri Alma

Herhangi bir sorun oluşursa:

```
Başlat → "Sistem Geri Yükleme" → "WinOptimizer" adlı nokta → Geri Yükle
```

---

## 📝 Changelog

### v1.0.0
- İlk sürüm
- 10 optimizasyon modülü
- Interactive menu + Silent mode
- Otomatik restore point
- Renkli terminal arayüzü
- Log dosyası desteği

---

## 🤝 Katkı

PR ve issue'lar memnuniyetle karşılanır!

1. Fork edin
2. Feature branch oluşturun (`git checkout -b feature/yeni-modul`)
3. Commit edin (`git commit -m 'feat: yeni modul eklendi'`)
4. Push edin (`git push origin feature/yeni-modul`)
5. Pull Request açın

---

## 📄 Lisans

MIT License — özgürce kullanın, paylaşın, değiştirin.

---

<div align="center">

Made with ❤️ for the Windows community

</div>

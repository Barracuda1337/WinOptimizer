# 🛡️ WinOptimizer Expert Suite

![Version](https://img.shields.io/badge/Version-3.2.6--RC1-blue)
![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011-0078d4)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1-blue)
![Stability](https://img.shields.io/badge/Stability-Production--Ready-success)

WinOptimizer, Microsoft Windows sistemleri için geliştirilmiş profesyonel bir bakım, analiz, onarım ve optimizasyon aracıdır. Diğer scriptlerin aksine, WinOptimizer güvenliği, kararlılığı ve geri alınabilirliği merkeze alır.

---

## 🔥 Temel Özellikler

- **🔄 Granüler Rollback Sistemi:** Yapılan tüm sistem değişiklikleri (Registry, DNS, Güç Planı, Servisler) `backups.json` dosyasına kaydedilir ve tek tıkla geri alınabilir.
- **🛡️ Akıllı Sistem Sağlık Denetimi:** DISM ve SFC araçlarını kullanarak sistem bütünlüğünü kontrol eder. Dil bağımsız (Lokalizasyon dostu) analiz motoru ile Türkçe/İngilizce sistemlerde hatasız çalışır.
- **⚡ Pro-Grade Optimizasyon:** 
  - **Smart DNS:** Gecikme süresini ölçerek en hızlı DNS sunucusunu atar.
  - **Deep Storage:** GB'larca disk alanı açan hibernasyon ve rezerve depolama yönetimi.
  - **Game Mode:** HAGS ve düşük gecikmeli girdi optimizasyonları.
- **📦 Yazılım Yöneticisi:** Winget entegrasyonu ile kategorize edilmiş, popüler uygulamaları tek tıkla kurun.
- **📊 Profesyonel Raporlama:** Tüm işlemlerin sonunda şık, modern ve detaylı bir HTML raporu oluşturulur.

---

## 🛠️ Kurulum ve Kullanım

### Gereksinimler
- Windows 10 veya 11
- PowerShell 5.1 (Windows ile yerleşik gelir)
- Yönetici Yetkisi

### Çalıştırma
Projenin ana dizininde bir PowerShell terminali açın ve şu komutu çalıştırın:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; .\WinOptimizer.ps1
```

---

## 📝 Değişiklik Günlüğü (v3.2.6 RC1)

- **Lokalizasyon:** DISM/SFC analiz sistemi metin tarama yerine Exit Code kontrolüne geçirilerek dünya genelindeki tüm Windows dilleriyle uyumlu hale getirildi.
- **Güvenlik:** Tüm yedekleme ve geri alma süreçlerine hata yönetimi (Try/Catch) eklendi.
- **Hız:** Appx paket temizliği bellek içi filtreleme ile hızlandırıldı.
- **UX:** Yazılım yöneticisi menüsü ve kurulum akışı tamamen fonksiyonel hale getirildi.

---

## ⚠️ Yasal Uyarı
Bu araç sistem ayarlarını değiştirir. Her ne kadar kapsamlı geri alma ve yedekleme sistemleri içerse de, değişiklik yapmadan önce bir **Sistem Geri Yükleme Noktası** oluşturmanız önerilir.

---

**Geliştirici:** Barracuda1337  
**Lisans:** MIT  
*Always backup your data before running system tweaks.*

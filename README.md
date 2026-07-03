<div align="center">

# ⚡ WinOptimizer v2.0

**Modern Windows Performance & Stability Engineering Tool**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue?style=for-the-badge&logo=powershell&logoColor=white)](https://microsoft.com/powershell)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D6?style=for-the-badge&logo=windows&logoColor=white)](https://windows.com)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)
[![Release](https://img.shields.io/badge/Version-2.0.0-orange?style=for-the-badge)](https://github.com/Barracuda1337/WinOptimizer)

---

[🇺🇸 English](#english) | [🇹🇷 Türkçe](#türkçe)

---

</div>

<a name="english"></a>
## 🚀 Features

WinOptimizer is a professional-grade PowerShell script suite designed to eliminate common Windows performance bottlenecks. It focuses on reducing input latency, cleaning system clutter, and optimizing network stack.

### 🛠️ Core Modules
- **Low Latency Input:** Fixes mouse stuttering by repairing HID drivers and disabling USB Selective Suspend.
- **Advanced Cleanup:** Deep cleans temp files, browser caches (Chrome, Firefox, Edge), and Windows Update logs.
- **Gaming Optimization:** Enables Game Mode, Hardware Accelerated GPU Scheduling, and VRR.
- **Network Performance:** Optimizes DNS (Cloudflare/Google), disables Network Throttling, and fixes 100Mbps Ethernet caps.
- **System Stability:** Automatically creates restore points and provides detailed HTML performance reports.

---

<a name="türkçe"></a>
## 🇹🇷 Türkçe Tanıtım

**WinOptimizer**, Windows'unuzun en yüksek verimlilikle çalışması için tasarlanmış kapsamlı bir optimizasyon aracıdır. Özellikle oyuncular, yazılımcılar ve bilgisayarından maksimum hız bekleyen kullanıcılar için geliştirilmiştir.

### ✨ Öne Çıkanlar
- **Fare Takılmasını Giderir:** Fare sürücülerini onarır ve USB güç tasarrufunu kapatarak akıcı hareket sağlar.
- **Derinlemesine Temizlik:** Tarayıcı önbelleklerinden Windows Update kalıntılarına kadar Gigabaytlarca yer açar.
- **Düşük Gecikme:** İnternet ve oyunlardaki tepki süresini (ping) iyileştirmek için ağ ayarlarını optimize eder.
- **HTML Raporu:** İşlem bittiğinde ne kadar RAM/Disk kazandığınızı gösteren şık bir rapor sunar.

---

## 📸 HTML Report Preview
> *The script generates a beautiful dark-themed dashboard showing before/after results.*

---

## ⚡ Quick Start

1. Open **PowerShell as Administrator**.
2. Run the following command:

```powershell
# Clone or Download, then run:
Set-ExecutionPolicy Bypass -Scope Process -Force
.\WinOptimizer.ps1
```

Or run everything silently:
```powershell
.\WinOptimizer.ps1 -Silent
```

---

## ⚙️ Configuration
You can customize the optimization behavior in `config.json`:
- **startup:** List of applications to disable on startup.
- **bloatware:** Built-in Windows apps to be safely removed.
- **dns:** Custom DNS server settings.

---

## 🛡️ Safety & Rollback
WinOptimizer prioritizes safety:
1. **Restore Point:** A system restore point is created before any change.
2. **Log System:** Every action is logged to `%TEMP%\WinOptimizer_DATE.log`.
3. **No Irreversible Changes:** Most optimizations can be reverted via standard Windows settings.

---

## 🤝 Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

Made with 🛠️ by [Barracuda1337 (Yunus Karataş)](https://github.com/Barracuda1337)

</div>

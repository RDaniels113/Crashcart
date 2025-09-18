# Crashcart

**Crashcart** is a collection of real-world technical incidents and recoveries.  
When systems flatline, this repo is the crash cart: case studies, scripts, and artifacts that bring them back.

---

## 🔍 Case Studies
- [Windows 11 BSOD – KMODE_EXCEPTION_NOT_HANDLED](case-studies/Win11-BSOD-KMODE.md)

---

## ⚙️ Scripts
Reusable tools created during incident response:
- `Offline-FilterCheck.ps1` – Enumerate minifilters from an offline Windows hive
- `DriverExport.ps1` – Export driver lists from an offline Windows installation

---

## 📂 Artifacts
Diagnostic outputs captured during incidents:
- `offline-fsfilters.txt` – Offline filter list
- `drivers-offline.txt` – Exported driver inventory
- `windbg-analysis.txt` – Example BSOD analysis output

---

## 💡 Why “Crashcart”?
In medicine, a crash cart is the rolling emergency kit doctors grab when a patient flatlines.  
This repo is the IT equivalent: **field notes, scripts, and recoveries** from real-world technical emergencies.

---

## 📜 License
This project is licensed under the [MIT License](LICENSE).  
Free to use, attribution appreciated.

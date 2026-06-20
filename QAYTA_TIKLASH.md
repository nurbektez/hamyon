# Windows qayta o'rnatishda botni saqlash va tiklash

Bu qo'llanma "Tez Tez Cash" botini Windows qayta o'rnatishdan oldin **saqlash** va
keyin **qayta ishga tushirish** uchun.

---

## A bosqich — HOZIR (Windows o'chirishdan OLDIN)

> ⚠️ Bu bosqichni bajarmasangiz, tokenlar va ma'lumotlar bazasi **butunlay yo'qoladi**.

### 1. Paketlar ro'yxatini saqlang
PowerShell oching va shu buyruqni yozing (botda qaysi Python paketlari borligini yozib oladi):
```powershell
C:\hamyon\miniapp_bot\.venv\Scripts\python.exe -m pip freeze > C:\hamyon\miniapp_bot\requirements.txt
```

### 2. Butun papkani USB yoki Google Drive'ga nusxalang
`C:\hamyon` papkasini **to'liq** USB flesh-disk yoki Google Drive'ga ko'chiring.
Bu hamma narsani saqlaydi:
- 🔑 `.env` — tokenlar, ID'lar
- 💾 `tezfast.db` — barcha ma'lumotlar bazasi
- 🐍 barcha `.py` kodlar
- 📄 `requirements.txt`, `reports/`, `start_all.ps1`

> Eslatma: `.env` va `tezfast.db` da maxfiy ma'lumot bor — ularni **ochiq GitHub'ga
> qo'ymang**. USB yoki Google Drive xavfsizroq.

### 3. (Ixtiyoriy) Kodni GitHub'ga ham yuklang
Qo'shimcha nusxa sifatida `.py` fayllarni github.com/nurbektez/hamyon ga yuklab qo'ying
(`.env` va `.db` dan tashqari).

---

## B bosqich — Windows o'rnatgandan KEYIN

### 1. Papkani qaytaring
USB'dagi `C:\hamyon` papkasini yangi Windows'ning `C:\` diskiga qaytaring.

### 2. Python o'rnating
[python.org](https://www.python.org/downloads/) dan **avvalgi bilan bir xil versiyani**
o'rnating. O'rnatishda **"Add Python to PATH"** katagiga belgi qo'ying.

### 3. cloudflared o'rnating
Tunnel uchun `cloudflared` kerak (avvalgi papkada bo'lsa, qaytadan kerak emas).

### 4. Virtual muhitni (venv) qayta yarating
```powershell
cd C:\hamyon\miniapp_bot
python -m venv .venv
.venv\Scripts\python.exe -m pip install -r requirements.txt
```
> Agar `.venv` papkasini ham nusxalagan bo'lsangiz va Python versiyasi bir xil bo'lsa,
> bu qadam kerak bo'lmasligi mumkin — to'g'ridan-to'g'ri 5-qadamga o'ting va sinab ko'ring.

### 5. Botni ishga tushiring
```powershell
Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File C:\hamyon\miniapp_bot\start_all.ps1" -WindowStyle Normal
```

### 6. Ishlayotganini tekshiring
```powershell
# Jarayon bormi:
Get-WmiObject Win32_Process | Where-Object { $_.CommandLine -like "*bot.py*" } | Select ProcessId

# Loglar:
Get-Content C:\hamyon\miniapp_bot\bot_err.log -Tail 10
Get-Content C:\hamyon\miniapp_bot\watchdog.log -Tail 15
```
Telegram'da botga `/start` yozib sinab ko'ring.

---

## Muammolar bo'lsa
- **Bot javob bermayapti** → `bot_err.log` ni tekshiring (6-qadam).
- **502 xato / WebApp ochilmayapti** → tunnel URL o'zgargan; watchdog `.env` ni avtomatik
  yangilaydi, biroz kuting yoki botni qayta ishga tushiring.
- **`TelegramConflictError`** → 2 ta bot bir vaqtda ishlayapti; eski jarayonni o'ldiring
  (`CLAUDE.md` dagi buyruqqa qarang).

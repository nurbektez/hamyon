# Tez Tez Cash — Telegram Mini App

Telegram bot + WebApp: punktlar (pickup points) bo'yicha naqd pul kirim/chiqim hisobi va
haftalik Excel hisobot. Kod `miniapp_bot/` papkasida.

## Til / Uslub
- Foydalanuvchi bilan **o'zbek tilida** muloqot (lotin alifbosi).
- Bot xabarlari, kod izohlari ham o'zbekcha.

## Fayllar tuzilishi (`C:\hamyon\miniapp_bot\`)
| Fayl | Vazifa |
|------|--------|
| `bot.py` | aiogram3 bot — handlerlar, haftalik hisobot oqimi, punkt sinxronizatsiya |
| `database.py` | SQLite (`tezfast.db`) — users, points, transactions, expenses, weekly_reports |
| `report.py` | Excel hisobot generatsiyasi (openpyxl) |
| `parcelpro.py` | tez.parcelpro.uz API — `cashbox.getPickupPoints` (asosiy sayt) |
| `express139.py` | 139express API — `lc_orderPaymentlistUZ`, faqat `naxt` (naqd) |
| `api.py` | FastAPI — WebApp backend (port 8000) |
| `config.py` | `.env` dan o'qiydi: BOT_TOKEN, WEBAPP_URL, GROUP_ID, ADMIN_ID, CASHIER_ID |
| `webapp.html` | Mini App frontend |
| `start_all.ps1` | Watchdog: API + tunnel + bot ni boshqaradi, qayta tiklaydi |
| `.env` | Maxfiy: tokenlar, URL (gitignore da) |
| `reports/` | Tasdiqlangan/kutilayotgan haftalik Excel fayllar saqlanadi |

## Ishga tushirish / o'chirish
```powershell
# Botni qayta ishga tushirish (eski jarayonlarni o'chirib):
Get-WmiObject Win32_Process | Where-Object { $_.CommandLine -like "*bot.py*" -or $_.CommandLine -like "*start_all*" } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Start-Sleep -Seconds 2
Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File C:\hamyon\miniapp_bot\start_all.ps1" -WindowStyle Normal

# Holatni tekshirish:
Get-WmiObject Win32_Process | Where-Object { $_.CommandLine -like "*bot.py*" } | Select ProcessId

# Loglar:
Get-Content C:\hamyon\miniapp_bot\bot_err.log -Tail 10   # bot logi (aiogram stderr ga yozadi)
Get-Content C:\hamyon\miniapp_bot\watchdog.log -Tail 15  # watchdog
Get-Content C:\hamyon\miniapp_bot\cf.log -Encoding ASCII | Select-String "trycloudflare"  # tunnel URL
```

## Muhim texnik bilimlar
- **Python**: venv da — `C:\hamyon\miniapp_bot\.venv\Scripts\python.exe`. Skript ishga tushirish
  uchun har doim shu yo'lni ishlat (global python EMAS).
- **Bot logi `bot_err.log` ga boradi** (aiogram INFO ni stderr ga yozadi), `bot.log` odatda bo'sh.
- **Jarayonni WMI CommandLine bo'yicha o'ldir**, nom bo'yicha emas — venv python `codex-runtimes`
  bola jarayon ochadi, ikkalasini ham o'ldirish kerak.
- **Bir vaqtda 2 bot ishlasa** → `TelegramConflictError`. Ishga tushirishdan oldin har doim
  eski jarayonlarni o'ldir.
- **Tunnel (WEBAPP_URL)**: bepul cloudflared (`trycloudflare.com`) har qayta ishga tushganda
  URL ni o'zgartiradi → watchdog `.env` ni avtomatik yangilaydi. 429 rate-limit bo'lsa
  localhost.run (SSH) ga fallback qiladi. Bu 502 xatolarning asosiy sababi.
- **PowerShell-da apostrofli matn** (masalan `To'raqo'rg'on`) muammo beradi — bash ishlat yoki
  Python skript orqali yoz.
- **PowerShell here-string** (`@'...'@`) ko'pincha bu muhitda parse xatosi beradi — bir qatorli
  buyruq yoki Write/Edit tool ishlat.

## API mantiqi
- **parcelpro** = ASOSIY sayt, AKTUAL punktlar manbasi. `get_sayt_summa(mon, sun, "cash", "bmwbtbxa")`
  faqat shu hafta TRANZAKSIYASI BOR punktlarni qaytaradi. Sana UTC+5 → UTC ga o'giriladi (`_to_utc`).
- **139express** — `express_data.get('naxt', 0)` (faqat naqd, `total` EMAS).

## Punkt sinxronizatsiya mantiqi (joriy)
parcelpro = master ro'yxat. Har haftalik hisobotda (`bot.py: _sync_and_notify` + `send_weekly_report`):
1. parcelproda BOR, DB da YO'Q punkt → avtomatik qo'shiladi (`add_point_with_order`),
   admindan nom so'raladi (reply orqali).
2. Ko'ringan punktlarning `last_seen` yangilanadi, `inactive_asked=0`.
3. **2 ketma-ket hafta** kassa 0 (last_seen 2 haftadan eski) → admindan BIR MARTA so'raladi
   ("Ishlayaptimi? Ha/Yo'q"). `inactive_asked=1` qilinadi.
4. Admin "Ha" → `inactive_asked` reset (keyingi 2 haftada yana so'raydi). "Yo'q" → `active=0`.

## Haftalik hisobot tasdiqlash oqimi
1. Hisobot generatsiya → `reports/` ga saqlanadi, `weekly_reports` jadvaliga yoziladi (confirmed=0).
2. **Adminga** "✅ Tasdiqlash" tugmasi bilan yuboriladi. Kassirlarga "kutilmoqda" xabari.
3. Admin tasdiqlaganda (`confirm_report:` callback) → confirmed=1, fayl kassirlarga yuboriladi.
4. Tasdiqlangan hisobot QAYTA generatsiya QILINMAYDI — saqlangan fayl qayta yuboriladi
   (parcelpro statusi o'zgarsa ham hisobot o'zgarmaydi).
5. Punkt kodlarining tartibi DB `points.sort_order` orqali (`database.py: _code_rank`, `_POINT_ORDER`).

## Buyruqlar (bot)
- `/start` — rolga qarab menyu (admin/director/cashier/point_worker)
- `/haftalik` — hisobot olish (admin: tasdiqlash, kassir: tasdiqlangan faylni olish)
- `/tekshir` — joriy hafta punkt sinxronizatsiyasini qo'lda ishga tushirish
- `/chatid` — user/chat ID

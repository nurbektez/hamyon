# Telegram tuneli ishlamayapti — sabab va doimiy yechim

## Qisqacha

Mini App `WEBAPP_URL` orqali ochiladi, u esa bepul **cloudflared (`trycloudflare.com`)**
tunneliga ulangan. Bepul tunnelning kamchiliklari:

- har qayta ishga tushganda **URL o'zgaradi** — Telegramdagi eski tugma 502 qaytaradi;
- Cloudflare tez-tez **429 (rate limit)** beradi — tunnel umuman ko'tarilmaydi;
- kompyuter uxlab qolsa/internet uzilsa — tunnel o'ladi, watchdog qayta ko'targanida yana yangi URL.

Shu sababdan "tunnel ishlamayapti" muammosi qayta-qayta takrorlanadi. Bu tunnelni
"tuzatib" bo'lmaydi — uni **olib tashlash** kerak.

## Eng tez yechim — `PAGES_GA_ULASH.bat`

**Belgisi:** mini app ochilganda **Error 1033** (yoki 502 / "tunnel topilmadi") chiqadi.
Bu Cloudflare tunneli o'lgani — ilovaning o'zida muammo yo'q.

Repodagi `PAGES_GA_ULASH.bat` ni yuklab olib, bot papkasiga qo'ying va ustiga ikki marta bosing.
U `botni_pages_ga_ulash.ps1` ni chaqiradi (yonida bo'lmasa GitHub'dan o'zi yuklab oladi):

1. avval faqat **nima o'zgarishini ko'rsatadi** — hech narsa yozilmaydi;
2. `ha` deb tasdiqlagandan keyingina `.env` va `start_all.ps1` ni o'zgartiradi
   (har biridan `.bak-...` zaxira olinadi) va botni qayta ishga tushiradi.

Bot papkasi `C:\hamyon\miniapp_bot` da bo'lmasa ham topiladi — skript `.env`,
`start_all.ps1` yoki `bot.py` bor papkani o'zi qidiradi. Topilmasa, nima qilish
kerakligini ekranga yozadi.

Qolgan bo'limlar — nima uchun shunday va qo'lda qilish tartibi.

## Nima uchun tunnel endi kerak emas

`index.html` (Mini App frontendi) **hech qanday backendga so'rov yubormaydi**:

- ma'lumot bot yuborgan URL parametridan olinadi: `?d=<json>`;
- foydalanuvchi amallari botga `Telegram.WebApp.sendData()` orqali qaytadi (`web_app_data`).

Ya'ni `api.py` (port 8000) va tunnel Mini App uchun kerak emas. Frontend statik fayl —
uni **GitHub Pages** da bepul va doimiy HTTPS manzilda saqlash mumkin.

## Doimiy yechim — GitHub Pages

### 1. Pages — avtomatik yoqiladi

`.github/workflows/pages.yml` `main` ga push bo'lganda Pages ni o'zi yoqib, `index.html` ni
chiqaradi (pastdagi "Pages avtomatik chiqarish" bo'limiga qarang). Qo'lda qilish kerak emas.

> Agar Actions o'chirilgan bo'lsa, qo'lda: `Settings` → `Pages` →
> **Source: Deploy from a branch** → **Branch: `main`**, **Folder: `/ (root)`** → `Save`.

1–2 daqiqadan keyin manzil tayyor bo'ladi:

```
https://nurbektez.github.io/hamyon/
```

Bu manzil **hech qachon o'zgarmaydi**.

### 2. Botdagi `.env` ni yangilang

```env
WEBAPP_URL=https://nurbektez.github.io/hamyon/
```

### 3. `start_all.ps1` dan tunnelni olib tashlang

Watchdog endi faqat `bot.py` ni kuzatsa yetarli:

- `cloudflared` ni ishga tushirish qismini o'chiring;
- `cf.log` dan URL o'qib `.env` ni yangilaydigan qismini o'chiring;
- `localhost.run` fallback ham kerak emas.

> `api.py` boshqa maqsadda ishlatilayotgan bo'lsa, uni localhostda qoldiring — u
> Mini App uchun kerak emas.

### 4. Tekshiring

Botda `/start` → `💼 Hamyon` tugmasi → ilova ochilishi va balans ko'rinishi kerak.

## Muhim: tugma turi

`tg.sendData()` **faqat oddiy klaviatura tugmasidan** (`KeyboardButton(web_app=...)`)
ochilgan Mini Appda ishlaydi. Inline tugmadan yoki menyu tugmasidan ochilsa,
`sendData` xato beradi va amal botga bormaydi. Bot `💼 Hamyon` tugmasini
`ReplyKeyboardMarkup` ichida yuborishi shart.

## URL uzunligi

Barcha ma'lumot `?d=` ichida ketadi. Tranzaksiyalar ko'payib ketsa URL juda uzayadi va
Telegram tugmani yubormay qo'yishi mumkin. Shuning uchun botda `?d=` ga solinadigan
JSON ni cheklang, masalan:

- `transactions` — oxirgi 30 ta;
- `pending` — faqat `status='pending'` bo'lganlari;
- kerak bo'lmagan maydonlarni umuman qo'shmang.

Ilova base64 (`base64url`) bilan kodlangan payloadni ham tushunadi — uzunlikni
qisqartirish uchun ishlatsa bo'ladi.

## Frontendda tuzatilgan xatolar

Tunnel to'g'ri ishlaganda ham ilovani "ishlamayapti" qilib ko'rsatgan xatolar:

| Xato | Oqibati | Holati |
|------|---------|--------|
| `tg.setHeaderColor()` eski klientlarda exception tashlaydi | Butun skript to'xtaydi — ilova **bo'm-bo'sh** ochiladi | Tuzatildi (`try/catch`) |
| `decodeURIComponent()` ikkinchi marta chaqirilardi | Matnda `%` bo'lsa (masalan `50% chegirma`) — `URIError`, ma'lumot yo'qoladi | Tuzatildi (3 xil kodlash sinaladi) |
| `data.error` kelganda `applyData` → `loadData` → `applyData` | Cheksiz rekursiya → `RangeError`; xato `try/catch` da yutilardi, bot yuborgan sabab ko'rinmas edi | Tuzatildi |
| "Kirish kerak" xabari `setupUI()` dan oldin yozilardi | Xabar darhol qayta yozilib ketardi — sabab ko'rinmasdi | Tuzatildi |
| `tg.sendData()` xatosi ushlanmasdi | Amal botga bormaydi, foydalanuvchi buni bilmaydi | Tuzatildi (toast + 4096 bayt tekshiruvi) |

## Pages avtomatik chiqarish

`.github/workflows/pages.yml` qo'shildi: `main` ga har push bo'lganda `index.html` Pages ga
chiqariladi. Workflow `actions/configure-pages` ni `enablement: true` bilan chaqiradi —
Pages sozlanmagan bo'lsa, o'zi yoqadi. Ya'ni yuqoridagi 1-qadamni qo'lda bajarish shart emas:
PR `main` ga qo'shilishi bilan manzil ishlay boshlaydi.

Chiqqanini tekshirish: repo → `Actions` → "Deploy Mini App to Pages" → yashil bo'lsa tayyor.

## Brauzerda tekshirilgan natijalar

Headless Chromium (390x844) da `index.html` haqiqiy ma'lumot bilan yuklab ko'rildi:

| Holat | Eski kod | Yangi kod |
|-------|----------|-----------|
| oddiy urlencode | ishlaydi | ✅ balans va 4 ta amal ko'rinadi |
| ikki marta urlencode | ishlaydi | ✅ |
| `base64url` | o'qimaydi | ✅ |
| izohda `%` bor (`Arenda — 50% oldindan`) | ❌ balans **0**, ma'lumot yo'qoladi | ✅ balans 14 750 000 so'm |
| `{"error": "..."}` | ❌ sababi ko'rinmaydi, bo'sh ekran | ✅ ekranda "Foydalanuvchi topilmadi" |
| parametrsiz ochilsa | ❌ hech qanday izoh yo'q | ✅ "Botda '💼 Hamyon' tugmasini bosing" |

## Mini App ichidagi servis paneli

Bot chati jim qolsa, telefonning o'zidan tekshirish mumkin — ofis kompyuteri shart emas:

**Admin panel → 🔧 Bot servisi**

1. `.env` dagi `BOT_TOKEN` ni bir marta kiritib "Saqlash" bosiladi — token **faqat
   o'sha telefonda** (`localStorage`) qoladi, repoga ham, boshqa serverga ham
   yuborilmaydi; faqat `api.telegram.org` ga ketadi.
2. **Tekshirish** — bot tirikmi (`getMe`) va webhook eski tunnel manzilida
   qolmaganmi (`getWebhookInfo`) ko'rsatadi.
3. **Webhookni o'chirish** — `deleteWebhook`; bot polling'ga qaytadi.

Panel bot dasturining o'zini ishga tushira olmaydi: kompyuter o'chiq bo'lsa,
bot ham o'chiq bo'ladi. Ya'ni panel webhook muammosini yechadi, kompyuter
muammosini emas.

## Agar tunnel baribir kerak bo'lsa

Doimiy manzil uchun **nomli (named) Cloudflare tunnel** ishlating — o'z domeningizga
bog'lanadi va qayta ishga tushganda URL o'zgarmaydi:

```powershell
cloudflared tunnel login
cloudflared tunnel create hamyon
cloudflared tunnel route dns hamyon hamyon.<sizning-domeningiz>
cloudflared tunnel run --url http://localhost:8000 hamyon
```

Bu `trycloudflare.com` ning 429 va "URL har safar o'zgaradi" muammosini butunlay yopadi.

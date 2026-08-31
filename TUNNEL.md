# Telegram tuneli ishlamayapti — sabab va doimiy yechim

> Bot Telegramda umuman javob bermayotgan bo'lsa, muammo tunnelda emas —
> [BOT.md](BOT.md) ga qarang: bot kompyuteringizda ishlaydi va ishga tushirilgan
> bo'lishi kerak.

## Qisqacha

Mini App `WEBAPP_URL` orqali ochiladi, u esa bepul **cloudflared (`trycloudflare.com`)**
tunneliga ulangan. Bepul tunnelning kamchiliklari:

- har qayta ishga tushganda **URL o'zgaradi** — Telegramdagi eski tugma 502 qaytaradi;
- Cloudflare tez-tez **429 (rate limit)** beradi — tunnel umuman ko'tarilmaydi;
- kompyuter uxlab qolsa/internet uzilsa — tunnel o'ladi, watchdog qayta ko'targanida yana yangi URL.

Shu sababdan "tunnel ishlamayapti" muammosi qayta-qayta takrorlanadi. Bu tunnelni
"tuzatib" bo'lmaydi — uni **olib tashlash** kerak.

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

## Ilova endi sababni o'zi aytadi

Ilgari ma'lumot kelmasa ekranda faqat "Kirish kerak" yozilardi — nima buzilgani
noma'lum qolardi. Endi ilova ochilganda o'zini tekshiradi va aniq sababni ro'yxat
qilib chiqaradi:

| Aniqlangan holat | Ekranda |
|------------------|---------|
| manzil `*.trycloudflare.com` / `*.ngrok*` / `localhost.run` va h.k. | "Vaqtinchalik tunnel manzilidan ochildi" + `.env` da `WEBAPP_URL` ni Pages manziliga almashtirish ko'rsatmasi |
| Telegramdan tashqarida (oddiy brauzer) ochilgan | "Ilova faqat Telegram ichida ishlaydi" |
| `tg.initData` bo'sh — haqiqiy tugmadan emas, havoladan ochilgan | "Telegram initData yubormadi" |
| manzilda `?d=` yo'q | "Bot ma'lumot qo'shmagan" |
| bot `{"error": "..."}` yuborgan | botning o'z sababi |

Har holatda oxirgi qator bir xil: ilovani botdagi **oddiy klaviatura** tugmasi
(`💼 Hamyon`) orqali ochish kerak.

Ya'ni `WEBAPP_URL` hali ham eski tunnelga qarab tursa, buni endi taxmin qilish
shart emas — ilovaning o'zi shuni yozib beradi.

## Yana uchta jimgina xato tuzatildi

| Xato | Oqibati | Yechim |
|------|---------|--------|
| `sendAction()` xato qaytarganda ham balans/ro'yxat yangilanardi va "✅" toast chiqardi | Amal **botga bormaydi**, lekin ilovada bo'lgandek ko'rinadi — eng chalg'ituvchi holat | Har bir amal (`chiqim`, `konvert`, `rasxod`, `foydalanuvchi qo'shish`, `tasdiqlash`, `rad etish`, `o'chirish`) endi yuborish muvaffaqiyatli bo'lgandagina holatni yangilaydi |
| Rad etish sababi `prompt()` bilan so'ralardi, o'chirish `confirm()` bilan | Telegram WebView bu dialoglarni bloklaydi — tugma bosiladi, **hech narsa bo'lmaydi** | Rad etish uchun oddiy modal qo'shildi; o'chirishda `tg.showConfirm()` (eski klientlarda `confirm()` ga qaytadi) |
| Izoh/ism `innerHTML` ga qochirilmasdan qo'yilardi | Izohda `<` bo'lsa (masalan `narx < 100`) razmetka buziladi, ro'yxat umuman chiqmaydi | Barcha matnlar `esc()` dan o'tkaziladi |
| `.toast` da `white-space:nowrap`, kenglik cheklovi yo'q | Uzun xabar (aynan "Yuborilmadi — ... tugmasidan oching") ekrandan chiqib, **o'qib bo'lmasdi** | `max-width` va qatorga bo'linish qo'shildi |
| Diagnostika ustida `0 so'm` balans va ishlamaydigan Chiqim/Konvert tugmalari turardi | Foydalanuvchi pul yo'qolgan deb o'ylashi mumkin | Diagnostika ochiq bo'lganda sahifa mazmuni va pastki menyu yashiriladi |

Headless Chromium (390x844) da 19 ta tekshiruv o'tkazildi: oddiy payload, izohda `<`
va HTML teg, payloadsiz ochilish, `trycloudflare.com` xosti, `sendData` xato
bergan holat va muvaffaqiyatli holat, rad etish modali — barchasi o'tdi.

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

# Bot javob bermayapti — nima qilish kerak

## Avvalo: bot qayerda ishlaydi

| Qism | Qayerda turadi | Qachon ishlaydi |
|------|----------------|-----------------|
| Mini App sahifasi (`index.html`) | GitHub Pages | **doim** — bepul, o'chmaydi |
| Bot (`bot.py`) | **sizning kompyuteringizda** | faqat siz uni ishga tushirganingizda |

Shuning uchun Pages ga o'tganimiz botga javob bermaslikni tuzatmaydi. Telegramda
botga yozganingizda javob kelishi uchun kompyuteringizda `bot.py` **ishlab turishi**
shart.

## Yangi bot — `bot/`

Mavjud `bot.py` ni tuzatib bo'lmasa yoki u yo'q bo'lsa, shu repodagi
[`bot/`](bot/) papkadagi bot tayyor va Mini App bilan to'liq mos ishlaydi.
Faqat standart kutubxona — `pip install` kerak emas. Sozlash:
[`bot/README.md`](bot/README.md).

Eski botingizga va uning bazasiga **tegmaydi** — alohida papka, alohida baza.

## Avval: tekshiruv skripti

Nima buzilganini bilmasangiz, **`scripts/check-bot.bat`** ni ikki marta bosing. U hammasini
o'zi tekshiradi va yonida `hisobot.txt` faylini yozadi:

- `bot.py`, `.env`, `requirements.txt`, `bot.log` bormi;
- `.env` da `BOT_TOKEN` bormi, `WEBAPP_URL` hali tunnelga qarab turmaganmi;
- hozir nechta bot nusxasi ishlayapti (bir nechta bo'lsa — `409 Conflict`, bot jim qoladi);
- Telegram bilan aloqa: `getMe`, `getWebhookInfo`, kutilayotgan xabarlar soni, oxirgi xato;
- webhook o'rnatilgan bo'lsa — so'raydi va o'sha yerda tozalaydi;
- `bot.log` ning oxirgi 25 qatori;
- oxirida oddiy tilda **XULOSA**: nima buzilgan va nima qilish kerak.

Token `.env` dan o'zi o'qiladi va hisobotda **yashiriladi** — `hisobot.txt` ni bemalol
yuborsangiz bo'ladi.

## Ishga tushirish

`scripts/start-bot.bat` va `scripts/start-bot.ps1` ni `bot.py` turgan papkaga
ko'chiring va **`start-bot.bat` ni ikki marta bosing**.

Skript o'zi bajaradi:

1. `bot.py` ni topadi;
2. Python ni topadi (`py` / `python` / `python3`) — topilmasa nima qilishni aytadi;
3. `requirements.txt` bo'lsa kutubxonalarni o'rnatadi;
4. `.env` ni tekshiradi — `BOT_TOKEN` bormi, `WEBAPP_URL` hali tunnelga qarab
   turmaganmi (turgan bo'lsa ogohlantiradi);
5. `bot.py` ning boshqa nusxasi ishlayotganini tekshiradi — ikkita nusxa bir vaqtda
   ishlasa Telegram `409 Conflict` beradi va bot **javob bermay qo'yadi**;
6. Botni ishga tushiradi, yiqilsa 5 soniyadan keyin qayta ko'taradi, hamma chiqishni
   `bot.log` ga yozadi.

Uch marta ketma-ket darhol yiqilsa skript to'xtaydi va xatoni ekranda qoldiradi —
oyna o'zi yopilib ketmaydi, xatoni o'qib olishingiz mumkin.

> `start_all.ps1` ni hozircha ishlatmang: unda `cloudflared` qismi bor, u 429 olsa
> butun skript to'xtaydi va bot ham ko'tarilmaydi.

Oyna ochiq turishi kerak — **yopsangiz bot o'chadi**.

## Ishga tushmasa

| Xato | Sabab | Yechim |
|------|-------|--------|
| `Python topilmadi` | Python o'rnatilmagan yoki PATH da yo'q | python.org dan o'rnating, "Add python.exe to PATH" ni belgilang |
| `ModuleNotFoundError` | kutubxonalar yo'q | `pip install -r requirements.txt` |
| `.ps1 cannot be loaded ... execution policy` | Windows imzosiz skriptlarni bloklaydi | `.bat` orqali ishga tushiring — u buni chetlab o'tadi |
| `401 Unauthorized` | token noto'g'ri yoki bekor qilingan | BotFather → `/token`, `.env` ni yangilang |
| Bot ishlayapti, lekin javob yo'q | webhook o'rnatilgan (polling hech narsa olmaydi) | `getWebhookInfo` bilan tekshiring, `deleteWebhook` bilan tozalang |
| Bot ishlayapti, xato yo'q, javob yo'q | siz bazada ro'yxatdan o'tmagansiz — rolga bog'langan handler jim qaytadi | DB da o'z Telegram ID'ingiz `admin` bilan turganini tekshiring |

Telegram tomonidagi holatni bot **o'chiq turganda** tekshirish:

```powershell
$t = "<BOT_TOKEN>"
irm "https://api.telegram.org/bot$t/getWebhookInfo" | ConvertTo-Json -Depth 5
irm "https://api.telegram.org/bot$t/getUpdates"     | ConvertTo-Json -Depth 5
```

- `url` bo'sh emas → webhook o'rnatilgan, polling ishlamaydi;
- `getUpdates` da xabaringiz ko'rinadi → Telegram tomoni soz, muammo bot kodida;
- `pending_update_count` o'sib boryapti → xabarlar kelyapti, bot ularni o'qimayapti.

Tokenni hech kimga yubormang.

## Kompyuter o'chganda ham ishlashi uchun — VPS

Bot kompyuteringizda turgani uchun kompyuter o'chsa yoki uxlasa javob bermaydi.
Doimiy ishlashi uchun uni arzon Ubuntu VPS ga ko'chirish kerak (oyiga ~$4).

```bash
sudo adduser --system --group --home /opt/hamyon hamyon
sudo -u hamyon git clone <bot-repo> /opt/hamyon
cd /opt/hamyon
sudo -u hamyon python3 -m venv .venv
sudo -u hamyon .venv/bin/pip install -r requirements.txt
sudo -u hamyon nano .env      # BOT_TOKEN va WEBAPP_URL
```

`/etc/systemd/system/hamyon.service`:

```ini
[Unit]
Description=TezFast Hamyon Telegram bot
After=network-online.target

[Service]
User=hamyon
WorkingDirectory=/opt/hamyon
EnvironmentFile=/opt/hamyon/.env
ExecStart=/opt/hamyon/.venv/bin/python -u bot.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now hamyon
sudo systemctl status hamyon
journalctl -u hamyon -f          # loglarni jonli ko'rish
```

`Restart=always` — bot yiqilsa systemd qayta ko'taradi; server qayta yuklansa ham
o'zi ishga tushadi. Watchdog skript kerak emas.

> `EnvironmentFile` oddiy `KALIT=qiymat` qatorlarini kutadi — qiymatni tirnoqqa
> olmang va `export` yozmang.
>
> Botni VPS da ishga tushirgach, kompyuterdagi nusxasini **yoping** — ikkita nusxa
> bir vaqtda polling qilsa Telegram `409 Conflict` beradi.

`WEBAPP_URL` VPS da ham o'sha doimiy manzil bo'ladi:

```env
WEBAPP_URL=https://nurbektez.github.io/hamyon/
```

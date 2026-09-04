# TezFast Hamyon — bot

Mini App (`index.html`) bilan to'liq mos ishlaydigan Telegram bot.
**Faqat Python standart kutubxonasi** ishlatiladi — `pip install` kerak emas,
kutubxona versiyasi ziddiyati bo'lmaydi.

## Ishga tushirish

1. `.env.example` dan nusxa oling va `.env` deb nomlang;
2. ichiga BotFather bergan tokenni yozing:

```
BOT_TOKEN=123456789:AA...
WEBAPP_URL=https://nurbektez.github.io/hamyon/
```

3. ishga tushiring:

```
python bot.py
```

Telegramda botga `/start` yozing. **`/start` bosgan birinchi odam avtomatik admin
bo'ladi** — shuning uchun birinchi bo'lib o'zingiz yozing. (Yoki `.env` da
`ADMIN_ID=` ga o'z Telegram ID ingizni qo'ying; ID ni `/id` buyrug'i ko'rsatadi.)

Ma'lumot shu papkadagi `hamyon.db` da saqlanadi — birinchi ishga tushirishda
o'zi yaratiladi.

## Buyruqlar

| Buyruq | Kim | Nima qiladi |
|--------|-----|-------------|
| `/start` | hamma | Mini App tugmasini yangilaydi |
| `/id` | hamma | Telegram ID ni ko'rsatadi |
| `/balans` | hamma | balansni matn bilan chiqaradi |
| `/punkt P01 Chorsu` | admin | punkt qo'shadi |
| `+500000 izoh` | admin, director, kassir | kirim yozadi |

Qolgan hamma narsa — chiqim, konvertatsiya, rasxod yuborish va tasdiqlash,
foydalanuvchi qo'shish — `💼 Hamyon` tugmasi orqali ochiladigan ilovada.

## Muhim: tugma turi

Ilova **oddiy klaviatura** tugmasidan ochiladi (`ReplyKeyboardMarkup` +
`web_app`). Telegram `sendData()` ni faqat shunday ochilgan ilovada ruxsat
beradi — inline tugma yoki menyu tugmasidan ochilsa, ilovadagi amallar botga
umuman qaytmaydi. Bot tugmani to'g'ri turda yuboradi.

Shu sababdan tugma **shaxsiy chatda** ishlaydi; guruhda Mini App tugmasi
ko'rsatilmaydi.

## Ma'lumot qanday uzatiladi

Bot har safar klaviatura yuborganda balans va tarixni JSON qilib tugma
manziliga qo'shadi (`?d=...`). Ilova hech qanday serverga so'rov yubormaydi —
shuning uchun tunnel ham, `api.py` ham kerak emas.

URL uzunligi cheklangan, shuning uchun `?d=` ga faqat oxirgi 20 ta amal
solinadi.

## Rollar

| Rol | Nima qila oladi |
|-----|-----------------|
| `admin` | hammasi + foydalanuvchi va punkt boshqaruvi |
| `director` | gazna amallari + rasxodlarni tasdiqlash |
| `cashier` | kirim va gazna amallari |
| `point_worker` | rasxod yuboradi, tasdiqlanishini kutadi |

## Doimiy ishlashi uchun

Kompyuter o'chsa bot ham to'xtaydi. VPS ga ko'chirish yo'riqnomasi —
`../BOT.md` dagi systemd bo'limida.

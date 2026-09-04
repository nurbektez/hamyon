#!/usr/bin/env python3
"""
TezFast Hamyon — Telegram bot.

Faqat Python standart kutubxonasi ishlatiladi: pip install kerak emas,
kutubxona versiyasi ziddiyati bo'lmaydi.

Ishga tushirish:
    python bot.py

Yonidagi .env fayldan o'qiladi:
    BOT_TOKEN=123456:ABC...          (majburiy)
    WEBAPP_URL=https://nurbektez.github.io/hamyon/
    ADMIN_ID=123456789               (ixtiyoriy; berilmasa /start bosgan
                                      birinchi odam admin bo'ladi)

Ma'lumot shu papkadagi hamyon.db (SQLite) da saqlanadi.
"""

import json
import os
import sqlite3
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime

BASE = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE, "hamyon.db")
API = "https://api.telegram.org/bot{token}/{method}"

ROLES = ("admin", "director", "cashier", "point_worker")
ACCOUNTS = ("som", "usd", "karta")
ACC_NAME = {"som": "so'm", "usd": "dollar", "karta": "karta"}


# ─────────────────────────── .env ───────────────────────────

def load_env():
    """.env ni oddiy KALIT=qiymat sifatida o'qiydi (tashqi kutubxonasiz)."""
    path = os.path.join(BASE, ".env")
    cfg = {}
    if os.path.exists(path):
        with open(path, encoding="utf-8-sig") as f:
            for raw in f:
                line = raw.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                key, _, val = line.partition("=")
                cfg[key.strip()] = val.strip().strip('"').strip("'")
    # Muhit o'zgaruvchisi .env dan ustun turadi (systemd/VPS uchun qulay)
    for key in ("BOT_TOKEN", "WEBAPP_URL", "ADMIN_ID"):
        if os.environ.get(key):
            cfg[key] = os.environ[key]
    return cfg


CFG = load_env()
TOKEN = CFG.get("BOT_TOKEN", "").strip()
WEBAPP_URL = CFG.get("WEBAPP_URL", "https://nurbektez.github.io/hamyon/").strip()


def log(*parts):
    print(datetime.now().strftime("%H:%M:%S"), *parts, flush=True)


# ─────────────────────── Telegram API ───────────────────────

def api(method, **params):
    """Telegram API ga so'rov. Xatoda ham dict qaytaradi — hech qachon otmaydi."""
    payload = {}
    for key, val in params.items():
        if val is None:
            continue
        payload[key] = json.dumps(val, ensure_ascii=False) if isinstance(val, (dict, list)) else val
    data = urllib.parse.urlencode(payload).encode()
    req = urllib.request.Request(API.format(token=TOKEN, method=method), data=data)
    try:
        with urllib.request.urlopen(req, timeout=65) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        body = e.read().decode(errors="replace")
        try:
            return json.loads(body)
        except ValueError:
            return {"ok": False, "description": "HTTP %s: %s" % (e.code, body[:200])}
    except Exception as e:                                    # tarmoq uzilishi va h.k.
        return {"ok": False, "description": "%s: %s" % (type(e).__name__, e)}


def say(chat_id, text, keyboard=None):
    return api("sendMessage", chat_id=chat_id, text=text,
               parse_mode="HTML", reply_markup=keyboard)


# ───────────────────────── Baza ─────────────────────────────

def db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    with db() as conn:
        conn.executescript("""
        CREATE TABLE IF NOT EXISTS users(
            tg_id INTEGER PRIMARY KEY, full_name TEXT, role TEXT,
            point_code TEXT, active INTEGER DEFAULT 1);
        CREATE TABLE IF NOT EXISTS points(
            code TEXT PRIMARY KEY, name TEXT, active INTEGER DEFAULT 1);
        CREATE TABLE IF NOT EXISTS balances(
            acc TEXT PRIMARY KEY, amount REAL DEFAULT 0);
        CREATE TABLE IF NOT EXISTS transactions(
            id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT, acc TEXT, acc_to TEXT,
            amount REAL, amount_to REAL, comment TEXT, point_code TEXT,
            tg_id INTEGER, created TEXT);
        CREATE TABLE IF NOT EXISTS expenses(
            id INTEGER PRIMARY KEY AUTOINCREMENT, tg_id INTEGER, point_code TEXT,
            category TEXT, currency TEXT, amount REAL, comment TEXT,
            status TEXT DEFAULT 'pending', reject_note TEXT, created TEXT);
        CREATE TABLE IF NOT EXISTS state(key TEXT PRIMARY KEY, value TEXT);
        """)
        for acc in ACCOUNTS:
            conn.execute("INSERT OR IGNORE INTO balances(acc, amount) VALUES(?, 0)", (acc,))


def get_state(key, default=None):
    with db() as conn:
        row = conn.execute("SELECT value FROM state WHERE key=?", (key,)).fetchone()
    return row["value"] if row else default


def set_state(key, value):
    with db() as conn:
        conn.execute("INSERT OR REPLACE INTO state(key, value) VALUES(?, ?)", (key, str(value)))


def get_user(tg_id):
    with db() as conn:
        return conn.execute("SELECT * FROM users WHERE tg_id=? AND active=1", (tg_id,)).fetchone()


def ensure_user(tg_id, name):
    """Foydalanuvchini ro'yxatdan o'tkazadi. Baza bo'sh bo'lsa birinchi odam admin."""
    user = get_user(tg_id)
    if user:
        return user
    forced_admin = str(CFG.get("ADMIN_ID", "")).strip()
    with db() as conn:
        count = conn.execute("SELECT COUNT(*) c FROM users").fetchone()["c"]
        if count == 0 or forced_admin == str(tg_id):
            conn.execute(
                "INSERT OR REPLACE INTO users(tg_id, full_name, role, point_code, active)"
                " VALUES(?, ?, 'admin', NULL, 1)", (tg_id, name))
            log("Birinchi foydalanuvchi admin qilindi:", tg_id, name)
    return get_user(tg_id)


def now_str():
    return datetime.now().strftime("%d.%m %H:%M")


def money(amount, acc="som"):
    n = int(round(amount or 0))
    s = "{:,}".format(n).replace(",", " ")
    return "$ " + s if acc == "usd" else s + " so'm"


# ──────────────────── Mini App uchun payload ────────────────

def build_payload(user):
    """index.html kutadigan aynan shu shakldagi ma'lumot."""
    tg_id = user["tg_id"]
    role = user["role"]
    with db() as conn:
        bal = {r["acc"]: r["amount"] for r in conn.execute("SELECT * FROM balances")}

        stats = {}
        for acc in ACCOUNTS:
            for kind in ("kirim", "chiqim"):
                row = conn.execute(
                    "SELECT COALESCE(SUM(amount), 0) s FROM transactions"
                    " WHERE type=? AND acc=?", (kind, acc)).fetchone()
                stats["%s_%s" % (kind, acc)] = row["s"]

        # URL uzunligi cheklangan — oxirgi 20 ta amal yetarli
        tx = []
        for r in conn.execute("SELECT * FROM transactions ORDER BY id DESC LIMIT 20"):
            item = {"type": r["type"], "amount": r["amount"], "date": r["created"]}
            if r["type"] == "konvert":
                item.update(accFrom=r["acc"], accTo=r["acc_to"], amountTo=r["amount_to"])
            else:
                item["acc"] = r["acc"]
                if r["comment"]:
                    item["comment"] = r["comment"]
                if r["point_code"]:
                    item["pointCode"] = r["point_code"]
            tx.append(item)

        def expense_rows(sql, args=()):
            out = []
            for r in conn.execute(sql, args):
                worker = conn.execute(
                    "SELECT full_name FROM users WHERE tg_id=?", (r["tg_id"],)).fetchone()
                out.append({
                    "id": r["id"], "category": r["category"], "currency": r["currency"],
                    "amount": r["amount"], "comment": r["comment"] or "",
                    "status": r["status"], "date": r["created"],
                    "pointCode": r["point_code"] or "", "rejectNote": r["reject_note"] or "",
                    "workerName": worker["full_name"] if worker else "",
                })
            return out

        pending, users, points, mine = [], [], [], []
        if role in ("director", "admin"):
            pending = expense_rows(
                "SELECT * FROM expenses ORDER BY id DESC LIMIT 30")
        if role == "point_worker":
            mine = expense_rows(
                "SELECT * FROM expenses WHERE tg_id=? ORDER BY id DESC LIMIT 20", (tg_id,))
        if role == "admin":
            users = [{"id": r["tg_id"], "name": r["full_name"], "role": r["role"],
                      "point": r["point_code"] or "", "active": r["active"]}
                     for r in conn.execute("SELECT * FROM users WHERE active=1")]
        points = [{"code": r["code"], "name": r["name"], "active": r["active"]}
                  for r in conn.execute("SELECT * FROM points")]

    return {
        "role": role,
        "fullName": user["full_name"] or "",
        "pointCode": user["point_code"] or "",
        "som": bal.get("som", 0), "usd": bal.get("usd", 0), "karta": bal.get("karta", 0),
        "stats": stats, "transactions": tx,
        "pending": pending, "myExpenses": mine, "users": users, "points": points,
    }


def webapp_url(user):
    data = json.dumps(build_payload(user), ensure_ascii=False, separators=(",", ":"))
    sep = "&" if "?" in WEBAPP_URL else "?"
    return WEBAPP_URL + sep + "d=" + urllib.parse.quote(data, safe="")


def keyboard_for(user):
    """
    Mini App ni ochadigan ODDIY KLAVIATURA tugmasi.
    sendData() faqat shu turdagi tugmadan ochilgan ilovada ishlaydi —
    inline tugma yoki menyu tugmasidan ochilsa amallar botga qaytmaydi.
    """
    return {
        "keyboard": [[{"text": "💼 Hamyon", "web_app": {"url": webapp_url(user)}}]],
        "resize_keyboard": True,
    }


# ───────────────── Mini App dan kelgan amallar ──────────────

def apply_action(user, data):
    """Mini App yuborgan amalni bazaga yozadi. (matn, muvaffaqiyatmi) qaytaradi."""
    action = data.get("action")
    tg_id = user["tg_id"]
    role = user["role"]

    def need(*roles):
        return role in roles

    with db() as conn:
        if action == "chiqim":
            if not need("admin", "director", "cashier"):
                return "Bu amal uchun huquqingiz yo'q.", False
            acc = data.get("acc", "som")
            amount = float(data.get("amount") or 0)
            if acc not in ACCOUNTS or amount <= 0:
                return "Noto'g'ri miqdor yoki hisob.", False
            have = conn.execute("SELECT amount FROM balances WHERE acc=?", (acc,)).fetchone()["amount"]
            if have < amount:
                return "Mablag' yetarli emas: %s bor." % money(have, acc), False
            conn.execute("UPDATE balances SET amount=amount-? WHERE acc=?", (amount, acc))
            conn.execute(
                "INSERT INTO transactions(type, acc, amount, comment, tg_id, created)"
                " VALUES('chiqim', ?, ?, ?, ?, ?)",
                (acc, amount, data.get("comment", ""), tg_id, now_str()))
            return "➖ Chiqim: %s\n📝 %s" % (money(amount, acc), data.get("comment", "")), True

        if action == "konvert":
            if not need("admin", "director", "cashier"):
                return "Bu amal uchun huquqingiz yo'q.", False
            af, at = data.get("acc_from"), data.get("acc_to")
            fa = float(data.get("amount_from") or 0)
            ta = float(data.get("amount_to") or 0)
            if af not in ACCOUNTS or at not in ACCOUNTS or fa <= 0 or ta <= 0:
                return "Konvert ma'lumoti noto'g'ri.", False
            have = conn.execute("SELECT amount FROM balances WHERE acc=?", (af,)).fetchone()["amount"]
            if have < fa:
                return "Mablag' yetarli emas: %s bor." % money(have, af), False
            conn.execute("UPDATE balances SET amount=amount-? WHERE acc=?", (fa, af))
            conn.execute("UPDATE balances SET amount=amount+? WHERE acc=?", (ta, at))
            conn.execute(
                "INSERT INTO transactions(type, acc, acc_to, amount, amount_to, tg_id, created)"
                " VALUES('konvert', ?, ?, ?, ?, ?, ?)", (af, at, fa, ta, tg_id, now_str()))
            return "💱 %s → %s" % (money(fa, af), money(ta, at)), True

        if action == "add_expense":
            amount = float(data.get("amount") or 0)
            if amount <= 0:
                return "Miqdor noto'g'ri.", False
            conn.execute(
                "INSERT INTO expenses(tg_id, point_code, category, currency, amount,"
                " comment, status, created) VALUES(?, ?, ?, ?, ?, ?, 'pending', ?)",
                (tg_id, user["point_code"], data.get("category", "boshqa"),
                 data.get("currency", "som"), amount, data.get("comment", ""), now_str()))
            notify_approvers(user, data, amount)
            return "📤 Rasxod director ga yuborildi: %s" % money(amount, data.get("currency", "som")), True

        if action in ("approve_expense", "reject_expense"):
            if not need("admin", "director"):
                return "Bu amal uchun huquqingiz yo'q.", False
            exp_id = data.get("exp_id")
            row = conn.execute("SELECT * FROM expenses WHERE id=?", (exp_id,)).fetchone()
            if not row:
                return "Rasxod topilmadi.", False
            if row["status"] != "pending":
                return "Bu rasxod allaqachon ko'rib chiqilgan.", False
            if action == "approve_expense":
                acc = row["currency"] if row["currency"] in ACCOUNTS else "som"
                conn.execute("UPDATE balances SET amount=amount-? WHERE acc=?", (row["amount"], acc))
                conn.execute(
                    "INSERT INTO transactions(type, acc, amount, comment, point_code, tg_id, created)"
                    " VALUES('chiqim', ?, ?, ?, ?, ?, ?)",
                    (acc, row["amount"], row["comment"], row["point_code"], row["tg_id"], now_str()))
                conn.execute("UPDATE expenses SET status='approved' WHERE id=?", (exp_id,))
                notify(row["tg_id"], "✅ Rasxodingiz tasdiqlandi: %s" % money(row["amount"], acc))
                return "✅ Tasdiqlandi: %s" % money(row["amount"], acc), True
            note = data.get("note", "")
            conn.execute("UPDATE expenses SET status='rejected', reject_note=? WHERE id=?", (note, exp_id))
            notify(row["tg_id"], "❌ Rasxodingiz rad etildi.\nSabab: %s" % note)
            return "❌ Rad etildi.", True

        if action == "add_user":
            if not need("admin"):
                return "Faqat admin foydalanuvchi qo'sha oladi.", False
            new_id = data.get("telegram_id")
            new_role = data.get("role")
            if not new_id or new_role not in ROLES:
                return "Foydalanuvchi ma'lumoti noto'g'ri.", False
            conn.execute(
                "INSERT OR REPLACE INTO users(tg_id, full_name, role, point_code, active)"
                " VALUES(?, ?, ?, ?, 1)",
                (int(new_id), data.get("full_name", ""), new_role, data.get("point_code")))
            notify(int(new_id), "✅ Sizga <b>%s</b> roli berildi.\n/start bosing." % new_role)
            return "✅ Qo'shildi: %s (%s)" % (data.get("full_name", ""), new_role), True

        if action == "del_user":
            if not need("admin"):
                return "Faqat admin o'chira oladi.", False
            del_id = int(data.get("telegram_id") or 0)
            if del_id == tg_id:
                return "O'zingizni o'chira olmaysiz.", False
            conn.execute("UPDATE users SET active=0 WHERE tg_id=?", (del_id,))
            return "🗑 O'chirildi.", True

    return "Noma'lum amal: %s" % action, False


def notify(tg_id, text):
    if tg_id:
        say(tg_id, text)


def notify_approvers(user, data, amount):
    with db() as conn:
        rows = conn.execute(
            "SELECT tg_id FROM users WHERE role IN ('director','admin') AND active=1").fetchall()
    for r in rows:
        notify(r["tg_id"], "⏳ Yangi rasxod\n👤 %s\n💰 %s\n📝 %s" % (
            user["full_name"], money(amount, data.get("currency", "som")), data.get("comment", "")))


# ──────────────────── Matnli buyruqlar ──────────────────────

HELP = (
    "<b>TezFast Hamyon</b>\n\n"
    "💼 <b>Hamyon</b> tugmasi — ilovani ochadi (balans, tarix, amallar).\n\n"
    "Buyruqlar:\n"
    "/start — ilova tugmasini yangilash\n"
    "/id — Telegram ID ingizni ko'rish\n"
    "/balans — balansni matn bilan ko'rish\n"
    "/punkt KOD Nomi — punkt qo'shish (admin)\n"
    "+50000 izoh — kirim yozish (admin/kassir/director)\n"
)


def handle_text(user, chat_id, text):
    cmd = text.strip()
    low = cmd.lower()

    if low.startswith("/start"):
        say(chat_id, "Assalomu alaykum, <b>%s</b>!\nRolingiz: <b>%s</b>\n\n"
                     "Pastdagi <b>💼 Hamyon</b> tugmasini bosing." % (
                         user["full_name"], user["role"]), keyboard_for(user))
        return
    if low.startswith("/help"):
        say(chat_id, HELP, keyboard_for(user))
        return
    if low.startswith("/id"):
        say(chat_id, "Sizning Telegram ID: <code>%s</code>" % user["tg_id"])
        return
    if low.startswith("/balans"):
        with db() as conn:
            bal = {r["acc"]: r["amount"] for r in conn.execute("SELECT * FROM balances")}
        say(chat_id, "💵 So'm: <b>%s</b>\n💲 Dollar: <b>%s</b>\n💳 Karta: <b>%s</b>" % (
            money(bal.get("som", 0)), money(bal.get("usd", 0), "usd"), money(bal.get("karta", 0))))
        return
    if low.startswith("/punkt"):
        if user["role"] != "admin":
            say(chat_id, "Faqat admin punkt qo'sha oladi.")
            return
        parts = cmd.split(None, 2)
        if len(parts) < 3:
            say(chat_id, "Foydalanish: <code>/punkt P01 Chorsu</code>")
            return
        with db() as conn:
            conn.execute("INSERT OR REPLACE INTO points(code, name, active) VALUES(?, ?, 1)",
                         (parts[1].upper(), parts[2]))
        say(chat_id, "🏪 Punkt qo'shildi: %s — %s" % (parts[1].upper(), parts[2]),
            keyboard_for(user))
        return

    if cmd.startswith("+"):
        if user["role"] not in ("admin", "director", "cashier"):
            say(chat_id, "Kirim yozish huquqingiz yo'q.")
            return
        body = cmd[1:].strip().replace(" ", " ")
        num, _, comment = body.partition(" ")
        try:
            amount = float(num.replace(" ", "").replace(",", "."))
        except ValueError:
            say(chat_id, "Foydalanish: <code>+500000 Chorsu punkti</code>")
            return
        if amount <= 0:
            say(chat_id, "Miqdor noldan katta bo'lishi kerak.")
            return
        with db() as conn:
            conn.execute("UPDATE balances SET amount=amount+? WHERE acc='som'", (amount,))
            conn.execute(
                "INSERT INTO transactions(type, acc, amount, comment, point_code, tg_id, created)"
                " VALUES('kirim', 'som', ?, ?, ?, ?, ?)",
                (amount, comment, user["point_code"], user["tg_id"], now_str()))
        say(chat_id, "➕ Kirim: <b>%s</b>\n%s" % (money(amount), comment), keyboard_for(user))
        return

    say(chat_id, HELP, keyboard_for(user))


# ───────────────────────── Asosiy sikl ──────────────────────

def handle_update(upd):
    msg = upd.get("message") or upd.get("edited_message")
    if not msg:
        return
    chat_id = msg["chat"]["id"]
    frm = msg.get("from") or {}
    tg_id = frm.get("id")
    name = (" ".join(x for x in (frm.get("first_name"), frm.get("last_name")) if x)
            or frm.get("username") or str(tg_id))

    user = ensure_user(tg_id, name)
    if not user:
        # Ro'yxatda yo'q — JIM QOLMAYMIZ, sababini aytamiz
        say(chat_id, "Siz ro'yxatdan o'tmagansiz.\nAdminga shu ID ni bering: "
                     "<code>%s</code>" % tg_id)
        log("Ro'yxatda yo'q foydalanuvchi:", tg_id, name)
        return

    wad = msg.get("web_app_data")
    if wad:
        try:
            data = json.loads(wad.get("data") or "{}")
        except ValueError:
            say(chat_id, "Ilovadan noto'g'ri ma'lumot keldi.")
            return
        log("web_app_data:", data.get("action"), "dan", tg_id)
        try:
            text, ok = apply_action(user, data)
        except Exception as e:                                # bitta amal butun botni yiqitmasin
            log("apply_action XATO:", repr(e))
            text, ok = "Xatolik: %s" % e, False
        say(chat_id, text, keyboard_for(get_user(tg_id)))
        return

    if msg.get("text"):
        handle_text(user, chat_id, msg["text"])


def main():
    if not TOKEN:
        print("XATO: .env da BOT_TOKEN yo'q. .env.example ga qarang.")
        sys.exit(1)

    init_db()
    me = api("getMe")
    if not me.get("ok"):
        print("XATO: Telegram bilan aloqa yo'q — %s" % me.get("description"))
        print("  401 bo'lsa token noto'g'ri; tarmoq xatosi bo'lsa internet/antivirus to'sayapti.")
        sys.exit(1)
    log("Bot ishga tushdi: @%s" % me["result"]["username"])
    log("WEBAPP_URL:", WEBAPP_URL)
    if any(x in WEBAPP_URL for x in ("trycloudflare", "ngrok", "localhost.run", "loca.lt")):
        log("OGOHLANTIRISH: WEBAPP_URL vaqtinchalik tunnelda — Mini App ochilmasligi mumkin.")

    # Polling ishlashi uchun webhook bo'lmasligi kerak
    api("deleteWebhook")

    offset = int(get_state("offset", 0) or 0)
    while True:
        res = api("getUpdates", offset=offset, timeout=30, allowed_updates=["message"])
        if not res.get("ok"):
            desc = str(res.get("description", ""))
            if "Conflict" in desc:
                print("XATO: botning boshqa nusxasi ham ishlayapti (409 Conflict).")
                print("  Barcha python jarayonlarini yopib, bittasini ishga tushiring.")
                sys.exit(1)
            log("getUpdates xato:", desc)
            time.sleep(5)
            continue
        for upd in res.get("result", []):
            offset = upd["update_id"] + 1
            try:
                handle_update(upd)
            except Exception as e:
                log("handle_update XATO:", repr(e))
        set_state("offset", offset)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        log("To'xtatildi.")

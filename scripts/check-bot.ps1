# TezFast Hamyon — bot nega javob bermayotganini aniqlaydigan tekshiruv skripti
#
# Ishlatish: check-bot.bat ni IKKI MARTA bosing.
#
# Skript hamma tekshiruvni o'zi bajaradi va yonida "hisobot.txt" faylini yaratadi.
# BOT_TOKEN .env dan avtomat o'qiladi va hisobotda YASHIRILADI — faylni bemalol
# yuborsangiz bo'ladi.

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$lines = New-Object System.Collections.Generic.List[string]
$token = $null

function Hide-Token($text) {
  $t = [string]$text
  if ($token -and $t) { $t = $t -replace [regex]::Escape($token), '<TOKEN-YASHIRILDI>' }
  return $t
}
function Add-Line($s, $color = 'Gray') {
  $s = Hide-Token $s
  $lines.Add($s)
  Write-Host $s -ForegroundColor $color
}
function Add-Head($s) {
  Add-Line ''
  Add-Line "── $s ──" Cyan
}

Add-Line "TezFast Hamyon — bot tekshiruvi" White
Add-Line "Sana: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Add-Line "Kompyuter: $env:COMPUTERNAME / $env:OS"

# ── 1. Papka va bot.py ──
Add-Head "1. Fayllar"
$dir = $PSScriptRoot
$bot = $null
foreach ($c in @("$dir\bot.py", "$dir\..\bot.py")) {
  if (Test-Path $c) { $bot = (Resolve-Path $c).Path; break }
}
if ($bot) {
  $root = Split-Path $bot -Parent
  Add-Line "bot.py topildi: $bot" Green
} else {
  $root = $dir
  Add-Line "bot.py TOPILMADI. Skript qaralgan papka: $dir" Red
  Add-Line "Bu skriptni bot.py turgan papkaga qo'ying." Yellow
}

foreach ($f in @('.env', 'requirements.txt', 'start_all.ps1', 'bot.log')) {
  $p = Join-Path $root $f
  if (Test-Path $p) {
    $sz = (Get-Item $p).Length
    Add-Line ("{0,-18} bor ({1} bayt)" -f $f, $sz)
  } else {
    Add-Line ("{0,-18} yo'q" -f $f) Yellow
  }
}

# ── 2. .env ──
Add-Head "2. .env sozlamalari"
$envFile = Join-Path $root '.env'
$webappUrl = $null
if (Test-Path $envFile) {
  $envText = Get-Content $envFile -Raw
  if ($envText -match '(?m)^\s*BOT_TOKEN\s*=\s*"?([^"\r\n]+)"?\s*$') {
    $token = $Matches[1].Trim()
    $botId = ($token -split ':')[0]
    Add-Line "BOT_TOKEN  : bor (bot id $botId, uzunligi $($token.Length)) — sirli qismi ko'rsatilmaydi" Green
  } else {
    Add-Line "BOT_TOKEN  : TOPILMADI — bot ishga tushmaydi" Red
  }
  if ($envText -match '(?m)^\s*WEBAPP_URL\s*=\s*"?([^"\r\n]+)"?\s*$') {
    $webappUrl = $Matches[1].Trim()
    Add-Line "WEBAPP_URL : $webappUrl"
    if ($webappUrl -match 'trycloudflare|ngrok|localhost\.run|lhr\.life|loca\.lt|serveo') {
      Add-Line "  ^ vaqtinchalik TUNNEL manzili — har safar o'zgaradi, Mini App ochilmaydi" Yellow
      Add-Line "  ^ tavsiya: WEBAPP_URL=https://nurbektez.github.io/hamyon/" Yellow
    }
  } else {
    Add-Line "WEBAPP_URL : yo'q" Yellow
  }
} else {
  Add-Line ".env fayl yo'q — token o'qib bo'lmadi, Telegram tekshiruvi o'tkazilmaydi" Red
}

# ── 3. Ishlab turgan jarayonlar ──
Add-Head "3. Ishlab turgan bot nusxalari"
$procs = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
           Where-Object { $_.Name -match '^pythonw?\.exe$' -and $_.CommandLine -like '*bot.py*' })
Add-Line "Topildi: $($procs.Count) ta"
foreach ($p in $procs) {
  Add-Line "  PID $($p.ProcessId): $($p.CommandLine)"
}
if ($procs.Count -eq 0) { Add-Line "  -> Bot ISHLAMAYAPTI. Javob bermasligining sababi shu bo'lishi mumkin." Red }
if ($procs.Count -gt 1) { Add-Line "  -> Bir nechta nusxa! Telegram 409 Conflict beradi, bot jim qoladi." Red }

# ── 4. Telegram ──
Add-Head "4. Telegram bilan aloqa"
if (-not $token) {
  Add-Line "Token yo'q — bu bo'lim o'tkazib yuborildi." Yellow
} else {
  function Call-TG($method) {
    try {
      $r = Invoke-RestMethod -Uri "https://api.telegram.org/bot$token/$method" -TimeoutSec 20 -ErrorAction Stop
      return @{ ok = $true; data = $r }
    } catch {
      $body = $null
      try { $body = $_.ErrorDetails.Message } catch {}
      return @{ ok = $false; err = $_.Exception.Message; body = $body }
    }
  }

  $me = Call-TG 'getMe'
  if ($me.ok) {
    Add-Line "getMe: OK — @$($me.data.result.username) ($($me.data.result.first_name))" Green
  } else {
    Add-Line "getMe: XATO — $($me.err)" Red
    if ($me.body) { Add-Line "  javob: $($me.body)" Red }
    Add-Line "  -> 401 bo'lsa token noto'g'ri; tarmoq xatosi bo'lsa internet/antivirus to'sayapti." Yellow
  }

  $wh = Call-TG 'getWebhookInfo'
  if ($wh.ok) {
    $w = $wh.data.result
    if ([string]::IsNullOrWhiteSpace($w.url)) {
      Add-Line "webhook: o'rnatilmagan (polling uchun to'g'ri)" Green
    } else {
      Add-Line "webhook: O'RNATILGAN -> $($w.url)" Red
      Add-Line "  -> Shu sababli polling (getUpdates) hech qanday xabar olmaydi." Red
      Write-Host ''
      $ans = Read-Host "Webhook ni hozir tozalaymi? Polling bilan ishlaydigan bot uchun shu kerak (ha/yo'q)"
      if ($ans -match '^(h|ha|y|yes)$') {
        $del = Call-TG 'deleteWebhook?drop_pending_updates=true'
        if ($del.ok) {
          Add-Line "  -> deleteWebhook: OK, webhook tozalandi. Endi botni qayta ishga tushiring." Green
        } else {
          Add-Line "  -> deleteWebhook: XATO — $($del.err)" Red
        }
      } else {
        Add-Line "  -> Tozalanmadi (foydalanuvchi rad etdi)." Yellow
      }
    }
    Add-Line "kutilayotgan xabarlar (pending_update_count): $($w.pending_update_count)"
    if ($w.pending_update_count -gt 0) {
      Add-Line "  -> Xabarlar kelyapti, lekin bot ularni o'qimayapti." Yellow
    }
    if ($w.last_error_message) {
      Add-Line "oxirgi xato: $($w.last_error_message) ($($w.last_error_date))" Red
    }
  } else {
    Add-Line "getWebhookInfo: XATO — $($wh.err)" Red
  }

  if ($procs.Count -eq 0) {
    $up = Call-TG 'getUpdates?limit=3&timeout=0'
    if ($up.ok) {
      $n = @($up.data.result).Count
      Add-Line "getUpdates: $n ta yangilanish navbatda"
      foreach ($u in @($up.data.result)) {
        $txt = $u.message.text
        $from = $u.message.from.username
        if ($txt) { Add-Line "  - @$from : $txt" }
      }
      if ($n -eq 0) { Add-Line "  -> Navbat bo'sh: yoki hech kim yozmagan, yoki boshqa nusxa o'qib ketyapti." Yellow }
    } else {
      Add-Line "getUpdates: XATO — $($up.err)" Red
      if ($up.body) { Add-Line "  javob: $($up.body)" Red }
    }
  } else {
    Add-Line "getUpdates o'tkazilmadi — bot ishlab turibdi, so'rov uning xabarlarini o'g'irlab qo'yardi." Gray
  }
}

# ── 5. bot.log oxiri ──
Add-Head "5. bot.log oxirgi 25 qator"
$logFile = Join-Path $root 'bot.log'
if (Test-Path $logFile) {
  foreach ($l in (Get-Content $logFile -Tail 25 -ErrorAction SilentlyContinue)) { Add-Line "  $l" }
} else {
  Add-Line "  bot.log yo'q (start-bot.bat orqali ishga tushirilsa yaratiladi)" Yellow
}

# ── XULOSA ──
Add-Head "XULOSA"
$verdicts = @()
if (-not $bot)                    { $verdicts += "bot.py topilmadi — skript noto'g'ri papkada." }
if (-not $token)                  { $verdicts += ".env da BOT_TOKEN yo'q — bot ishga tusha olmaydi." }
if ($token -and -not $me.ok)      { $verdicts += "Telegram bilan aloqa yo'q (token noto'g'ri yoki internet to'silgan)." }
if ($wh.ok -and -not [string]::IsNullOrWhiteSpace($wh.data.result.url)) {
  $verdicts += "WEBHOOK o'rnatilgan — polling ishlamaydi. Tuzatish uchun botni yopib shuni bajaring:"
  $verdicts += '    $t = (Select-String -Path .env -Pattern "^BOT_TOKEN=(.+)$").Matches.Groups[1].Value'
  $verdicts += '    irm "https://api.telegram.org/bot$t/deleteWebhook?drop_pending_updates=true"'
}
if ($procs.Count -eq 0)           { $verdicts += "Bot ishlamayapti — start-bot.bat bilan ishga tushiring." }
if ($procs.Count -gt 1)           { $verdicts += "Bir nechta nusxa ishlayapti — 409 Conflict. Hammasini yopib, bittasini ishga tushiring." }
if ($webappUrl -and $webappUrl -match 'trycloudflare|ngrok|localhost\.run|loca\.lt|serveo') {
  $verdicts += "WEBAPP_URL vaqtinchalik tunnelda — Mini App ochilmaydi (bot javobiga ta'sir qilmaydi)."
}
if ($verdicts.Count -eq 0) {
  $verdicts += "Bot ishlab turibdi, Telegram bilan aloqa bor, webhook yo'q."
  $verdicts += "Demak muammo bot KODIDA yoki bazada: masalan siz foydalanuvchilar jadvalida yo'qsiz,"
  $verdicts += "shuning uchun handler jimgina qaytib ketyapti. bot.py ni ko'rish kerak."
}
foreach ($v in $verdicts) { Add-Line $v Yellow }

# ── Saqlash ──
$out = Join-Path $dir 'hisobot.txt'
$lines | Out-File -FilePath $out -Encoding utf8
Add-Line ''
Add-Line "Hisobot saqlandi: $out" Green
Add-Line "Shu faylni Claude ga yuboring — token ichida YO'Q, xavfsiz." Green

try { Start-Process notepad.exe $out } catch {}
Write-Host ''
Read-Host 'Yopish uchun Enter bosing' | Out-Null

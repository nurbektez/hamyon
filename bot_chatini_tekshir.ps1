<#
.SYNOPSIS
  Bot chati ishlamay qolganda sababini topadi (va -Fix bilan tuzatadi).

.DESCRIPTION
  Tekshiradi:
    1. bot.py jarayoni ishlayaptimi;
    2. .env dagi BOT_TOKEN va WEBAPP_URL;
    3. Telegram: bot tokeni tirikmi (getMe);
    4. Telegram: WEBHOOK eski tunnel manzilida qolib ketmaganmi (getWebhookInfo)
       — bot chati o'lishining eng ko'p uchraydigan sababi;
    5. start_all.ps1 sintaksis jihatdan butunmi (izohga olingan qatorlar buzmaganmi);
    6. bot_err.log oxiri.

  -Fix bilan: webhookni o'chiradi, buzilgan start_all.ps1 ni zaxiradan tiklaydi,
  eski jarayonlarni o'ldirib botni qayta ishga tushiradi.

.EXAMPLE
  # faqat tekshirish
  powershell -ExecutionPolicy Bypass -File .\bot_chatini_tekshir.ps1

  # topilgan muammolarni tuzatish
  powershell -ExecutionPolicy Bypass -File .\bot_chatini_tekshir.ps1 -Fix
#>

param(
  [string]$BotDir = 'C:\hamyon\miniapp_bot',
  [switch]$Fix
)

$ErrorActionPreference = 'Continue'
# Eski Windows'da Invoke-RestMethod TLS 1.0 ga tushib qoladi — api.telegram.org rad etadi
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

function Say($m, $c = 'Gray') { Write-Host $m -ForegroundColor $c }
$problems = @()

Say "`n=== Bot chati diagnostikasi ===" 'Cyan'
Say "Papka: $BotDir"
if (-not $Fix) { Say "Rejim: TEKSHIRISH (tuzatish uchun -Fix qo'shing)" 'Yellow' }

if (-not (Test-Path $BotDir)) { throw "Papka topilmadi: $BotDir" }

# ── 1. Jarayon ─────────────────────────────────────────────────────────────
Say "`n[1] bot.py jarayoni" 'Cyan'
$procs = @(Get-WmiObject Win32_Process -ErrorAction SilentlyContinue |
           Where-Object { $_.CommandLine -like '*bot.py*' })
if ($procs.Count -eq 0) {
  Say "  ❌ ishlamayapti" 'Red'; $problems += 'bot-o-chiq'
} elseif ($procs.Count -gt 1) {
  Say "  ⚠️  $($procs.Count) ta jarayon — TelegramConflictError sababi" 'Yellow'
  $problems += 'ikkita-bot'
} else {
  Say "  ✅ ishlayapti (PID $($procs[0].ProcessId))" 'Green'
}

# ── 2. .env ────────────────────────────────────────────────────────────────
Say "`n[2] .env" 'Cyan'
$envPath = Join-Path $BotDir '.env'
$token  = $null
$webapp = $null
if (-not (Test-Path $envPath)) {
  Say "  ❌ .env topilmadi" 'Red'
} else {
  foreach ($line in @(Get-Content $envPath)) {
    if ($line -match '^\s*BOT_TOKEN\s*=\s*(.+?)\s*$')  { $token = $Matches[1].Trim('"').Trim("'") }
    if ($line -match '^\s*WEBAPP_URL\s*=\s*(.+?)\s*$') { $webapp = $Matches[1].Trim('"').Trim("'") }
  }
  if ($token) { Say "  ✅ BOT_TOKEN bor (…$($token.Substring([Math]::Max(0,$token.Length-4))))" 'Green' }
  else        { Say "  ❌ BOT_TOKEN yo'q" 'Red'; $problems += 'token-yoq' }

  if ($webapp) {
    if ($webapp -match 'trycloudflare|localhost\.run|ngrok') {
      Say "  ⚠️  WEBAPP_URL hamon tunnelda: $webapp" 'Yellow'; $problems += 'eski-webapp-url'
    } else { Say "  ✅ WEBAPP_URL = $webapp" 'Green' }
  } else { Say "  ⚠️  WEBAPP_URL yo'q" 'Yellow' }
}

# ── 3-4. Telegram ──────────────────────────────────────────────────────────
if ($token) {
  Say "`n[3] Telegram — token tirikmi" 'Cyan'
  try {
    $me = Invoke-RestMethod -Uri "https://api.telegram.org/bot$token/getMe" -TimeoutSec 20
    if ($me.ok) { Say "  ✅ @$($me.result.username)" 'Green' }
    else        { Say "  ❌ javob: $($me.description)" 'Red'; $problems += 'token-xato' }
  } catch {
    Say "  ❌ api.telegram.org ga ulanib bo'lmadi: $($_.Exception.Message)" 'Red'
    $problems += 'tarmoq'
  }

  Say "`n[4] Telegram — webhook holati (eng muhim)" 'Cyan'
  try {
    $wh = Invoke-RestMethod -Uri "https://api.telegram.org/bot$token/getWebhookInfo" -TimeoutSec 20
    $url = $wh.result.url
    if ([string]::IsNullOrWhiteSpace($url)) {
      Say "  ✅ webhook yo'q — bot polling rejimida (to'g'ri)" 'Green'
    } else {
      Say "  ❌ WEBHOOK O'RNATILGAN: $url" 'Red'
      Say "     Telegram xabarlarni shu manzilga yuboradi. Tunnel o'lgan bo'lsa," 'Red'
      Say "     bot chati umuman ishlamaydi." 'Red'
      $problems += 'webhook'
    }
    if ($wh.result.pending_update_count) {
      Say "  ⏳ yetkazilmagan xabarlar: $($wh.result.pending_update_count)" 'Yellow'
    }
    if ($wh.result.last_error_message) {
      Say "  ↳ oxirgi xato: $($wh.result.last_error_message)" 'Yellow'
    }
  } catch {
    Say "  ⚠️  getWebhookInfo o'qilmadi: $($_.Exception.Message)" 'Yellow'
  }
}

# ── 5. start_all.ps1 butunligi ─────────────────────────────────────────────
Say "`n[5] start_all.ps1 sintaksisi" 'Cyan'
$startPath = Join-Path $BotDir 'start_all.ps1'
$startBroken = $false
if (-not (Test-Path $startPath)) {
  Say "  ⚠️  fayl yo'q" 'Yellow'
} else {
  $perrs = $null
  try {
    [System.Management.Automation.Language.Parser]::ParseFile($startPath, [ref]$null, [ref]$perrs) | Out-Null
  } catch {}
  if ($perrs -and $perrs.Count -gt 0) {
    $startBroken = $true; $problems += 'start-buzilgan'
    Say "  ❌ $($perrs.Count) ta parse xatosi — watchdog ishga tushmaydi:" 'Red'
    $perrs | Select-Object -First 3 | ForEach-Object {
      Say ("     qator {0}: {1}" -f $_.Extent.StartLineNumber, $_.Message)
    }
  } else { Say "  ✅ butun" 'Green' }
}

# ── 6. Log ─────────────────────────────────────────────────────────────────
Say "`n[6] bot_err.log oxiri" 'Cyan'
$logPath = Join-Path $BotDir 'bot_err.log'
if (Test-Path $logPath) { Get-Content $logPath -Tail 12 | ForEach-Object { Say "  $_" } }
else { Say "  (log yo'q)" 'Yellow' }

# ── TUZATISH ───────────────────────────────────────────────────────────────
Say "`n=== Xulosa ===" 'Cyan'
if ($problems.Count -eq 0) { Say "Muammo topilmadi.`n" 'Green'; return }
Say ("Topilgan muammolar: " + ($problems -join ', ')) 'Yellow'

if (-not $Fix) {
  Say "`nTuzatish uchun: -Fix qo'shib qayta ishga tushiring.`n" 'Yellow'
  return
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

if ($problems -contains 'webhook' -and $token) {
  Say "`n→ webhook o'chirilmoqda…" 'Cyan'
  try {
    $r = Invoke-RestMethod -Uri "https://api.telegram.org/bot$token/deleteWebhook" -TimeoutSec 20
    if ($r.ok) {
      Say "  ✅ o'chirildi — bot endi polling bilan ishlaydi" 'Green'
      Say "     Agar bot ishga tushganda o'zi setWebhook qilsa, webhook qaytadi —" 'Yellow'
      Say "     u holda bot.py da webhook o'rniga polling yoqilishi kerak." 'Yellow'
    }
    else       { Say "  ❌ $($r.description)" 'Red' }
  } catch { Say "  ❌ $($_.Exception.Message)" 'Red' }
}

if ($startBroken) {
  Say "`n→ start_all.ps1 zaxiradan tiklanmoqda…" 'Cyan'
  $bak = Get-ChildItem "$startPath.bak-*" -ErrorAction SilentlyContinue |
         Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if ($bak) {
    Copy-Item $startPath "$startPath.buzilgan-$stamp" -ErrorAction SilentlyContinue
    Copy-Item $bak.FullName $startPath -Force
    Say "  ✅ tiklandi: $($bak.Name)" 'Green'
    Say "  ⚠️  Unda cloudflared qatorlari qaytadi — WEBAPP_URL ni qo'lda Pages ga qo'ying." 'Yellow'
  } else {
    Say "  ❌ zaxira topilmadi — botni to'g'ridan-to'g'ri ishga tushiramiz." 'Red'
  }
}

Say "`n→ bot qayta ishga tushirilmoqda…" 'Cyan'
Get-WmiObject Win32_Process -ErrorAction SilentlyContinue |
  Where-Object { $_.CommandLine -like '*bot.py*' -or $_.CommandLine -like '*start_all*' } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Start-Sleep -Seconds 3

$py = Join-Path $BotDir '.venv\Scripts\python.exe'
if (-not (Test-Path $py)) { $py = 'python' }
Start-Process -FilePath $py -ArgumentList 'bot.py' -WorkingDirectory $BotDir -WindowStyle Minimized
Start-Sleep -Seconds 5

$now = @(Get-WmiObject Win32_Process -ErrorAction SilentlyContinue |
         Where-Object { $_.CommandLine -like '*bot.py*' })
if ($now.Count -ge 1) { Say "  ✅ ishga tushdi (PID $($now[0].ProcessId))" 'Green' }
else { Say "  ❌ ishga tushmadi — bot_err.log ni ko'ring" 'Red' }

Say "`nTelegramda botga /start yozib sinang.`n" 'Cyan'

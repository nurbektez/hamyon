<#
.SYNOPSIS
  Botni cloudflared tunnelidan uzib, Mini App ni doimiy GitHub Pages manziliga ulaydi.

.DESCRIPTION
  1. .env dagi WEBAPP_URL ni GitHub Pages manziliga o'zgartiradi.
  2. start_all.ps1 dagi tunnel bilan bog'liq qatorlarni topadi va (-Apply bilan) izohga oladi.
  3. (-Restart bilan) eski bot jarayonlarini o'ldirib, botni qayta ishga tushiradi.

  Standart holatda HECH NARSA o'zgartirmaydi — faqat nima o'zgarishini ko'rsatadi.
  Rozi bo'lsangiz, -Apply qo'shib qayta ishga tushiring.

.EXAMPLE
  # 1-qadam: nima o'zgarishini ko'rish
  powershell -ExecutionPolicy Bypass -File .\botni_pages_ga_ulash.ps1

  # 2-qadam: o'zgartirish va botni qayta ishga tushirish
  powershell -ExecutionPolicy Bypass -File .\botni_pages_ga_ulash.ps1 -Apply -Restart
#>

param(
  [string]$BotDir  = 'C:\hamyon\miniapp_bot',
  [string]$PagesUrl = 'https://nurbektez.github.io/hamyon/',
  [switch]$Apply,
  [switch]$Restart
)

$ErrorActionPreference = 'Stop'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

# Eski Windows'da Invoke-RestMethod TLS 1.0 ga tushadi — api.telegram.org rad etadi
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

function Say($msg, $color = 'Gray') { Write-Host $msg -ForegroundColor $color }

# Papkada bot turibdimi? .env, start_all.ps1 yoki bot.py bo'lsa — ha.
function Test-BotDir($path) {
  if (-not $path) { return $false }
  if (-not (Test-Path $path)) { return $false }
  foreach ($f in @('.env', 'start_all.ps1', 'bot.py')) {
    if (Test-Path (Join-Path $path $f)) { return $true }
  }
  return $false
}

# Bot boshqa papkada bo'lsa ham topilsin — foydalanuvchi yo'lni terib o'tirmasin.
# Skript yonidan, C:\hamyon dan va ularning ichki papkalaridan qidiriladi.
function Find-BotDir($preferred) {
  if (Test-BotDir $preferred) { return $preferred }

  $roots = @()
  if ($PSScriptRoot) { $roots += $PSScriptRoot }
  $parent = Split-Path $preferred -Parent
  if ($parent) { $roots += $parent }
  $roots += 'C:\hamyon'
  $roots = @($roots | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique)

  foreach ($root in $roots) {
    if (Test-BotDir $root) { return $root }
    foreach ($sub in @(Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue)) {
      if (Test-BotDir $sub.FullName) { return $sub.FullName }
    }
  }
  return $null
}

Say "`n=== Botni GitHub Pages ga ulash ===" 'Cyan'

$foundDir = Find-BotDir $BotDir
if (-not $foundDir) {
  # throw emas: PowerShell uni stack trace bilan chiqaradi, foydalanuvchi tushunmaydi.
  Say ""
  Say "Bot papkasi topilmadi." 'Red'
  Say "  Kerak: ichida .env, start_all.ps1 yoki bot.py bo'lgan papka."
  Say "  Qidirildi: $BotDir"
  if ($PSScriptRoot) { Say "             $PSScriptRoot" }
  Say "             C:\hamyon"
  Say "             va ularning ichki papkalari"
  Say ""
  Say "  Yechim: bu faylni bot papkasiga ko'chirib qayta ishga tushiring," 'Yellow'
  Say "          yoki yo'lni o'zingiz bering:" 'Yellow'
  Say "          .\botni_pages_ga_ulash.ps1 -BotDir 'C:\bot\papkasi'" 'Yellow'
  Say ""
  exit 1
}
$autoFound = ($foundDir -ne $BotDir)
$BotDir = $foundDir

Say "Papka     : $BotDir"
if ($autoFound) { Say "            (avtomatik topildi)" 'Yellow' }
Say "Yangi URL : $PagesUrl"
if (-not $Apply) { Say "Rejim     : SINOV (hech narsa o'zgarmaydi, -Apply qo'shing)" 'Yellow' }
else             { Say "Rejim     : O'ZGARTIRISH" 'Green' }

# ── 1. .env ────────────────────────────────────────────────────────────────
$envPath = Join-Path $BotDir '.env'
$botToken = ''
Say "`n[1/4] .env — WEBAPP_URL" 'Cyan'
if (-not (Test-Path $envPath)) {
  Say "  .env topilmadi ($envPath) — o'tkazib yuborildi." 'Yellow'
} else {
  $lines = @(Get-Content $envPath)
  # Webhook bosqichi uchun kerak. Token ekranga chiqmaydi, hech qayerga yozilmaydi.
  foreach ($l in $lines) {
    if ($l -match '^\s*BOT_TOKEN\s*=\s*(.+?)\s*$') { $botToken = $Matches[1].Trim('"').Trim("'") }
  }
  $old   = ($lines | Where-Object { $_ -match '^\s*WEBAPP_URL\s*=' }) -join '; '
  if ($old) { Say "  hozir : $old" } else { Say "  hozir : (WEBAPP_URL yo'q, qo'shiladi)" }
  Say "  bo'ladi: WEBAPP_URL=$PagesUrl" 'Green'

  if ($Apply) {
    Copy-Item $envPath "$envPath.bak-$stamp"
    if ($old) { $new = @($lines -replace '^\s*WEBAPP_URL\s*=.*', "WEBAPP_URL=$PagesUrl") }
    else      { $new = @($lines) + "WEBAPP_URL=$PagesUrl" }
    # .env ni BOM'siz yozamiz — BOM python-dotenv da birinchi kalitni buzadi
    [System.IO.File]::WriteAllLines($envPath, $new, (New-Object System.Text.UTF8Encoding($false)))
    Say "  ✅ yozildi (zaxira: .env.bak-$stamp)" 'Green'
  }
}

# ── 2. Telegram webhook ────────────────────────────────────────────────────
# Tunnel o'lganda webhook uning o'lik manzilida qotib qoladi va bot chati jim
# bo'ladi. WEBAPP_URL ni almashtirish buni tuzatmaydi — webhookni Telegram
# tomonida o'chirish kerak, shunda bot polling'ga qaytadi.
Say "`n[2/4] Telegram — webhook holati" 'Cyan'
$webhookUrl = $null
if (-not $botToken) {
  Say "  .env da BOT_TOKEN yo'q — tekshirib bo'lmadi." 'Yellow'
} else {
  try {
    $wh = Invoke-RestMethod -Uri "https://api.telegram.org/bot$botToken/getWebhookInfo" -TimeoutSec 20
    $webhookUrl = $wh.result.url
    if ([string]::IsNullOrWhiteSpace($webhookUrl)) {
      Say "  webhook yo'q — bot polling rejimida (to'g'ri)" 'Green'
      $webhookUrl = $null
    } else {
      Say "  webhook o'rnatilgan: $webhookUrl" 'Yellow'
      Say "  Telegram xabarlarni shu manzilga yuboradi. Manzil o'lik bo'lsa," 'Yellow'
      Say "  bot chati jim bo'ladi." 'Yellow'
      if ($wh.result.pending_update_count) {
        Say "  yetkazilmagan xabarlar: $($wh.result.pending_update_count)"
      }
      if ($wh.result.last_error_message) {
        Say "  oxirgi xato: $($wh.result.last_error_message)"
      }
      Say "  bo'ladi: webhook o'chiriladi, bot polling'ga qaytadi" 'Green'
    }
  } catch {
    Say "  api.telegram.org o'qilmadi: $($_.Exception.Message)" 'Yellow'
    Say "  (internet yo'q yoki token xato — bu bosqich o'tkazib yuboriladi)" 'Yellow'
  }

  if ($Apply -and $webhookUrl) {
    try {
      $r = Invoke-RestMethod -Uri "https://api.telegram.org/bot$botToken/deleteWebhook" -TimeoutSec 20
      if ($r.ok) {
        Say "  webhook o'chirildi — bot endi polling bilan ishlaydi" 'Green'
        Say "  Bot ishga tushganda o'zi setWebhook qilsa, webhook qaytadi —" 'Yellow'
        Say "  u holda bot.py da webhook o'rniga polling yoqilishi kerak." 'Yellow'
      } else {
        Say "  o'chirilmadi: $($r.description)" 'Red'
      }
    } catch {
      Say "  o'chirilmadi: $($_.Exception.Message)" 'Red'
    }
  }
}

# ── 3. start_all.ps1 ───────────────────────────────────────────────────────
$startPath = Join-Path $BotDir 'start_all.ps1'
Say "`n[3/4] start_all.ps1 — tunnel qatorlari" 'Cyan'
if (-not (Test-Path $startPath)) {
  Say "  start_all.ps1 topilmadi — o'tkazib yuborildi." 'Yellow'
} else {
  $pattern = 'cloudflared|trycloudflare|localhost\.run|cf\.log|WEBAPP_URL'
  $src  = @(Get-Content $startPath)
  $hits = @()
  for ($i = 0; $i -lt $src.Count; $i++) {
    if ($src[$i] -match $pattern -and $src[$i] -notmatch '^\s*#') { $hits += $i }
  }

  if ($hits.Count -eq 0) {
    Say "  Tunnel bilan bog'liq qator topilmadi — allaqachon tozalangan ko'rinadi." 'Green'
  } else {
    Say "  Quyidagi $($hits.Count) ta qator izohga olinadi:" 'Yellow'
    foreach ($i in $hits) { Say ("    {0,4}: {1}" -f ($i + 1), $src[$i].Trim()) }

    if ($Apply) {
      Copy-Item $startPath "$startPath.bak-$stamp"
      foreach ($i in $hits) { $src[$i] = "# [pages] " + $src[$i] }
      # .ps1 ni BOM bilan — Windows PowerShell 5.1 aks holda o'zbekcha matnni buzadi
      [System.IO.File]::WriteAllLines($startPath, $src, (New-Object System.Text.UTF8Encoding($true)))
      Say "  ✅ izohga olindi (zaxira: start_all.ps1.bak-$stamp)" 'Green'
      Say "  ⚠️  Fayl mantig'i buzilmaganini bir ko'zdan kechiring — kerak bo'lsa zaxiradan qaytaring." 'Yellow'
    }
  }
}

# ── 4. Botni qayta ishga tushirish ─────────────────────────────────────────
Say "`n[4/4] Botni qayta ishga tushirish" 'Cyan'
if (-not $Restart) {
  Say "  -Restart berilmadi. Qo'lda:" 'Yellow'
  Say "    Get-WmiObject Win32_Process | Where-Object { `$_.CommandLine -like '*bot.py*' -or `$_.CommandLine -like '*start_all*' } | ForEach-Object { Stop-Process -Id `$_.ProcessId -Force }"
  Say "    Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -File $startPath' -WindowStyle Normal"
} elseif (-not $Apply) {
  Say "  Sinov rejimida qayta ishga tushirilmaydi." 'Yellow'
} else {
  Get-WmiObject Win32_Process |
    Where-Object { $_.CommandLine -like '*bot.py*' -or $_.CommandLine -like '*start_all*' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
  Start-Sleep -Seconds 2
  Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File $startPath" -WindowStyle Normal
  Say "  ✅ qayta ishga tushirildi" 'Green'
}

Say "`nTayyor. Telegramda botga /start yozing → '💼 Hamyon' tugmasi.`n" 'Cyan'
if (-not $Apply) { Say "O'zgartirish uchun: -Apply -Restart qo'shib qayta ishga tushiring.`n" 'Yellow' }

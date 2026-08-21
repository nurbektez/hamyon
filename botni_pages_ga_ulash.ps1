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

function Say($msg, $color = 'Gray') { Write-Host $msg -ForegroundColor $color }

Say "`n=== Botni GitHub Pages ga ulash ===" 'Cyan'
Say "Papka     : $BotDir"
Say "Yangi URL : $PagesUrl"
if (-not $Apply) { Say "Rejim     : SINOV (hech narsa o'zgarmaydi, -Apply qo'shing)" 'Yellow' }
else             { Say "Rejim     : O'ZGARTIRISH" 'Green' }

if (-not (Test-Path $BotDir)) { throw "Papka topilmadi: $BotDir  (-BotDir bilan boshqa yo'l bering)" }

# ── 1. .env ────────────────────────────────────────────────────────────────
$envPath = Join-Path $BotDir '.env'
Say "`n[1/3] .env — WEBAPP_URL" 'Cyan'
if (-not (Test-Path $envPath)) {
  Say "  .env topilmadi ($envPath) — o'tkazib yuborildi." 'Yellow'
} else {
  $lines = @(Get-Content $envPath)
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

# ── 2. start_all.ps1 ───────────────────────────────────────────────────────
$startPath = Join-Path $BotDir 'start_all.ps1'
Say "`n[2/3] start_all.ps1 — tunnel qatorlari" 'Cyan'
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

# ── 3. Botni qayta ishga tushirish ─────────────────────────────────────────
Say "`n[3/3] Botni qayta ishga tushirish" 'Cyan'
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

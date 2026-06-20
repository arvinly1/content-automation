. "$PSScriptRoot\common.ps1"

$root = Get-ProjectRoot
$draftPath = Join-Path $root "output\drafts.json"
$coverDir = Join-Path $root "output\covers"
New-Item -ItemType Directory -Force -Path $coverDir | Out-Null

if (-not (Test-Path $draftPath)) {
  throw "未找到 $draftPath，请先运行 sync_feishu_drafts.ps1"
}

$drafts = Get-Content -Raw $draftPath | ConvertFrom-Json

Add-Type -AssemblyName System.Drawing

function New-CoverImage {
  param(
    [string]$Path,
    [string]$Title,
    [string]$Subtitle,
    [string]$Footer
  )

  $bmp = New-Object System.Drawing.Bitmap 1242, 1660
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

  $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    [System.Drawing.Rectangle]::new(0, 0, 1242, 1660),
    [System.Drawing.Color]::FromArgb(248, 249, 246),
    [System.Drawing.Color]::FromArgb(229, 234, 228),
    90
  )
  $g.FillRectangle($bg, 0, 0, 1242, 1660)

  $brushDark = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(38, 44, 40))
  $brushMid = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(90, 99, 92))
  $brushAccent = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(120, 74, 58))
  $panel = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(238, 241, 235))

  $g.FillRectangle($panel, 80, 180, 1082, 1000)
  $g.FillRectangle($brushAccent, 80, 180, 18, 1000)

  $fontTitle = New-Object System.Drawing.Font("Microsoft YaHei UI", 62, [System.Drawing.FontStyle]::Bold)
  $fontSub = New-Object System.Drawing.Font("Microsoft YaHei UI", 34, [System.Drawing.FontStyle]::Regular)
  $fontFoot = New-Object System.Drawing.Font("Microsoft YaHei UI", 28, [System.Drawing.FontStyle]::Regular)
  $fmt = New-Object System.Drawing.StringFormat
  $fmt.Alignment = [System.Drawing.StringAlignment]::Near
  $fmt.LineAlignment = [System.Drawing.StringAlignment]::Near

  $g.DrawString($Title, $fontTitle, $brushDark, [System.Drawing.RectangleF]::new(140, 260, 960, 560), $fmt)
  $g.DrawString($Subtitle, $fontSub, $brushMid, [System.Drawing.RectangleF]::new(140, 880, 930, 220), $fmt)
  $g.DrawString($Footer, $fontFoot, $brushMid, [System.Drawing.RectangleF]::new(100, 1390, 1040, 120), $fmt)

  $bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose()
  $bmp.Dispose()
}

foreach ($draft in $drafts) {
  $safeTitle = $draft.title
  $subtitle = if ($draft.platform -eq "小红书") {
    "真实记录｜程序员转型｜内容知识库"
  } else {
    "先不谈暴富，先把经验和选题沉淀下来"
  }

  $path = Join-Path $coverDir "$($draft.slug)-$($draft.platform).png"
  New-CoverImage -Path $path -Title $safeTitle -Subtitle $subtitle -Footer "程序员转型内容实验"
}

Write-Host "已生成封面：$coverDir"

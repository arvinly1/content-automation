. "$PSScriptRoot\common.ps1"

$root = Get-ProjectRoot
$draftPath = Join-Path $root "output\drafts.json"
$publicDir = Join-Path $root "public"
$articlesDir = Join-Path $publicDir "articles"
New-Item -ItemType Directory -Force -Path $articlesDir | Out-Null

if (-not (Test-Path $draftPath)) {
  throw "未找到 $draftPath，请先运行 sync_feishu_drafts.ps1"
}

$config = Get-ContentAutomationConfig
$drafts = Get-Content -Raw $draftPath | ConvertFrom-Json
$baseUrl = $config.Site.BaseUrl.TrimEnd("/")
$siteTitle = $config.Site.Title
$author = $config.Site.Author

function HtmlEncode([string]$Text) {
  [System.Net.WebUtility]::HtmlEncode($Text)
}

$rssItems = New-Object System.Collections.Generic.List[string]
$indexItems = New-Object System.Collections.Generic.List[string]

foreach ($draft in $drafts) {
  if ($draft.platform -ne "头条") { continue }

  $slug = $draft.slug
  $articleUrl = "$baseUrl/articles/$slug.html"
  $htmlTitle = HtmlEncode $draft.title
  $paragraphs = ($draft.body -split "(`r`n|`n|`r){2,}") | Where-Object { $_.Trim() }
  $bodyHtml = ($paragraphs | ForEach-Object { "<p>$([System.Net.WebUtility]::HtmlEncode($_.Trim()).Replace("`n", "<br>"))</p>" }) -join "`n"

  $html = @"
<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>$htmlTitle</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "Microsoft YaHei", sans-serif; margin: 0; background: #f7f8f5; color: #26302a; }
    main { max-width: 760px; margin: 0 auto; padding: 48px 20px 80px; line-height: 1.85; font-size: 18px; }
    h1 { font-size: 34px; line-height: 1.25; margin: 0 0 28px; }
    p { margin: 0 0 20px; }
    .meta { color: #667064; margin-bottom: 36px; font-size: 14px; }
  </style>
</head>
<body>
  <main>
    <h1>$htmlTitle</h1>
    <div class="meta">$([System.Net.WebUtility]::HtmlEncode($author)) · $(Get-Date -Format "yyyy-MM-dd")</div>
    $bodyHtml
  </main>
</body>
</html>
"@

  $articlePath = Join-Path $articlesDir "$slug.html"
  $html | Set-Content -Encoding UTF8 $articlePath

  $indexItems.Add("<li><a href=""articles/$slug.html"">$htmlTitle</a></li>")

  $desc = HtmlEncode (($draft.body -replace "\s+", " ").Substring(0, [Math]::Min(180, ($draft.body -replace "\s+", " ").Length)))
  $pubDate = [DateTimeOffset]::Now.ToString("r")
  $rssItems.Add(@"
    <item>
      <title>$htmlTitle</title>
      <link>$articleUrl</link>
      <guid>$articleUrl</guid>
      <pubDate>$pubDate</pubDate>
      <description>$desc</description>
    </item>
"@)
}

$indexHtml = @"
<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>$([System.Net.WebUtility]::HtmlEncode($siteTitle))</title>
</head>
<body>
  <h1>$([System.Net.WebUtility]::HtmlEncode($siteTitle))</h1>
  <ul>
    $($indexItems -join "`n")
  </ul>
</body>
</html>
"@
$indexHtml | Set-Content -Encoding UTF8 (Join-Path $publicDir "index.html")

$rss = @"
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>$([System.Net.WebUtility]::HtmlEncode($siteTitle))</title>
    <link>$baseUrl</link>
    <description>$([System.Net.WebUtility]::HtmlEncode($siteTitle))</description>
    <language>zh-CN</language>
    $($rssItems -join "`n")
  </channel>
</rss>
"@
$rss | Set-Content -Encoding UTF8 (Join-Path $publicDir "rss.xml")

Write-Host "已生成静态站点和 RSS：$publicDir"

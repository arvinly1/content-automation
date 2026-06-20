. "$PSScriptRoot\common.ps1"

$root = Get-ProjectRoot
$draftPath = Join-Path $root "output\drafts.json"
$coverDir = Join-Path $root "output\covers"
$todayDir = Join-Path $root "today_publish"

if (-not (Test-Path $draftPath)) {
  throw "未找到 $draftPath，请先运行 sync_feishu_drafts.ps1"
}

if (Test-Path $todayDir) {
  Remove-Item -Recurse -Force $todayDir
}
New-Item -ItemType Directory -Force -Path $todayDir | Out-Null

$drafts = Get-Content -Raw $draftPath | ConvertFrom-Json
$platformSlug = @{
  "头条" = "toutiao"
  "小红书" = "xiaohongshu"
}

function Write-Utf8File {
  param(
    [string]$Path,
    [string]$Content
  )
  $Content | Set-Content -Encoding UTF8 $Path
}

function ConvertTo-HtmlText {
  param([AllowNull()][string]$Text)
  if ($null -eq $Text) { return "" }
  return [System.Net.WebUtility]::HtmlEncode($Text)
}

function Get-PlatformPublishUrl {
  param([string]$Platform)
  if ($Platform -eq "小红书") {
    return "https://creator.xiaohongshu.com/publish/publish"
  }
  return "https://mp.toutiao.com/profile_v4/graphic/publish"
}

function Get-PublishTitle {
  param(
    [string]$Platform,
    [string]$Title
  )

  if ($Platform -ne "头条" -or $Title.Length -le 30) {
    return $Title
  }

  $shortTitle = $Title
  $shortTitle = $shortTitle.Replace("失业后我才明白：程序员最危险的不是35岁，而是只有工资这一种收入", "失业后我才懂：程序员最怕收入单一")
  $shortTitle = $shortTitle.Replace("最危险的不是35岁，而是只有工资这一种收入", "最怕收入单一")
  $shortTitle = $shortTitle.Replace("我才明白", "我才懂")

  if ($shortTitle.Length -le 30) {
    return $shortTitle
  }

  $parts = $shortTitle -split "[，。；]"
  if ($parts.Count -gt 0 -and $parts[0].Length -gt 0 -and $parts[0].Length -le 30) {
    return $parts[0]
  }

  return $shortTitle.Substring(0, 30)
}

function Get-Checklist {
  param([string]$Platform)

  if ($Platform -eq "小红书") {
    return @"
# 小红书发布前检查

- [ ] 标题前 12 个字能让人停下来
- [ ] 开头 3 行有真实情绪或明确痛点
- [ ] 分段足够短，手机上不压迫
- [ ] 没有夸大收益、没有“月入过万”承诺
- [ ] 没有大段引用或搬运他人内容
- [ ] 至少有一个可收藏的清单或方法
- [ ] 标签不超过 8 个，且和内容真实相关
- [ ] 发布后复制链接，回填飞书发布复盘库

建议发布时间：

- 中午 12:00-13:30
- 晚上 20:30-23:00

发布后观察：

- 2 小时：点击/点赞是否有起量
- 24 小时：收藏率、评论痛点
- 72 小时：是否值得延展下一篇
"@
  }

  return @"
# 头条发布前检查

- [ ] 标题真实，不做过度承诺
- [ ] 开头 200 字有冲突和个人状态
- [ ] 正文逻辑完整：经历 -> 观点 -> 方法 -> 反思
- [ ] 没有大段引用或搬运他人内容
- [ ] 没有夸大收益、没有诱导式承诺
- [ ] 文章收益/原创/广告等选项发布前确认
- [ ] 封面清晰，标题字不遮挡主体
- [ ] 发布后复制链接，回填飞书发布复盘库

建议发布时间：

- 晚上 20:00-22:30

发布后观察：

- 2 小时：推荐量、阅读点击
- 24 小时：完读率、评论质量
- 72 小时：收益、收藏、转粉
"@
}

$manifest = New-Object System.Collections.Generic.List[object]
$helperCards = New-Object System.Collections.Generic.List[string]

$publishIndex = 0
foreach ($draft in $drafts) {
  $platform = [string]$draft.platform
  if (-not $platformSlug.ContainsKey($platform)) { continue }

  $publishIndex++
  $dirName = "{0:D2}_{1}" -f $publishIndex, $platformSlug[$platform]
  $publishDir = Join-Path $todayDir $dirName
  New-Item -ItemType Directory -Force -Path $publishDir | Out-Null

  $titlePath = Join-Path $publishDir "title.txt"
  $bodyPath = Join-Path $publishDir "body.md"
  $checklistPath = Join-Path $publishDir "checklist.md"
  $metaPath = Join-Path $publishDir "meta.json"

  $publishTitle = Get-PublishTitle -Platform $platform -Title ([string]$draft.title)

  Write-Utf8File $titlePath $publishTitle
  Write-Utf8File $bodyPath $draft.body
  Write-Utf8File $checklistPath (Get-Checklist -Platform $platform)

  if ($platform -eq "小红书") {
    Write-Utf8File (Join-Path $publishDir "tags.txt") "#程序员 #失业日记 #程序员转型 #技术变现 #副业探索 #内容创作 #自我成长"
  }

  $coverName = "$($draft.slug)-$platform.png"
  $coverPath = Join-Path $coverDir $coverName
  if (Test-Path $coverPath) {
    Copy-Item $coverPath (Join-Path $publishDir "cover.png") -Force
  }

  $meta = [pscustomobject]@{
    record_id = $draft.record_id
    platform = $platform
    title = $publishTitle
    original_title = $draft.title
    source_slug = $draft.slug
    generated_at = (Get-Date).ToString("s")
    publish_status = "待人工发布"
    after_publish = "把发布链接、阅读量、点赞、收藏、评论回填飞书发布复盘库"
  }
  $meta | ConvertTo-Json -Depth 10 | Set-Content -Encoding UTF8 $metaPath
  $manifest.Add($meta)

  $safePlatform = ConvertTo-HtmlText $platform
  $safeTitle = ConvertTo-HtmlText $publishTitle
  $safeBody = ConvertTo-HtmlText $draft.body
  $safeDirName = ConvertTo-HtmlText $dirName
  $publishUrl = ConvertTo-HtmlText (Get-PlatformPublishUrl -Platform $platform)
  $titleLength = ([string]$publishTitle).Length
  $bodyLength = ([string]$draft.body).Length

  $tagsBlock = ""
  if ($platform -eq "小红书") {
    $tags = Get-Content -Raw (Join-Path $publishDir "tags.txt")
    $safeTags = ConvertTo-HtmlText $tags
    $tagsBlock = @"
        <div class="field">
          <div class="field-head">
            <label for="$dirName-tags">标签</label>
            <button type="button" data-copy="$dirName-tags">复制标签</button>
          </div>
          <textarea id="$dirName-tags" rows="2" readonly>$safeTags</textarea>
        </div>
"@
  }

  $helperCards.Add(@"
      <section class="card">
        <div class="card-title">
          <div>
            <p class="eyebrow">$safePlatform</p>
            <h2>$safeTitle</h2>
          </div>
          <a class="open-link" href="$publishUrl" target="_blank" rel="noopener">打开$($safePlatform)发布页</a>
        </div>

        <div class="meta-row">
          <span>标题 $titleLength 字</span>
          <span>正文 $bodyLength 字</span>
          <span>素材目录 $safeDirName</span>
        </div>

        <div class="cover-row">
          <img src="$safeDirName/cover.png" alt="$safePlatform 封面预览" onerror="this.style.display='none'">
          <div>
            <p>封面文件：<code>$safeDirName/cover.png</code></p>
            <p class="muted">封面和最终发布仍建议人工确认，避免平台规则和排版问题。</p>
          </div>
        </div>

        <div class="field">
          <div class="field-head">
            <label for="$dirName-title">标题</label>
            <button type="button" data-copy="$dirName-title">复制标题</button>
          </div>
          <textarea id="$dirName-title" rows="2" readonly>$safeTitle</textarea>
        </div>

        <div class="field">
          <div class="field-head">
            <label for="$dirName-body">正文</label>
            <button type="button" data-copy="$dirName-body">复制正文</button>
          </div>
          <textarea id="$dirName-body" rows="14" readonly>$safeBody</textarea>
        </div>

$tagsBlock

        <div class="actions">
          <a href="$safeDirName/checklist.md" target="_blank" rel="noopener">发布前检查</a>
          <a href="$safeDirName" target="_blank" rel="noopener">打开素材目录</a>
        </div>
      </section>
"@)
}

$manifest | ConvertTo-Json -Depth 10 | Set-Content -Encoding UTF8 (Join-Path $todayDir "manifest.json")

$readme = @"
# 今日发布包

生成时间：$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

使用方式：

1. 打开平台后台。
2. 复制对应目录里的 ``title.txt`` 和 ``body.md``。
3. 上传 ``cover.png``。
4. 小红书额外复制 ``tags.txt``。
5. 发布前按 ``checklist.md`` 检查。
6. 发布后把链接和数据回填飞书 ``发布复盘库``。

目录：

- ``01_toutiao`` / ``03_toutiao``：头条发布包，按当天待发布顺序编号
- ``02_xiaohongshu`` / ``04_xiaohongshu``：小红书发布包，按当天待发布顺序编号
- ``publish-helper.html``：发布助手页面，一键复制标题、正文、标签并打开平台后台
"@

Write-Utf8File (Join-Path $todayDir "README.md") $readme

$helperHtml = @"
<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>今日发布助手</title>
  <style>
    * { box-sizing: border-box; }
    body {
      margin: 0;
      background: #f6f7f9;
      color: #172033;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "Microsoft YaHei", sans-serif;
      line-height: 1.6;
    }
    header {
      position: sticky;
      top: 0;
      z-index: 5;
      border-bottom: 1px solid #e5e7eb;
      background: rgba(255,255,255,.94);
      backdrop-filter: blur(10px);
    }
    .topbar {
      max-width: 1180px;
      margin: 0 auto;
      padding: 18px 24px;
      display: flex;
      justify-content: space-between;
      gap: 16px;
      align-items: center;
    }
    h1, h2, p { margin: 0; }
    h1 { font-size: 22px; }
    h2 { font-size: 22px; line-height: 1.35; }
    .sub, .muted, .status { color: #6b7280; font-size: 14px; }
    .status { min-width: 180px; text-align: right; }
    main {
      max-width: 1180px;
      margin: 0 auto;
      padding: 24px;
      display: grid;
      gap: 20px;
    }
    .card {
      background: #fff;
      border: 1px solid #e5e7eb;
      border-radius: 8px;
      padding: 22px;
      box-shadow: 0 8px 24px rgba(15,23,42,.04);
    }
    .card-title {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      gap: 20px;
      margin-bottom: 14px;
    }
    .eyebrow {
      color: #ef4444;
      font-size: 14px;
      font-weight: 700;
      margin-bottom: 4px;
    }
    button, .open-link, .actions a {
      border: 0;
      border-radius: 6px;
      background: #ef4444;
      color: #fff;
      cursor: pointer;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      min-height: 38px;
      padding: 0 14px;
      font-size: 14px;
      font-weight: 700;
      text-decoration: none;
      white-space: nowrap;
    }
    button:hover, .open-link:hover { background: #dc2626; }
    .actions a {
      background: #f3f4f6;
      color: #374151;
      border: 1px solid #e5e7eb;
    }
    .meta-row {
      display: flex;
      flex-wrap: wrap;
      gap: 10px;
      margin: 14px 0;
      color: #6b7280;
      font-size: 13px;
    }
    .meta-row span {
      padding: 4px 9px;
      border-radius: 999px;
      background: #f3f4f6;
    }
    .cover-row {
      display: flex;
      gap: 16px;
      align-items: center;
      padding: 14px;
      border: 1px solid #e5e7eb;
      border-radius: 8px;
      background: #fafafa;
      margin-bottom: 18px;
    }
    .cover-row img {
      width: 160px;
      height: 90px;
      object-fit: cover;
      border-radius: 6px;
      border: 1px solid #e5e7eb;
      background: #fff;
    }
    code {
      background: #eef2f7;
      padding: 2px 5px;
      border-radius: 4px;
    }
    .field { margin-top: 16px; }
    .field-head {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 12px;
      margin-bottom: 8px;
    }
    label { font-weight: 700; }
    textarea {
      width: 100%;
      resize: vertical;
      border: 1px solid #e5e7eb;
      border-radius: 8px;
      padding: 12px;
      color: #172033;
      background: #fff;
      font: 15px/1.7 "Microsoft YaHei", sans-serif;
    }
    textarea:focus {
      outline: 2px solid rgba(239,68,68,.18);
      border-color: #ef4444;
    }
    .actions {
      display: flex;
      flex-wrap: wrap;
      gap: 10px;
      margin-top: 18px;
    }
    .toast {
      position: fixed;
      right: 20px;
      bottom: 20px;
      padding: 12px 14px;
      border-radius: 8px;
      color: #fff;
      background: #111827;
      opacity: 0;
      transform: translateY(10px);
      transition: .18s ease;
      pointer-events: none;
    }
    .toast.show { opacity: 1; transform: translateY(0); }
    @media (max-width: 760px) {
      .topbar, .card-title, .cover-row { flex-direction: column; align-items: stretch; }
      .status { text-align: left; }
      .open-link { width: 100%; }
      .cover-row img { width: 100%; height: auto; aspect-ratio: 16 / 9; }
    }
  </style>
</head>
<body>
  <header>
    <div class="topbar">
      <div>
        <h1>今日发布助手</h1>
        <p class="sub">生成时间：$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")。复制内容后到平台后台人工检查并发布。</p>
      </div>
      <div class="status" id="status">准备好了</div>
    </div>
  </header>

  <main>
$($helperCards -join "`n")
  </main>

  <div class="toast" id="toast">已复制</div>

  <script>
    const statusEl = document.getElementById('status');
    const toastEl = document.getElementById('toast');

    function showToast(message) {
      statusEl.textContent = message;
      toastEl.textContent = message;
      toastEl.classList.add('show');
      window.setTimeout(() => toastEl.classList.remove('show'), 1400);
    }

    async function copyTextFrom(id) {
      const el = document.getElementById(id);
      if (!el) return;
      el.focus();
      el.select();

      try {
        await navigator.clipboard.writeText(el.value);
      } catch (error) {
        document.execCommand('copy');
      }

      showToast('已复制：' + id.replace('-', ' '));
    }

    document.querySelectorAll('[data-copy]').forEach((button) => {
      button.addEventListener('click', () => copyTextFrom(button.dataset.copy));
    });
  </script>
</body>
</html>
"@

Write-Utf8File (Join-Path $todayDir "publish-helper.html") $helperHtml
Write-Host "已生成今日发布包：$todayDir"
Write-Host "发布助手页面：$todayDir\publish-helper.html"

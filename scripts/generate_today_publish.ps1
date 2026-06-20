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
$platformOrder = @{
  "头条" = "01_toutiao"
  "小红书" = "02_xiaohongshu"
}

function Write-Utf8File {
  param(
    [string]$Path,
    [string]$Content
  )
  $Content | Set-Content -Encoding UTF8 $Path
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

foreach ($draft in $drafts) {
  $platform = [string]$draft.platform
  if (-not $platformOrder.ContainsKey($platform)) { continue }

  $dirName = $platformOrder[$platform]
  $publishDir = Join-Path $todayDir $dirName
  New-Item -ItemType Directory -Force -Path $publishDir | Out-Null

  $titlePath = Join-Path $publishDir "title.txt"
  $bodyPath = Join-Path $publishDir "body.md"
  $checklistPath = Join-Path $publishDir "checklist.md"
  $metaPath = Join-Path $publishDir "meta.json"

  Write-Utf8File $titlePath $draft.title
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
    title = $draft.title
    source_slug = $draft.slug
    generated_at = (Get-Date).ToString("s")
    publish_status = "待人工发布"
    after_publish = "把发布链接、阅读量、点赞、收藏、评论回填飞书发布复盘库"
  }
  $meta | ConvertTo-Json -Depth 10 | Set-Content -Encoding UTF8 $metaPath
  $manifest.Add($meta)
}

$manifest | ConvertTo-Json -Depth 10 | Set-Content -Encoding UTF8 (Join-Path $todayDir "manifest.json")

$readme = @"
# 今日发布包

生成时间：$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

使用方式：

1. 打开平台后台。
2. 复制对应目录里的 `title.txt` 和 `body.md`。
3. 上传 `cover.png`。
4. 小红书额外复制 `tags.txt`。
5. 发布前按 `checklist.md` 检查。
6. 发布后把链接和数据回填飞书 `发布复盘库`。

目录：

- `01_toutiao`：头条发布包
- `02_xiaohongshu`：小红书发布包
"@

Write-Utf8File (Join-Path $todayDir "README.md") $readme
Write-Host "已生成今日发布包：$todayDir"

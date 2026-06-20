. "$PSScriptRoot\common.ps1"

$root = Get-ProjectRoot
$draftPath = Join-Path $root "output\drafts.json"
$packPath = Join-Path $root "output\publish_pack.md"

if (-not (Test-Path $draftPath)) {
  throw "未找到 $draftPath，请先运行 sync_feishu_drafts.ps1"
}

$drafts = Get-Content -Raw $draftPath | ConvertFrom-Json
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# 发布包")
$lines.Add("")
$lines.Add("生成时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$lines.Add("")

foreach ($draft in $drafts) {
  $coverPath = "output/covers/$($draft.slug)-$($draft.platform).png"
  $lines.Add("## $($draft.platform)：$($draft.title)")
  $lines.Add("")
  $lines.Add("标题：$($draft.title)")
  $lines.Add("")
  $lines.Add("封面：$coverPath")
  $lines.Add("")
  if ($draft.platform -eq "小红书") {
    $lines.Add("建议标签：#程序员 #失业日记 #程序员转型 #技术变现 #副业探索 #内容创作 #自我成长")
    $lines.Add("")
  }
  $lines.Add("正文：")
  $lines.Add("")
  $lines.Add($draft.body)
  $lines.Add("")
  $lines.Add("---")
  $lines.Add("")
}

$lines | Set-Content -Encoding UTF8 $packPath
Write-Host "已生成发布包：$packPath"

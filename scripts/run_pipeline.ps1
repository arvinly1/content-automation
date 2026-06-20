$ErrorActionPreference = "Stop"

& "$PSScriptRoot\sync_feishu_drafts.ps1"

$root = Split-Path -Parent $PSScriptRoot
$draftPath = Join-Path $root "output\drafts.json"
$drafts = Get-Content -Raw $draftPath | ConvertFrom-Json
if ($null -eq $drafts -or $drafts.Count -eq 0) {
  Write-Host ""
  Write-Host "没有待发布草稿，本次不生成发布包。"
  Write-Host "请先在飞书内容成稿库中把要发布的记录状态改为：待发布"
  exit 0
}

& "$PSScriptRoot\generate_covers.ps1"
& "$PSScriptRoot\generate_publish_pack.ps1"
& "$PSScriptRoot\generate_today_publish.ps1"
& "$PSScriptRoot\generate_static_site.ps1"

Write-Host ""
Write-Host "内容自动化流水线已完成。"

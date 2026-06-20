$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

# Prefer environment variables so local secrets are not written to git.
if (-not $env:FEISHU_APP_ID -or -not $env:FEISHU_APP_SECRET) {
  $localConfig = Join-Path $projectRoot "config.local.psd1"
  if (-not (Test-Path $localConfig)) {
    throw "缺少飞书配置。请设置环境变量 FEISHU_APP_ID / FEISHU_APP_SECRET，或创建 config.local.psd1。"
  }
}

if (-not $env:SITE_BASE_URL) {
  $env:SITE_BASE_URL = "https://arvinly1.github.io/content-automation"
}

& "$PSScriptRoot\run_pipeline.ps1"

Write-Host ""
Write-Host "今日发布包已生成：$projectRoot\today_publish"
Write-Host "打开 today_publish\publish-helper.html，按顺序复制标题、正文并上传封面。"

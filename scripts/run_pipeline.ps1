$ErrorActionPreference = "Stop"

& "$PSScriptRoot\sync_feishu_drafts.ps1"
& "$PSScriptRoot\generate_covers.ps1"
& "$PSScriptRoot\generate_publish_pack.ps1"
& "$PSScriptRoot\generate_static_site.ps1"

Write-Host ""
Write-Host "内容自动化流水线已完成。"

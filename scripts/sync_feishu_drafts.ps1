. "$PSScriptRoot\common.ps1"

$root = Get-ProjectRoot
$outputDir = Join-Path $root "output"
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

$config = Get-ContentAutomationConfig
$token = Get-FeishuTenantToken -Config $config
$headers = @{ Authorization = "Bearer $token" }

$appToken = $config.Feishu.AppToken
$tableId = $config.Feishu.DraftTableId
$uri = "https://open.feishu.cn/open-apis/bitable/v1/apps/$appToken/tables/$tableId/records?page_size=100"
$resp = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers

$drafts = @(
foreach ($item in $resp.data.items) {
  $fields = $item.fields
  $status = Convert-PlainText $fields."状态"
  if ($status -ne "待发布") { continue }

  [pscustomobject]@{
    record_id = $item.record_id
    title = Convert-PlainText $fields."成稿标题"
    platform = Convert-PlainText $fields."平台版本"
    format = Convert-PlainText $fields."内容形式"
    body = Convert-PlainText $fields."正文"
    cover_notes = Convert-PlainText $fields."封面/配图建议"
    slug = New-Slug ((Convert-PlainText $fields."成稿标题") + $item.record_id)
    synced_at = (Get-Date).ToString("s")
  }
}
)

$path = Join-Path $outputDir "drafts.json"
$drafts | ConvertTo-Json -Depth 20 | Set-Content -Encoding UTF8 $path
Write-Host "已同步待发布草稿：$($drafts.Count) 条 -> $path"

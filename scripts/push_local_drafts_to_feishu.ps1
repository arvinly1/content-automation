param(
  [string]$DraftDir = "",
  [switch]$Force
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\common.ps1"

$root = Get-ProjectRoot
if (-not $DraftDir) {
  $DraftDir = Join-Path $root "content_drafts"
}

if (-not (Test-Path $DraftDir)) {
  throw "未找到本地草稿目录：$DraftDir"
}

function Read-LocalDraft {
  param([string]$Path)

  $raw = Get-Content -Raw -Encoding UTF8 $Path
  $match = [regex]::Match($raw, "(?s)^---\s*\r?\n(.*?)\r?\n---\s*\r?\n(.*)$")
  if (-not $match.Success) {
    throw "草稿缺少 front matter：$Path"
  }

  $meta = @{}
  foreach ($line in ($match.Groups[1].Value -split "\r?\n")) {
    if (-not $line.Trim()) { continue }
    $parts = $line -split ":", 2
    if ($parts.Count -ne 2) {
      throw "front matter 格式错误：$Path -> $line"
    }
    $meta[$parts[0].Trim()] = $parts[1].Trim()
  }

  foreach ($required in @("title", "platform", "format", "status")) {
    if (-not $meta.ContainsKey($required) -or -not $meta[$required]) {
      throw "草稿缺少字段 $required：$Path"
    }
  }

  [pscustomobject]@{
    Path = $Path
    Title = $meta.title
    Platform = $meta.platform
    Format = $meta.format
    Status = $meta.status
    CoverNotes = if ($meta.cover_notes) { $meta.cover_notes } else { "" }
    Body = $match.Groups[2].Value.Trim()
  }
}

function Get-AllFeishuRecords {
  param(
    [string]$AppToken,
    [string]$TableId,
    [hashtable]$Headers
  )

  $records = New-Object System.Collections.Generic.List[object]
  $pageToken = ""
  do {
    $uri = "https://open.feishu.cn/open-apis/bitable/v1/apps/$AppToken/tables/$TableId/records?page_size=100"
    if ($pageToken) {
      $uri = "$uri&page_token=$pageToken"
    }

    $resp = Invoke-RestMethod -Method Get -Uri $uri -Headers $Headers
    foreach ($item in $resp.data.items) {
      $records.Add($item)
    }
    $pageToken = $resp.data.page_token
  } while ($pageToken)

  return $records
}

$config = Get-ContentAutomationConfig
$token = Get-FeishuTenantToken -Config $config
$headers = @{ Authorization = "Bearer $token" }
$appToken = $config.Feishu.AppToken
$tableId = $config.Feishu.DraftTableId

$existing = Get-AllFeishuRecords -AppToken $appToken -TableId $tableId -Headers $headers
$drafts = Get-ChildItem -Path $DraftDir -Filter *.md -File | Sort-Object Name | ForEach-Object {
  Read-LocalDraft -Path $_.FullName
}

if (-not $drafts -or $drafts.Count -eq 0) {
  Write-Host "没有找到本地草稿：$DraftDir"
  exit 0
}

$created = 0
$updated = 0
$skipped = 0

foreach ($draft in $drafts) {
  $matched = $existing | Where-Object {
    (Convert-PlainText $_.fields."成稿标题") -eq $draft.Title -and
    (Convert-PlainText $_.fields."平台版本") -eq $draft.Platform
  } | Select-Object -First 1

  $fields = @{
    "成稿标题" = $draft.Title
    "平台版本" = $draft.Platform
    "内容形式" = $draft.Format
    "正文" = $draft.Body
    "封面/配图建议" = $draft.CoverNotes
    "状态" = $draft.Status
  }

  $body = @{ fields = $fields } | ConvertTo-Json -Depth 10

  if ($matched -and -not $Force) {
    Write-Host "已存在，跳过：$($draft.Platform) / $($draft.Title)"
    $skipped++
    continue
  }

  if ($matched -and $Force) {
    $recordId = $matched.record_id
    $uri = "https://open.feishu.cn/open-apis/bitable/v1/apps/$appToken/tables/$tableId/records/$recordId"
    Invoke-RestMethod -Method Put -Uri $uri -Headers $headers -ContentType "application/json" -Body $body | Out-Null
    Write-Host "已更新：$($draft.Platform) / $($draft.Title)"
    $updated++
    continue
  }

  $uri = "https://open.feishu.cn/open-apis/bitable/v1/apps/$appToken/tables/$tableId/records"
  Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -ContentType "application/json" -Body $body | Out-Null
  Write-Host "已创建：$($draft.Platform) / $($draft.Title)"
  $created++
}

Write-Host ""
Write-Host "本地草稿同步完成：创建 $created，更新 $updated，跳过 $skipped。"

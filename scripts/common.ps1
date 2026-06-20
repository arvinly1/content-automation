$ErrorActionPreference = "Stop"

function Get-ProjectRoot {
  Split-Path -Parent $PSScriptRoot
}

function Get-ContentAutomationConfig {
  $root = Get-ProjectRoot
  $examplePath = Join-Path $root "config.example.psd1"
  $localPath = Join-Path $root "config.local.psd1"

  $config = Import-PowerShellDataFile $examplePath
  if (Test-Path $localPath) {
    $local = Import-PowerShellDataFile $localPath
    foreach ($section in $local.Keys) {
      if (-not $config.ContainsKey($section)) { $config[$section] = @{} }
      foreach ($key in $local[$section].Keys) {
        $config[$section][$key] = $local[$section][$key]
      }
    }
  }

  if ($env:FEISHU_APP_ID) { $config.Feishu.AppId = $env:FEISHU_APP_ID }
  if ($env:FEISHU_APP_SECRET) { $config.Feishu.AppSecret = $env:FEISHU_APP_SECRET }
  if ($env:SITE_BASE_URL) { $config.Site.BaseUrl = $env:SITE_BASE_URL }
  if ($env:SITE_TITLE) { $config.Site.Title = $env:SITE_TITLE }
  if ($env:SITE_AUTHOR) { $config.Site.Author = $env:SITE_AUTHOR }

  if (-not $config.Feishu.AppId -or -not $config.Feishu.AppSecret) {
    throw "缺少飞书 AppId/AppSecret。请设置 config.local.psd1 或 FEISHU_APP_ID / FEISHU_APP_SECRET 环境变量。"
  }

  return $config
}

function Get-FeishuTenantToken {
  param([hashtable]$Config)

  $body = @{
    app_id = $Config.Feishu.AppId
    app_secret = $Config.Feishu.AppSecret
  } | ConvertTo-Json

  $resp = Invoke-RestMethod `
    -Method Post `
    -Uri "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal" `
    -ContentType "application/json" `
    -Body $body

  return $resp.tenant_access_token
}

function Convert-PlainText {
  param($Value)

  if ($null -eq $Value) { return "" }
  if ($Value -is [string]) { return $Value }
  if ($Value.text) { return ($Value.text -join "") }
  return [string]$Value
}

function New-Slug {
  param([string]$Text)

  $sha1 = [System.Security.Cryptography.SHA1]::Create()
  try {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $hash = [System.BitConverter]::ToString($sha1.ComputeHash($bytes)).Replace("-", "").Substring(0, 10).ToLowerInvariant()
  } finally {
    $sha1.Dispose()
  }

  return "post-$hash"
}

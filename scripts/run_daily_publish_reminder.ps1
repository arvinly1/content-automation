$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$logDir = Join-Path $projectRoot "output\logs"
$logPath = Join-Path $logDir ("daily-publish-{0}.log" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
$helperPath = Join-Path $projectRoot "today_publish\publish-helper.html"

New-Item -ItemType Directory -Force -Path $logDir | Out-Null

function Show-Reminder {
  param(
    [string]$Title,
    [string]$Message
  )

  Add-Type -AssemblyName System.Windows.Forms
  [System.Windows.Forms.MessageBox]::Show(
    $Message,
    $Title,
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Information
  ) | Out-Null
}

try {
  Set-Location $projectRoot
  "[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] start daily publish pipeline" | Tee-Object -FilePath $logPath

  & "$PSScriptRoot\run_daily_publish.ps1" *>&1 | Tee-Object -FilePath $logPath -Append

  if (-not (Test-Path $helperPath)) {
    throw "未生成发布助手页面：$helperPath"
  }

  Start-Process $helperPath

  $message = @"
今日内容发布包已经生成。

请打开发布助手页面，按顺序完成：

1. 复制头条标题和正文，上传封面，检查后发布
2. 复制小红书标题、正文、标签，上传封面，检查后发布
3. 发布后把链接、阅读、点赞、收藏、评论回填飞书发布复盘库
4. 晚上或明天观察 2 小时 / 24 小时数据

发布助手：
$helperPath

日志：
$logPath
"@

  Show-Reminder -Title "今日发布包已生成" -Message $message
  "[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] done" | Tee-Object -FilePath $logPath -Append
} catch {
  $errorMessage = $_.Exception.Message
  "[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] failed: $errorMessage" | Tee-Object -FilePath $logPath -Append

  Show-Reminder -Title "今日发布包生成失败" -Message @"
自动生成流程失败了。

错误：
$errorMessage

日志：
$logPath
"@

  exit 1
}

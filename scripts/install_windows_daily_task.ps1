param(
  [string]$TaskName = "内容发布包每日生成",
  [string]$At = "10:00"
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $PSScriptRoot "run_daily_publish_reminder.ps1"
$pwsh = (Get-Command pwsh.exe -ErrorAction SilentlyContinue).Source
$powershellExe = if ($pwsh) { $pwsh } else { "powershell.exe" }

if (-not (Test-Path $runner)) {
  throw "未找到执行脚本：$runner"
}

$time = [datetime]::ParseExact($At, "HH:mm", $null)
$action = New-ScheduledTaskAction `
  -Execute $powershellExe `
  -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$runner`"" `
  -WorkingDirectory $projectRoot

$trigger = New-ScheduledTaskTrigger -Daily -At $time
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet `
  -StartWhenAvailable `
  -AllowStartIfOnBatteries `
  -DontStopIfGoingOnBatteries `
  -MultipleInstances IgnoreNew

$task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Settings $settings
Register-ScheduledTask -TaskName $TaskName -InputObject $task -Force | Out-Null

Write-Host "已创建/更新 Windows 计划任务：$TaskName"
Write-Host "执行时间：每天 $At"
Write-Host "执行程序：$powershellExe"
Write-Host "执行脚本：$runner"
Write-Host ""
Write-Host "可手动测试："
Write-Host "Start-ScheduledTask -TaskName `"$TaskName`""

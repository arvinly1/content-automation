# Windows 定时生成发布包

目标：每天定时运行脚本，自动从飞书拉取待发布内容，生成 `today_publish/` 文件夹，并打开 `publish-helper.html` 提醒你发布。

## 方式一：手动运行

```powershell
cd F:\work\content-automation
$env:FEISHU_APP_ID = "你的 AppId"
$env:FEISHU_APP_SECRET = "你的 AppSecret"
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_daily_publish.ps1
```

生成后打开：

```text
F:\work\content-automation\today_publish
```

## 方式二：Windows 任务计划程序

推荐直接运行安装脚本：

```powershell
cd F:\work\content-automation
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\install_windows_daily_task.ps1 -At 10:00
```

它会创建/更新一个 Windows 计划任务：

- 名称：`内容发布包每日生成`
- 时间：每天 `10:00`
- 动作：使用 PowerShell 7 运行 `scripts\run_daily_publish_reminder.ps1`
- 效果：生成发布包，打开发布助手页，并弹窗提醒你人工发布和观察数据

手动测试：

```powershell
Start-ScheduledTask -TaskName "内容发布包每日生成"
```

也可以手动通过图形界面创建：

1. 打开 Windows `任务计划程序`
2. 点击 `创建基本任务`
3. 名称：`内容发布包每日生成`
4. 触发器：每天，例如 `10:00`
5. 操作：启动程序
6. 程序或脚本：

   ```text
   pwsh.exe
   ```

7. 添加参数：

   ```text
   -NoProfile -ExecutionPolicy Bypass -File "F:\work\content-automation\scripts\run_daily_publish_reminder.ps1"
   ```

8. 起始于：

   ```text
   F:\work\content-automation
   ```

## 本地密钥配置

推荐创建本地配置文件：

```powershell
Copy-Item F:\work\content-automation\config.example.psd1 F:\work\content-automation\config.local.psd1
```

然后编辑 `config.local.psd1`，填入飞书 `AppId` 和 `AppSecret`。

`config.local.psd1` 已被 `.gitignore` 忽略，不会提交到 GitHub。

## 每天发布动作

定时任务只负责生成素材和打开发布助手，不会自动发平台。

你每天只需要：

1. 打开 `today_publish/publish-helper.html`
2. 点击按钮复制头条标题、正文，上传封面，按清单检查后发布
3. 点击按钮复制小红书标题、正文、标签，上传封面，按清单检查后发布
4. 发布后把链接和数据回填飞书 `发布复盘库`
5. 观察 2 小时 / 24 小时 / 72 小时数据：阅读、点赞、收藏、评论、转粉、收益

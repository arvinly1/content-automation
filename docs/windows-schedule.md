# Windows 定时生成发布包

目标：每天定时运行脚本，自动从飞书拉取待发布内容，生成 `today_publish/` 文件夹。

## 方式一：手动运行

```powershell
cd F:\work\content-automation
$env:FEISHU_APP_ID = "你的 AppId"
$env:FEISHU_APP_SECRET = "你的 AppSecret"
.\scripts\run_daily_publish.ps1
```

生成后打开：

```text
F:\work\content-automation\today_publish
```

## 方式二：Windows 任务计划程序

1. 打开 Windows `任务计划程序`
2. 点击 `创建基本任务`
3. 名称：`内容发布包每日生成`
4. 触发器：每天，例如 `09:30`
5. 操作：启动程序
6. 程序或脚本：

   ```text
   powershell.exe
   ```

7. 添加参数：

   ```text
   -NoProfile -ExecutionPolicy Bypass -File "F:\work\content-automation\scripts\run_daily_publish.ps1"
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

定时任务只负责生成素材，不会自动发平台。

你每天只需要：

1. 打开 `today_publish/01_toutiao`
2. 复制 `title.txt` 和 `body.md`
3. 上传 `cover.png`
4. 按 `checklist.md` 检查后发布
5. 打开 `today_publish/02_xiaohongshu`
6. 复制标题、正文、标签，上传封面
7. 发布后把链接和数据回填飞书

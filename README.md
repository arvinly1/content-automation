# 程序员转型内容自动化

这个项目用于把飞书里的待发布内容，自动整理成可发布资产：

- 从飞书多维表格读取 `待发布` 草稿
- 生成平台发布包 Markdown
- 生成头条/小红书封面图
- 生成可部署的静态文章页和 RSS Feed
- 为头条号“内容源/RSS接入”做中期自动化准备

## 当前策略

短期：

- 小红书：生成发布包和封面，人工最后确认发布。
- 头条：生成发布包，同时生成 RSS Feed，后续尝试走官方内容源接入。

中期：

- 把 `public/` 目录部署到一个稳定域名。
- 用 `public/rss.xml` 作为头条内容源。
- 飞书继续作为内容中台，脚本负责编排。

## 配置

复制配置模板：

```powershell
Copy-Item .\config.example.psd1 .\config.local.psd1
```

编辑 `config.local.psd1`，填入飞书应用信息。也可以使用环境变量：

```powershell
$env:FEISHU_APP_ID = "cli_xxx"
$env:FEISHU_APP_SECRET = "xxx"
```

## 一键生成

```powershell
.\scripts\run_pipeline.ps1
```

输出目录：

- `output/drafts.json`：飞书待发布草稿
- `output/publish_pack.md`：复制发布包
- `output/covers/*.png`：平台封面
- `today_publish/`：今天要手动发布的分平台文件夹
- `public/articles/*.html`：静态文章页
- `public/rss.xml`：RSS Feed

## 每天发布

运行流水线后，打开：

```text
today_publish/
```

里面会自动生成：

```text
today_publish/
  01_toutiao/
    title.txt
    body.md
    cover.png
    checklist.md
    meta.json
  02_xiaohongshu/
    title.txt
    body.md
    cover.png
    tags.txt
    checklist.md
    meta.json
```

发布时只需要复制标题和正文，上传封面，按清单检查。发布完成后，把链接和数据回填飞书 `发布复盘库`。

## 定时生成

见 [docs/windows-schedule.md](docs/windows-schedule.md)。

## 部署到 GitHub Pages

见 [docs/github-pages.md](docs/github-pages.md)。

## 注意

不要把 `config.local.psd1` 提交或分享出去。你之前已经把密钥发到聊天里，流程跑通后建议重置一次飞书应用密钥。

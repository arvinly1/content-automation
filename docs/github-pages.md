# GitHub Pages 部署

## 方案

这个项目使用 GitHub Actions 部署 `public/` 目录。

推送到 `main` 分支后，`.github/workflows/pages.yml` 会自动把 `public/` 发布到 GitHub Pages。

## 首次部署步骤

1. 在 GitHub 新建一个空仓库，例如：

   `content-automation`

2. 在仓库 Settings -> Pages 里，把 Source 设置为：

   `GitHub Actions`

3. 本地设置站点地址：

   ```powershell
   $env:SITE_BASE_URL = "https://你的GitHub用户名.github.io/content-automation"
   ```

4. 重新生成 RSS：

   ```powershell
   .\scripts\run_pipeline.ps1
   ```

5. 初始化并推送：

   ```powershell
   git init
   git add .
   git commit -m "Initialize content automation"
   git branch -M main
   git remote add origin https://github.com/你的GitHub用户名/content-automation.git
   git push -u origin main
   ```

6. 部署完成后，RSS 地址通常是：

   `https://你的GitHub用户名.github.io/content-automation/rss.xml`

## 后续更新

飞书里有新稿件后：

```powershell
$env:SITE_BASE_URL = "https://你的GitHub用户名.github.io/content-automation"
.\scripts\run_pipeline.ps1
git add output public
git commit -m "Update published content"
git push
```

## 头条接入

在头条号后台申请或配置内容源时，优先使用：

```text
https://你的GitHub用户名.github.io/content-automation/rss.xml
```

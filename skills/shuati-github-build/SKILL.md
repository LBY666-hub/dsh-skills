---
name: shuati-github-build
description: 从用户上传的考试 Word 题库（docx 试题 + 配套答案）构建一个离线可用的刷题 PWA（纯前端静态单页应用：单选/多选/判断/案例分析，每题含选项、正确答案、知识点详解，做题记录存浏览器 localStorage，支持深浅主题、错题本、统计数据），并把整套文件推送到 GitHub 公开仓库并开启 GitHub Pages 部署到手机。用于"把题库做成刷题小程序/刷题软件/刷题应用、发布到 GitHub/GitHub Pages、装到手机、离线刷题"等需求。
---

# 刷题 App 构建 + 发布到 GitHub 全流程

目标产物：一个**纯前端静态 PWA**（无后端、无数据库、数据保存在各设备浏览器 localStorage）。做完后可**本地双击打开**，也可**发布到 GitHub Pages 装到手机离线使用**。

## 术语与核心认知
- 这是**没有任何后端的静态网页**：只包含 HTML/CSS/JS + 题库数据文件。
- **做题记录、错题、统计、主题偏好**全部存在**用户自己设备的浏览器 localStorage**，不上传服务器、不上 GitHub、别人看不到，**按设备/浏览器隔离**。
- 若要"能看所有人成绩"的多用户统计，必须另加后端+数据库；本流程默认不涉及。

## 一、读入题库（从 docx）
1. 用 `read_document` 读 `试题N.docx` 与 `试题N答案.docx`（`read_document` 会把 docx 转成 Markdown 分页返回；若内容被截断或在表格里，用 `pwsh` 解压 `word/document.xml` 提取纯文本）。
2. 记录每套试卷结构：通常为 单选 / 多选 / 判断 / 案例分析 四个部分，并抄录**答案**。
3. 常见题量为：单选 30 + 多选 30 + 判断 20 + 案例 10 ≈ 每套 90 题。

## 二、题库数据结构（data/paperN.js）
每题一个对象：
```js
{ q: "题目", o: ["A. 选项一","B. 选项二","C. 选项三","D. 选项四"], a: "B", note: "知识点详解" }
```
- 单选：`a` 单字母，如 `B`。
- 多选 / 案例：`a` 多个字母，如 `ABCD`。
- 判断：`a` 取 `√` 或 `×`（`o` 可省略，应用内置 √/× 两选项）。
- 案例：每套的案例分析先录案例文本（题目+长文材料），再列其题目。
- 聚合文件 `data/data.js`：`window.DATA = [PAPER1, PAPER2, PAPER3];`

> 关键正确性：答案一定要**逐题对照原始答案文档**，用 node 脚本比对（题量、答案格式合法：`/^[ABCD]$/`、`/^[A-D]+$/`、`/^[√×]$/`），并对判分逻辑做单测（单选/多选漏选错选/判断/案例）。

## 三、应用结构（核心文件）
- `index.html`：入口，含头部（标题+主题切换按钮）+ 主内容 `#view` + 底部 4 个 Tab（刷题/错题本/统计/更多）+ 依次引入 data/*.js 与 app.js；末尾注册 Service Worker。
- `style.css`：用 CSS 变量做**深浅主题**；用 `:root`（深色）与 `[data-theme="light"]`（浅色）覆盖；突出**选项面板**（`--opt` 浅色+明显描边，避免深色下看不清）。
- `app.js`：IIFE，含存储（localStorage 键 `mb_records_v1`/`mb_state_v1`/`mb_theme`）、`buildItems()`（把四种题型按 单选→多选→判断→案例 拼成题列表）、判分 `isCorrect`、首页/刷题/错题本/统计/更多 视图、主题切换。暴露 `window.renderHome`。
- `manifest.webmanifest`：PWA 清单（name/short_name/start_url/display standalone/theme_color/icons）。
- `sw.js`：Service Worker，缓存核心资产实现离线；`CACHE` 版本号改动即刷新缓存。
- `icons/icon.svg`：应用图标（用 SVG 文本而非 PNG，便于走文本上传接口）。

### 刷题模式与顺序
顺序练习 = `buildItems` 的固定顺序：单选→多选→判断→案例分析。另提供 单选/多选/判断/案例专练、随机、错题重练、未做重练。

## 四、常见 Bug 与规避（重要）
- **动态 class 拼接**：拼 HTML 时，动态类名**必须放在引号内**。
  正确：`'<button class="btn'+(i===pi?' primary':'')+'" data-paper="'+i+'">...'`
  错误：`'<button class="btn"'+(i===pi?' primary':'')+' data-paper=...'`（会把 `primary` 变成裸属性，导致选中不显示样式、看起来"点了没反应"）。**这是最容易出现的隐蔽 bug**。
- 多选需"确认答案"按钮，单选/判断点即判分；作答后置只读并高亮正确/错误选项 + 显示答案解析。
- "错题重练 / 单题复习"要先清掉该题旧记录（`fresh`），否则会显示为只读无法重做。

## 五、本地预览
- 双击 `index.html` 可用（file://）。PWA/离线须 HTTP。
- 需要静态服务器时，在 `刷题App` 目录起 `http.server`/`node`，访问 `http://127.0.0.1:<port>/index.html`。

## 六、发布到 GitHub Pages
1. **前置**：准备一个 GitHub **Personal Access Token**，权限为：
   - 细粒度令牌：**Repository permissions → Contents：Read and write**（必填），Metadata：Read（强制）。
   - 若要**自动创建仓库**，还需 **Account/Repository Administration：Read and write**；否则手动建仓库更省事。
   - 关键坑：令牌页选"Public repositories"= **只读**，无法推送；必须改成 "Only select repositories" 选目标仓库 + Contents 读写。
2. 若无同名仓库：GitHub → New repository（Public），仓库名如 `marketing-brush-app`。
3. 上传文件：用 GitHub MCP（`mcp__github__push_files`，需带 `message`；或 `create_or_update_file`）。`README.md`、`启动.bat`（本地双击启动）、`.nojekyll`（跳过 Jekyll 以纯静态发布）一并上传。
   - **在仓库根加一个空 `.nojekyll`**，更稳。
4. **开启 Pages**：仓库 Settings → Pages → Source: **Deploy from a branch** → Branch `main`，Folder `/ (root)` → Save。
5. 首次部署 1~5 分钟，期间访问会 404（正常），看 Actions 里 `pages-build-deployment` 是否变绿。
6. 站点地址：`https://<用户名>.github.io/<仓库名>/`。

## 七、发布后的验证与排查
- **不要只测一次**：强刷（Ctrl+Shift+R）后再验证；检查 选题高亮、顺序练习、多选确认、错题本、统计、刷新后记录是否保留。
- 线上异常时**对比本地版与部署版**行为差异，优先检查**代码生成逻辑（模板字符串拼接）**，而非 UI 框架。
- MCP 推送 `fetch failed`/显示"连接异常"时：先查 token 权限与仓库存在性，再排除文件大小，最后判定为**临时网络/限流**，等待重试；此时可用轻量调用（如 get_me）实测是否真断。
- **安全边界**：仓库公开则代码所有人可见，但做题数据在用户本地、不会因此泄露；不要往 skill/README 里写 token 等敏感信息。

## 八、交付文案
交付时说明：功能清单、本地打开方式（双击 index.html / 启动.bat）、需要什么（现代浏览器，无需联网）、网络配置（本地无网络；装手机需 HTTPS 托管如 GitHub Pages）、更新时间、数据存储与隐私（localStorage 按设备隔离、导出备份）、怎么加题改题（data/paperN.js 改 q/o/a/note）、FAQ。

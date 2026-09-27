---
name: github-up
description: 把产出推送到 GitHub 的标准流程（交互式七步）—— 用户以 /github-up 调用并说明要推的产出后，依次推进：①确认目标仓库与可见性（默认公开） ②敏感信息与大文件体检 ③本地 git 准备与提交 ④建远端仓库 ⑤推送（本机 git + Git Credential Manager）⑥用 GitHub 连接读回验证 ⑦按需开启 GitHub Pages。适用于报告、代码、数据集、网页应用、技能库等**任意产出**。未确认"推什么 / 推到哪个仓库 / 公开还是私有"之前，不得推送。
disable-model-invocation: true
---

# 推送到 GitHub（github-up）

> ⚠️ 命令名是 **`/github-up`**（连字符）。DSH 的技能名只允许 `^[a-z0-9]+(?:-[a-z0-9]+)*$` —— **下划线、大写、中文都会被加载器忽略**，所以原本设想的 `/github_up` 不可用。

一句话流程：**你说要推什么 → 我确认仓库与可见性 → 体检 → 本地提交 → 建远端 → 推送 → 读回验证 → （需要就）开 Pages。**

---

## 0. 铁律

| 编号 | 铁律 |
|---|---|
| **R1 先问后推** | 推送前必须让用户确认三件事：**推什么**（文件/目录）、**推到哪个仓库**（新建还是已有）、**可见性**。缺一项就只问那一项。 |
| **R2 可见性默认公开** | 用户的既定偏好是**公开**仓库（其名下 `marketing-brush-app`、`dsh-skills` 均为公开）→ **默认按公开建议**；只有用户明确说"私有"时才建私有。若内容含未发表数据或密钥，我可以提醒一句风险，但**以用户指令为准**。 |
| **R3 密钥绝不外泄** | 推送前必须跑敏感信息扫描；命中就停下来问用户，**先处理再推**。默认公开放大了这条的重要性。任何情况下不打印 token/密钥/序列号。 |
| **R4 不推垃圾** | 大文件（>50 MB 提醒、>100 MB 拒绝）、`node_modules/`、`.venv/`、模型权重、构建产物、临时文件，先排除或写进 `.gitignore`。 |
| **R5 读回验证** | 推完必须用 GitHub 连接**读回**仓库文件清单 + 提交号，并与本机 `git rev-parse HEAD` 比对一致，再报告完成。 |
| **R6 失败即披露** | 报错就贴原文（含 HTTP 状态码）+ 我的判断与处置；不静默换路、不谎报成功。 |
| **R7 误推即补救** | 若已推上敏感文件：`git rm --cached` + 提交 + 推送，并**提醒轮换该密钥**（历史仍在，必要时用 filter-repo 清史）。 |

---

## 1. Step 1｜确认三件事（缺哪问哪）

```
【推什么】<文件/目录的绝对路径；若在会话工作区就直接给相对路径>
【推到哪】新建仓库 <名字>  ／ 已有仓库 <LBY666-hub/xxx>
【可见性】公开（默认）／私有
【提交信息】<可选，不给就由我按内容拟一句>
```

判断"是不是技能产出"：**是 → 走 §8 的技能库流程**；否则走下面的通用流程。

---

## 2. Step 2｜出发前体检（必做，结果要报给用户）

```powershell
$target = "<要推的目录>"

# ① 敏感信息扫描（命中即停）
$pat = 'sk-[A-Za-z0-9]{10,}|ghp_[A-Za-z0-9]{20,}|github_pat_|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|(password|passwd|pwd|api[_-]?key|apikey|token|secret|序列号|注册码)\s*[:=]\s*\S|\b1[3-9]\d{9}\b'
Get-ChildItem $target -Recurse -Force -File -ErrorAction SilentlyContinue | Select-String -Pattern $pat | Select-Object -First 20 Path, LineNumber, Line

# ② 大文件（>50 MB 列出，>100 MB 必须处理）
Get-ChildItem $target -Recurse -Force -File | Where-Object Length -gt 50MB |
  Sort-Object Length -Descending | Select-Object @{n='MB';e={[math]::Round($_.Length/1MB,1)}}, FullName

# ③ 体积与文件数概览
$f = Get-ChildItem $target -Recurse -Force -File
"文件数 {0}，合计 {1} MB" -f $f.Count, [math]::Round((($f | Measure-Object Length -Sum).Sum)/1MB,1)
```

体检通过后给用户一句结论：`文件 N 个 / 合计 X MB / 敏感命中 0 处 / 大文件 0 个`。

---

## 3. Step 3｜本地仓库准备

```powershell
Set-Location "<目标目录>"
if (-not (Test-Path .git)) { git init -b main }      # 已存在则跳过

# .gitignore（按需裁剪，至少排除这些）
@'
node_modules/
.venv/
__pycache__/
dist/
build/
*.bak-*
~$*
.DS_Store
Thumbs.db
'@ | Set-Content ".gitignore" -Encoding utf8

git add -A
git status --short | Select-Object -First 30            # 让用户过一眼要提交什么
git -c user.name="LBY666-hub" -c user.email="15762959246@163.com" commit -m "<提交信息>"
git log --oneline | Select-Object -First 3
```

> 本机 git 全局身份已是 `LBY666-hub / 15762959246@163.com`，`-c` 只是显式兜底。

---

## 4. Step 4｜建远端仓库

**⚠️ 不能用 DSH 的 GitHub 连接建仓**：那条连接（key `github-github`，bearer → `https://api.githubcopilot.com/mcp/`）是**只读令牌**，`create_repository` 与 `push_files` 都会返回
`403 Resource not accessible by personal access token`。

所以**默认走"网页建仓 + 本机 git 推送"**（今天实测可用）：

1. 让用户打开 https://github.com/new
2. 填 **Repository name**（小写 kebab-case，如 `my-report-2026`）、**Description**（可选）
3. **Choose visibility** 选 **Public**（默认）；只有用户明确要私有时才选 Private
4. **Add README / .gitignore / license 全部留空**（保持空仓，避免多一次 Initial commit 造成历史分叉）
5. 点 Create repository，用户回一句"建好了"
6. 我设 remote：
   ```powershell
   git remote add origin https://github.com/LBY666-hub/<repo>.git
   git remote -v
   ```

（若用户想让我以后也能**自动建仓**：需要给令牌加 `Administration: Read and write`（fine-grained）或 `repo`（classic），见 §9 失败矩阵。）

---

## 5. Step 5｜推送（本机 git + GCM，已验证可用）

```powershell
Set-Location "<目标目录>"
git -c credential.helper=manager push -u origin main
```

- **为什么带 `-c credential.helper=manager`**：本机全局 `credential.helper` 是**空值**，在 Git 里等于"清空助手列表"，会挡住系统级的 `manager`。加上这个参数即强制启用 Git Credential Manager。
- **首次会弹 GitHub 授权窗口**：让用户在弹窗里选 GitHub → Sign in with your browser → 浏览器点 Authorize。凭据会存进 Windows 凭据管理器（`git:https://github.com`），**以后免密**。
- **耗时不可控（要等人操作）→ 用后台任务**：`run_in_background: true`，然后告诉用户"现在去完成弹窗授权"；完成后读任务输出。
- 推完立刻看状态：
  ```powershell
  git status -sb | Select-Object -First 2
  git rev-parse --short HEAD; git rev-parse --short origin/main
  ```

**备选路线（无弹窗环境，或 GCM 不可用时）** —— 需要用户先在自己终端 `setx GITHUB_TOKEN <PAT>`：

```powershell
$h = "AUTHORIZATION: basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("x-access-token:$env:GITHUB_TOKEN"))
git -c http.extraheader=$h push -u origin main      # 不打印 token
```

---

## 6. Step 6｜读回验证（必须做）

用 DSH 的 GitHub 连接（读操作正常）：

- `get_file_contents`：`owner=LBY666-hub`、`repo=<仓库>`、`path=/`、`ref=refs/heads/main`（fields: name/type/size）→ 对照本机 `git ls-files`
- `list_commits`（perPage 3）→ 提交号、作者、时间
- 本机比对：`git rev-parse HEAD` == `git rev-parse origin/main`，且 `git status --porcelain` 为空

三项一致才算成功，否则按 §9 排查。

---

## 7. Step 7｜GitHub Pages（仅当产出是网页/静态站点）

1. 仓库 **Settings → Pages → Source: Deploy from a branch → Branch `main` / Folder `/ (root)` → Save**
2. 根目录放一个空的 **`.nojekyll`**（跳过 Jekyll，纯静态更稳）
3. 首次部署 1~5 分钟，期间访问 404 属正常；看 Actions 里 `pages-build-deployment` 变绿
4. 站点地址：`https://LBY666-hub.github.io/<repo>/`
5. MCP **没有** Pages 工具，这步只能引导用户在 GUI 点（或等装了 `gh` 用 `gh api`）

---

## 8. 特例：产出本身就是「DSH 技能」

走技能库标准动作（库 = 唯一维护入口）：

```powershell
$lib = "D:\刘宝阳\个人知识库\03-计算机与大模型\dsh学习\DSH技能库"
# 1) 放技能：$lib\skills\<技能名>\SKILL.md（名字只能 [a-z0-9-]）
# 2) 安装到运行副本并实测
pwsh -File "$lib\install.ps1" -Skill <技能名>
# 3) 更新 $lib\README.md 的技能清单表 + $lib\CHANGELOG.md 追加一条
# 4) 提交推送
Set-Location $lib; git add -A; git -c user.name="LBY666-hub" -c user.email="15762959246@163.com" commit -m "feat: 新增 <技能名> 技能"
git -c credential.helper=manager push
```
仓库：`LBY666-hub/dsh-skills`（公开）。

---

## 9. 失败矩阵（先看这里，别乱试）

| 症状 / 原文 | 原因 | 处置 |
|---|---|---|
| `403 Resource not accessible by personal access token`（来自 `create_repository` 或 `push_files`） | DSH 的 GitHub 连接是**只读 bearer 令牌** | 改走 §4/§5（网页建仓 + 本机 git）；或让用户给令牌加权限：classic 勾 `public_repo`（公开仓库足够）／`repo`（含私有仓库），fine-grained 加 **Contents: Read and write**（+ 把该仓库加入 Repository access，想自动建仓还要 **Administration: Read and write**） |
| `push` 提示 `Authentication failed` / 401 | 未授权或凭据失效 | `git -c credential.helper=manager push`；仍失败则清掉旧凭据（Windows 凭据管理器里删 `git:https://github.com`）重新授权 |
| **GCM 不弹窗、命令一直挂着** | 全局 `credential.helper` 空值挡住了系统级 manager | 用 `-c credential.helper=manager`；长期修法：`git config --global --unset credential.helper` |
| 推送被拒且仓库是私有 | 令牌作用域只有 `public_repo` | 换 `repo` 作用域；或按用户偏好改回公开（默认即为公开，一般不会遇到） |
| 文件 >100 MB 被拒 | GitHub 硬限制 | 用 Git LFS；或打包成 zip / 走 Release 附件 |
| `fetch failed` / `Failed to connect to github.com:443` | 本机访问 GitHub 时通时断（实测会自愈） | **先重试 1~4 次（间隔 8 秒）**，多数情况第 1~2 次即成功；仍失败则查代理：系统代理 `127.0.0.1:7897`（Clash）是否在跑、git 是否需 `-c http.proxy=`；Node 的 fetch 需 `NODE_USE_ENV_PROXY=1` |
| 推送后发现有敏感文件 | — | `git rm --cached <file>` + 提交推送，并**提醒轮换密钥**；历史清理用 `git filter-repo` |

---

## 10. 本机环境事实（直接引用，不必重新探测）

| 项 | 值 |
|---|---|
| GitHub 账号 | `LBY666-hub`（狗蛋） |
| 已有仓库 | `marketing-brush-app`（公开·刷题 PWA）、`dsh-skills`（公开·技能库） |
| 可见性偏好 | **公开**（默认）；私有需用户明确要求 |
| 仓库命名习惯 | 小写 kebab-case |
| 本机 git 身份 | `LBY666-hub` / `15762959246@163.com`（全局已设） |
| 凭据 | **GCM 可用**（`C:\Program Files\Git\mingw64\bin\git-credential-manager.exe`），凭据已存 `git:https://github.com`；但全局 `credential.helper=''`（空值）→ 必须 `-c credential.helper=manager` |
| DSH 的 GitHub 连接 | `github-github` · manual/**bearer** → `https://api.githubcopilot.com/mcp/`；**只读**（能 `get_me`/搜索/读文件/列提交，不能建仓、不能写内容） |
| 常用产出位置 | 会话工作区 `D:\AAAAA\A workplace\dsh file`（含 `_stata输出\`）；知识库 `D:\刘宝阳\个人知识库\...`；技能库 `D:\刘宝阳\个人知识库\03-计算机与大模型\dsh学习\DSH技能库` |
| `gh` CLI | ❌ 未安装 |

---

## 11. 交付摘要格式（推完给用户）

```
✅ 已推送：<仓库链接>（公开，分支 main，提交 <短哈希>）
文件：N 个 / X MB ｜ 主要文件：…
读回验证：GitHub 侧文件清单与本机一致 ✅
后续维护：cd "<目录>" && git add -A && git commit -m "…" && git -c credential.helper=manager push
（若是网页产出）站点：https://LBY666-hub.github.io/<repo>/ （Pages 已开启 / 待你在 Settings→Pages 点一下）
```

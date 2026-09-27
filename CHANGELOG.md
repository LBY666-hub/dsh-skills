# 变更日志 · DSH 技能库

本库记录我所有 DSH 技能的版本与变更。技能改动请在此追加一条，并在 GitHub 仓库提交时写清对应技能名。

## 2026-09-27

**新增 `github-up` 技能**（把任意产出推送到 GitHub 的标准流程）

- 命令 **`/github-up`** —— ⚠️ **技能名不允许下划线**：加载器要求 `^[a-z0-9]+(?:-[a-z0-9]+)*$`，原设想的 `/github_up` 会被直接忽略，故定为连字符形式
- 交互式七步：确认三件事（推什么 / 推到哪 / 可见性）→ 敏感信息与大文件体检 → 本地 git 准备与提交 → 建远端仓库（走网页，因 DSH 的 GitHub 连接是只读令牌）→ 本机 git + Git Credential Manager 推送 → 用 GitHub 连接读回验证 → 按需开启 GitHub Pages
- 固化本机实测要点：① MCP 建仓/写内容一律 `403 Resource not accessible by personal access token`（只读 bearer 令牌）② 全局 `credential.helper` 为空值会挡住系统级 GCM，推送须带 `-c credential.helper=manager` ③ 技能产出走本库流程，普通产出走通用流程
- 同步状态：运行副本 `~\.dsh\skills\github-up` 与库内 `skills/github-up` 内容一致
- **修订：可见性默认「私有」→「公开」**（用户既定偏好）——同步更新 R2 铁律、Step 1 确认模板、Step 4 建仓指引、失败矩阵；公开仓库只需 `public_repo` 作用域，比私有更省事

**建库**（首次整理入库，共 4 个技能）

| 技能 | 变更 |
|---|---|
| `stata` | **新增**：交互式四步门控的 Stata 数据分析流程（数据勘察 → 分析方式清单含 do 写法与演示公式 → 按编号执行 → 可视化交付）。内含本机实测环境事实（StataNow 19.5 MP / 16 核 / maxvar 5000）与 9 条批处理坑（`r(608)` 日志冲突、`estimates table` 的 `star()` 与 `se` 互斥、`etable` 不吃 varlist、图必须 `graph export`、残留进程导致启动挂起等）。设为**仅手动触发**（`disable-model-invocation: true`） |
| `plugin-search` | 纳入库：插件检索流程（`find_dsh_plugin` 检索 → 事实卡 → 五段式选型报告） |
| `quit` | 纳入库：会话收尾的结构化总结格式 |
| `shuati-github-build` | 纳入库：Word 题库 → 离线刷题 PWA → GitHub Pages 部署 |

**基础设施**

- 新增 `README.md`：技能索引、三种安装方式、目录规范、新增技能步骤、加载器校验规则
- 新增 `install.ps1`：一键同步到 `~\.dsh\skills`，含加载器同款校验（名称正则 / 必填字段 / 拒绝旧字段名 / BOM 提示）与自动备份
- 入库前做了敏感信息扫描（`sk-`、`ghp_`、token、序列号、手机号等模式）：**无命中**（唯一命中是 stata 技能中"禁止打印序列号"这条规则本身）

---
name: plugin-search
description: 插件检索 —— 当用户挂载本 skill 并说出"我想要某类 DSH 插件"的需求时使用。执行时先调用 dsh-find-plugin 提供的 find_dsh_plugin 工具按需求检索插件，再逐个补齐事实（npm 元数据 / GitHub 活跃度 / 与本机内核的兼容判定 / 是否已装），最后输出：详细介绍 + 横向对比 + 适配结论 + 具体安装建议与命令。适用于"找插件、选插件、插件对比、装哪个好"这类请求。
disable-model-invocation: false
---

# 插件检索（plugin-search）

用户挂载本 skill 后会直接说出需求（如"任务完成想收到微信通知""找一个能看 git diff 的插件"）。
本 skill 的唯一目标：**把一句模糊需求，变成一份带事实依据、可直接执行的插件选型报告。**

---

## 0. 前置自检（每次执行都做，不可跳）

1. 内核版本：`dsh --version`（判定兼容性的基准）。
2. 已装清单：`dsh plugin --profile web ls` + 读 `~\.dsh\profiles\web\package.json` 的 `dependencies`。
3. **工具可用性**：检查当前工具面里有没有 `find_dsh_plugin`。
   - 有 → 正常走 §2。
   - **没有** → 说明 `dsh-find-plugin` 已装但 dsh 未重启（新插件未生效）。此时：
     - 明确告知用户"`find_dsh_plugin` 工具尚未生效，需要重启 dsh（启动器里重启服务）"；
     - **不要卡住**：立即按 §5 的降级通道继续交付结果。

---

## 1. 把需求翻译成检索词

- 抽 2~4 个关键词，**中英各备一组**（很多插件描述只有英文）。
- 需求含场景词时拆成 2~3 个查询，例如：
  - "任务完成提醒我（微信/Telegram/系统通知）" → `task notification`、`wechat notify`、`telegram bot`
  - "帮我管记忆" → `memory`、`long-term memory recall`、`context memory`
- **记录用户显式约束**，用于后面过滤：免费/无需 API key、纯本地、中文界面、与 Obsidian/Zotero 集成、是否需要 GUI 面板等。
- 若用户需求过于宽泛（如"有什么好玩的插件"），先反问一句收敛方向，或按类别给 3~5 组检索词并行。

## 2. 调用 `find_dsh_plugin` 检索

- **先看该工具的实际参数定义再调用**（通常是 `query` / `lang` / `limit` 之类），**不要臆造参数名**。
- 把 §1 的查询词逐个传入（1~3 次调用）。
- `lang` 若可选，按用户语言选（中文用户给 `zh`）。
- 报错/被限流时不要反复重试超过 1 次，直接转 §5 降级。

## 3. 候选收敛

- 目标 **3~6 个**候选：先按"功能是否真的对上需求"筛，再按"是否声明兼容当前内核 → 维护活跃度 → star 数"排序。
- 明显不相关（只是名字撞词、通用 npm 包、官方 `@deepseek-ai/*` 内置包）一律剔除，不要凑数。
- 官方 `@deepseek-ai/*` 包**不是社区插件**，只在"内置已有等价能力"时作为对照提一句。

## 4. 给每个候选补"事实卡"（禁止只看一句描述就下结论）

对每个候选（可并行）采集：

| 维度 | 取法 |
|---|---|
| 版本 / 描述 / 关键词 / 维护者 / 发布时间 | `https://registry.npmmirror.com/<包名>/latest`（JSON，含 `readme` 摘要字段） |
| peer 依赖 / engines | 同上（`peerDependencies`、`dsh.engines`）→ 判定是否接受当前内核 |
| 是否兼容当前内核 | 用 `peerDependencies` 的 `@deepseek-ai/dsh-*` 范围做 semver 判定（含预发布）；本地索引 `_证据归档\DSH插件目录-离线-20260926.json` 可直接查 |
| GitHub 活跃度 | `https://api.github.com/repos/<owner>/<repo>` → `stargazers_count` / `pushed_at` / `archived` / `open_issues_count` |
| 是否已装 | 与 §0 的已装清单比对 |
| 使用门槛与风险 | 是否需要 API key、是否有 native 依赖、是否 git 源（pnpm 会拦构建脚本，需 `allowBuilds`）、最近一次发布距今多久、是否 archived |

**取不到就写"未取到"，绝不编造 star 数、发布日期、维护者。**

## 5. 失败兜底（GitHub 不可用时的三级降级，必须告知用户已降级）

1. 若配了 `GITHUB_TOKEN`（DSH 凭据里）→ 配额 30/min；没有则匿名 10/min 且**同出口 IP 共享**，易 403/429。重试 1 次。
2. 降级 A：`dsh plugin --profile web search "dsh <关键词>"` —— 返回描述/版本/发布日期/维护者/关键词/链接（走 npmmirror，不经 GitHub）。
3. 降级 B：本地兼容性索引 `D:\AAAAA\A workplace\dsh file\_证据归档\DSH插件目录-离线-20260926.json`（599 条，含版本与 peer 兼容判定）；
   `D:\AAAAA\A workplace\dsh file\查插件.ps1` 可直接用（`.\查插件.ps1 memory`）。
4. 已知坑（排查时先想到）：本机 **Node 的 fetch 不走系统代理**，用代理/加速器时需 `NODE_USE_ENV_PROXY=1` 启动 dsh；内置插件管理器连 GitHub 曾 `timed out after 5000ms`。
5. 降级后**必须写明**"本次结果是降级通道产出、数据截至某时间"，别把"没搜到"说成"不存在"。

## 6. 输出格式（固定五段，中文）

1. **需求理解** —— 我用什么标准在找（含用户约束），一句话。
2. **候选对比表** —— 列：`插件 | 一句话功能 | 版本/发布 | star·最近更新 | 兼容当前内核 | 门槛/风险 | 已装`。表格里只放事实，判断留给第 4 段。
3. **逐个详细介绍** —— 每个 2~4 句：它解决什么问题、怎么做到、与同类**差在哪**、代价是什么（要不要 key、要不要重启、有没有 GUI）。
4. **推荐结论** —— `首选 / 备选 / 不建议` 三档 + 一句话理由；明确说出"为什么不选另外几个"。
5. **安装建议与方式** —— 首选与备选各给一条可复制命令：
   ```powershell
   # npm 源（推荐，钉版本便于回滚）
   dsh plugin --profile web add -w "<包名>@<版本>"
   # GitHub 源码（仅当 npm 没有时）
   dsh plugin --profile web add -w "github:<owner>/<repo>"
   ```
   并写清**装后步骤**：重启 dsh → 验证（工具/面板是否出现）→ 回滚命令（`remove -w "<包名>"`）。

## 7. 安装纪律

- **默认只出建议，不擅自安装**；用户明确说"装/帮我装上"才动手。
- 动手时按既定纪律：**备份 profile 配置 → 安装 → 读回**（`package.json` 依赖与 bundles、`dsh --profile web --dump-config` 无致命错误、插件目录存在）。
- 提示"第三方代码，建议 review 源码并钉版本"。
- 安装/卸载后都要提醒：**CLI 装的需重启 dsh 才彻底生效**（内置面板的操作是 live-remove）。
- 不打印 token/密钥；凭据类配置一律建议走 GUI 凭据页。

## 8. 本机环境事实（引用时直接用，不必重新探测）

- 内核：`0.1.7-rc.1`；安装位置 `D:\AAAAA\dsh-017`；profile `C:\Users\16357\.dsh\profiles\web`。
- 插件管理器：`dsh plugin --profile web <add|remove|ls|search>`（转发给 pnpm 12.6.0，registry = npmmirror）。
- `dsh-find-plugin` 0.4.0 已安装（挂载行 id `find-dsh-plugin`，工具名 `find_dsh_plugin`）。
- 已装第三方插件（截至 2026-09-26）：skill-explorer、task-board、cyber-particle、deep-read-summarize、dsh-context、drag-and-drop、dsh-find-plugin、mcp-connector、office-tools。

## 9. 禁止事项

- 不做"可能是/大概是兼容"的模糊判定 —— 判不了就写"无法判定（缺 peer 声明）"。
- 不凭记忆报版本号、star 数、发布日期；一律以本次取到的数据为准。
- 不复述插件自己的营销话术当结论；要落到"对你这个需求能不能用、代价是什么"。
- 不建议把官方内置包当插件安装。
- 用户没要求时，不修改 profile 配置、不动已装插件。

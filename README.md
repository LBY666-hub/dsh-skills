# DSH 技能库 · dsh-skills

我的 [DeepSeek Harness (DSH)](https://github.com/deepseek-ai/deepseek-harness) 技能集中管理库。

技能 = 一份 `SKILL.md`（YAML frontmatter + Markdown 指令），放进 `~/.dsh/skills/<name>/`，在会话里输入 `/<name>` 调用。

> **本库是唯一维护入口**：`~/.dsh/skills/` 只是运行副本，任何改动请回到本库修改后再用 `install.ps1` 同步。

---

## 技能清单

| 技能 | 调用 | 一句话用途 | 自动挂载 | 体量 |
|---|---|---|---|---|
| **stata** | `/stata` | Stata 数据分析全流程（**交互式四步门控**）：上传任意格式数据 + 一句话需求 → 我出「分析方式清单」（每项含 do 文件写法与演示公式）→ 你按编号选择 → 执行数据处理与分析 → 可视化与交付 | **禁用**（仅手动，避免误执行 Stata） | 257 行 / 14.9 KB |
| **plugin-search** | `/plugin-search` | 插件检索与选型：`find_dsh_plugin` 检索 → 补事实卡（npm 元数据 / GitHub 活跃度 / 内核兼容判定 / 是否已装）→ 五段式报告 + 安装命令 | 允许 | 108 行 / 7.6 KB |
| **shuati-github-build** | `/shuati-github-build` | Word 题库 → 离线刷题 PWA → 推送 GitHub 并开启 Pages，装到手机离线刷题 | 允许 | 74 行 / 6.9 KB |
| **quit** | `/quit` | 会话收尾：输出「做了什么 / 产物·位置 / 当前状态 / 可继续事项」的结构化总结 | 允许 | 27 行 / 1.8 KB |

---

## 目录结构

```
dsh-skills/
├─ README.md          ← 本文件（技能索引 + 使用方法）
├─ CHANGELOG.md       ← 变更日志（每次改动请追加一条）
├─ install.ps1        ← 一键同步到 ~\.dsh\skills（含加载器同款校验 + 自动备份）
└─ skills/
   ├─ stata/SKILL.md
   ├─ plugin-search/SKILL.md
   ├─ quit/SKILL.md
   └─ shuati-github-build/SKILL.md
```

---

## 安装 / 更新

### 一键（推荐）

```powershell
pwsh -File install.ps1                 # 同步全部技能
pwsh -File install.ps1 -Skill stata    # 只装/更新某一个
pwsh -File install.ps1 -DryRun         # 预演：只显示会做什么，不写盘
```

脚本安装前会做**加载器同款校验**（技能名正则、frontmatter 必填字段、拒绝旧字段名、BOM 提示），覆盖前自动备份为 `SKILL.md.bak-<yyyyMMdd-HHmmss>`；只写 `~\.dsh\skills`，其它位置一概不动。

### 手动

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.dsh\skills\stata" | Out-Null
Copy-Item .\skills\stata\SKILL.md "$env:USERPROFILE\.dsh\skills\stata\SKILL.md" -Force
```

### 换一台机器

```powershell
git clone https://github.com/LBY666-hub/dsh-skills.git
cd dsh-skills
pwsh -File install.ps1
```

（私有仓库需先配置凭据；也可以直接用 DSH 的 GitHub 连接把技能推送到这台机器。）

---

## 新增一个技能

1. 建 `skills/<技能名>/SKILL.md` —— 名字只能**小写字母、数字、连字符**；frontmatter 必须有 `name` 与 `description`
2. 可选：`disable-model-invocation: true|false`（`true` = 只能手动 `/名字` 触发，不允许模型自动挂载）
3. `pwsh -File install.ps1 -Skill <技能名>` 安装，并在会话里实测一次
4. 在 `CHANGELOG.md` 追加一条记录，然后提交推送

---

## 校验规则（DSH 加载器要求，踩过的坑）

| 规则 | 说明 |
|---|---|
| 技能名 | `^[a-z0-9]+(?:-[a-z0-9]+)*$` —— **中文名会被忽略** |
| 必填字段 | `name` + `description`，缺失 → 该技能文件被忽略 |
| 旧字段名 | `disableModelInvocation` / `modelInvocable` → **拒绝加载**，只能用 `disable-model-invocation` |
| 编码 | 建议 UTF-8 **无 BOM** |
| 生效方式 | 放入 `~\.dsh\skills` 后由 DSH 扫描纳入，输入 `/<技能名>` 调用 |

---

## 与 GitHub 的对应关系

| 位置 | 角色 |
|---|---|
| 本仓库 `LBY666-hub/dsh-skills` | **版本管理与备份（源）** |
| `D:\刘宝阳\个人知识库\03-计算机与大模型\dsh学习\DSH技能库\` | 本地工作副本（与仓库同构） |
| `C:\Users\16357\.dsh\skills\` | DSH 运行副本（由 `install.ps1` 同步） |

---

## 变更日志

见 [CHANGELOG.md](CHANGELOG.md)。

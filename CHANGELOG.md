# 变更日志 · DSH 技能库

本库记录我所有 DSH 技能的版本与变更。技能改动请在此追加一条，并在 GitHub 仓库提交时写清对应技能名。

## 2026-09-27

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

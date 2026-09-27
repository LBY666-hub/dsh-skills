---
name: stata
description: Stata 数据分析全流程（交互式四步门控）—— 用户以 /stata 调用、上传任意格式数据并简述需求后，本 skill 依次推进：①只读数据勘察 ②输出“分析方式清单”（每项含 do 文件写法与演示公式）③用户按编号选择后执行数据处理与统计分析 ④数据可视化与交付。**用户未给出需求与编号选择前，禁止任何清洗、建模、出表出图操作。** 适用于用本机 StataNow 19.5 MP 处理问卷、社科、计量、量表与结构方程数据。
disable-model-invocation: true
---

# Stata 数据分析（交互式 · 四步门控）

一句话流程：**用户 `/stata` + 数据 + 需求 → 我出「分析方式清单」（含 do 写法与演示公式）→ 用户按编号选 → 我执行分析 → 出图与交付。**

本 skill 只能由用户显式 `/stata` 触发（`disable-model-invocation: true`），**不自动运行**。

---

## 0. 铁律（不可跳过）

| 编号 | 铁律 |
|---|---|
| **R1 交互门控** | 只有在用户**已经说明需求**后才出清单；只有在用户**给出编号选择**后才执行 Stata。缺哪一步就只问那一步，**不要替用户预设**。 |
| **R2 只读勘察** | Step 1 允许的只有"元数据级"读取：文件名、格式、大小、变量名/类型/标签、观测数、缺失概况。**禁止**清洗、生成变量、建模、出表出图。 |
| **R3 原始数据只读** | 绝不修改用户原始文件。所有写入只发生在项目目录内；转换（如 `.sav`→`.dta`）产出的是副本。 |
| **R4 数值可溯源** | 汇报的每个数字都必须来自**本次运行的 log**，禁止凭记忆/推测报数。数学上不确定就写"未取到/需补跑"。 |
| **R5 先报后跑** | 每次真正执行前，用一句话说明"将要运行什么 do（含关键命令）"；跑完贴关键日志片段与产物路径。 |
| **R6 失败即披露** | 报错就贴 `r(错误码)` 原文 + 我的修法，再重跑；连续 3 次同一错误就停下来问用户，不要静默变通。 |
| **R7 交付前读回** | 图必须我自己读回看过（`read_image`）；表必须解析核对过内容；然后再交付。 |

---

## 1. Step 1｜数据勘察（只读）

### 1.1 找到数据
1. 用户若给了路径 → 直接用；
2. 若说"我刚上传的" → 取最新附件：
   `C:\Users\16357\.dsh\attachments\v1\files\<2位>\<hash>\<原文件名>`（按 `LastWriteTime` 取最新；同一消息可能有多份，按名字/大小与用户描述匹配）；
3. 找不到就**问用户**，不要猜。

### 1.2 认格式与读法

| 扩展名 | 读法 |
|---|---|
| `.dta` | 直接 `use`（Stata 19 可读 13–19 版；更老的需 `useold`/转换） |
| `.csv` / `.txt` / `.tsv` | `import delimited`（注意编码与分隔符：`encoding(UTF-8)`、`delimiter()`） |
| `.xlsx` / `.xls` | `import excel`（多工作表用 `sheet()`；表头跨行用 `cellrange()`） |
| **`.sav` / `.por`（SPSS）** | Stata 读不了 → 用本机 Python 转换：`python -c "import pyreadstat; df,meta=pyreadstat.read_sav(r'源', encoding='GBK'); pyreadstat.write_dta(df, r'目标.dta')"`（`pyreadstat 1.3.6` 已装；中文变量标签注意 `encoding`/`user_missing`） |
| 其它（`.rds`/`.mat`） | 先问用户，不自行臆断 |

### 1.3 勘察清单（只读，写进给用户的首条回复）
- 样本量、变量数、标识变量、时间变量、分组变量
- 关键变量的类型/取值/标签、缺失率（`.dta/.csv` 可 `import` 后 `describe`+`misstable`；这一步算 R2 允许范围）
- 可能的痛点：字符串数值、缺失编码（-99/999）、重复 ID、面板不平衡、单位/量纲

### 1.4 首条回复模板（若用户只给了数据没给需求）
```
已收到数据：<文件名>（<格式>, <大小>, <N 行 × M 列>）
初步看到：<3–5 条结构事实>

**你想解决什么问题？** 例如：
① 描述现状（分布/差异/趋势） ② 检验组间差异 ③ 建回归模型找影响因素
④ 量表信效度与结构方程 ⑤ 中介/调节机制 ⑥ 面板/因果推断 ⑦ 只要图
（说一句就够，我据此出「分析方式清单」）
```
**若用户已给需求** → 直接进 Step 2，不要再问一轮。

---

## 2. Step 2｜分析方式清单（本 skill 的核心产物）

### 2.1 每项**必须**包含这 7 个字段
```
【编号】X#（如 C2）
【名称】中文名
【回答什么】一句话研究问题
【前提】需要的变量/样本量/数据结构，缺什么先补什么
【演示公式】数学式 → Stata 命令（一一对应）
【do 片段】可直接粘贴运行的代码块（含必要注释；含 set maxvar / 标准误 / 权重 / 聚类）
【产出】表（xlsx）／图（png）／数据文件
【成本】预计耗时、是否需要 ssc install（联网风险）
```

### 2.2 分组骨架（按需裁剪，不要全端上去）

**0. 数据体检（默认推荐第 0 步，几乎总该做）**
- 公式：样本/缺失/分布 → `describe`、`codebook`、`misstable summarize`、`summarize, detail`、`tab1`、`assert` 一致性
- 产出：数据质量表 + 变量字典

**A. 数据准备**
| 编号 | 名称 | 演示公式 → Stata |
|---|---|---|
| A1 | 清洗与缺失值处理 | 缺失率/模式 → `misstable patterns`；删除/插补 `mi set mlong`+`mi impute` |
| A2 | 变量生成与重编码 | 标准化 z=(x−μ)/σ → `egen z=std(x)`；分组 `recode`/`xtile`；交互 `c.x##c.z` |
| A3 | 合并与长宽转换 | 1:1/1:m 匹配 → `merge 1:m id using`；宽长 `reshape long` |
| A4 | 异常值与缩尾 | 缩尾 w=(1%,99%) → `winsor2`(SSC) 或 `egen p1=pctile(x), p(1)` |
| A5 | 变量标签与值标签（中文） | `label variable` / `label define` / `label values` |

**B. 描述与探索**
| 编号 | 名称 | 演示公式 → Stata |
|---|---|---|
| B1 | 描述统计表 | mean±sd, min/max, N → `tabstat` / `table` / `etable` |
| B2 | 组间差异检验 | t 检验 → `ttest y, by(g)`；卡方 → `tab g y, chi2`；非参 → `ranksum`/`kwallis` |
| B3 | 相关矩阵 | Pearson/Spearman → `pwcorr`/`spearman`，显著性 `pwcorr, sig star(.05)` |
| B4 | 列联表与比例 | `tabulate` + `proportion` |

**C. 回归族（计量/社科主力）**
| 编号 | 名称 | 演示公式 → Stata |
|---|---|---|
| C1 | 基准 OLS（稳健标准误） | Y=β₀+β₁X+β₂Z+ε → `regress y x z, robust` |
| C2 | 嵌套模型逐步加入 | 逐步加控制变量 → `regress ...` × 多次 + `estimates store` + `etable, estimates(m1 m2 m3)` |
| C3 | 二值/有序/多项/计数 | logit/oprobit/mlogit/poisson → `logit`、`oprobit`、`mlogit`、`poisson ..., robust`（+`margins, dydx(*)`） |
| C4 | 面板模型 | FE/RE + Hausman → `xtset id t`、`xtreg y x, fe`、`xtreg y x, re`、`hausman fe re`；聚类 `, vce(cluster id)` |
| C5 | 工具变量 | 2SLS → `ivregress 2sls`/`ivreg2`(SSC) + 弱工具 `estat firststage` |
| C6 | 中介效应 | 间接效应 a·b → `medeff`/`sgmediation`(SSC) 或 SEM 路径 `sem (M<-X)(Y<-M X)`，`estat teffects` |
| C7 | 调节效应 | Y=β₁X+β₂W+β₃X·W → `regress y c.x##c.w` + `margins`/`marginsplot` |
| C8 | 稳健性与异质性 | 替换测度/子样本/缩尾 → 循环 `foreach` 批量重估 |

**D. 量表与结构方程**
| 编号 | 名称 | 演示公式 → Stata |
|---|---|---|
| D1 | 信度 | Cronbach α → `alpha item1-item8, std item` |
| D2 | 探索性因子分析 | `factor item*, pcf` + `rotate, varimax` + `estat kmo` |
| D3 | 验证性因子/结构方程 | 测量模型 λ、结构路径 γ/β → `sem (F1 -> x1 x2)(F2 -> y1 y2)(F2 <- F1)`；拟合 `estat gof, stats(all)`、`estat mindices` |
| D4 | 测量不变性/多组比较 | `sem ..., group(g)` + `estat gof` 逐步约束 |

**E. 因果推断（如适用）**：DID（`didregress`/`csdid`）、PSM（`teffects psmatch`）、RDD（`rdrobust`(SSC)）、事件研究（`eventstudyinteract`）

**F. 可视化**（Step 4 的图清单也走这套编号）
| 编号 | 名称 | 演示命令 |
|---|---|---|
| F1 | 分布（直方/密度/箱线） | `histogram y, bin(20)`、`graph box y, over(g)` |
| F2 | 组间比较（均值±95%CI） | `graph bar (mean) y, over(g)` 或 `ciplot`(SSC) |
| F3 | 相关热图 | `corrplot`(SSC) / `heatplot` |
| F4 | 回归系数图 | `coefplot`(SSC) 或 `estimates table` 转 xlsx 后自绘 |
| F5 | 边际效应图 | `margins, at(...)` + `marginsplot` |
| F6 | 趋势/面板图 | `twoway line y t`、`xtline` |
| F7 | **SEM 路径图** | ⚠️ 需 GUI 的 SEM Builder；批处理只能出系数与拟合指标（要图另想办法：导系数后另绘） |

**G. 自定义**：用户用自然语言描述的分析（我翻译成 do 并说明公式与前提）

### 2.3 清单收尾（固定句式）
```
**请回复编号**（可多选，逗号分隔），例如：`0, A3, C2, F4`
可选补充约束：样本筛选（if 条件）、控制变量清单、聚类层级、加权变量、置信水平、图表中英文、输出格式（xlsx/docx/png）
```
并在末尾给 1–2 组**推荐组合**（如 `0 → A3 → C2 → F5`：先体检、再清洗、再嵌套回归、最后边际效应图）。

---

## 3. Step 3｜执行（用户给出编号之后）

### 3.1 项目目录（固定结构）
```
D:\AAAAA\stata\work\<项目名>-<YYYYMMDD>\
  ├─ data\   原始副本 + 转换后的 .dta（只读来源）
  ├─ do\     01-import.do / 02-clean.do / 03-analysis.do / 04-figures.do
  └─ out\    表(xlsx/docx) / 图(png) / 导出数据
（批处理日志落在**运行目录**：把 cwd 设为项目根，则生成 01-import.log 等在根目录）
```

### 3.2 do 文件规范（每个文件都要有头部）
```stata
*==============================================================
* 项目：<名称>    文件：02-clean.do    日期：<YYYY-MM-DD>
* 目的：<一句话>  输入：data/xxx.dta   输出：out/xxx.xlsx
*==============================================================
clear all
set more off
version 19.5
set maxvar 120000          // 默认仅 5000，宽表必须放开
cd "D:/AAAAA/stata/work/<项目>/"
use "data/xxx.dta", clear
...分析...
```
- 中文标签可用（Stata 19 Unicode）；do 文件用 **UTF-8 无 BOM** 写盘
- 路径用正斜杠 `D:/...` 且全程加引号
- 导出前 `capture drop _est_*`（`estimates store` 会往数据集塞 `_est_*` 变量）

### 3.3 批处理调用（本机实测可用）
```powershell
Start-Process "D:\AAAAA\stata\StataMP-64.exe" `
  -ArgumentList '/e','do',"D:/AAAAA/stata/work/<项目>/do/03-analysis.do" `
  -WorkingDirectory "D:\AAAAA\stata\work\<项目>" -WindowStyle Hidden -PassThru |
  Wait-Process -Timeout 300
```
- 跑前先清理残留进程（否则新实例会卡住）：`Get-Process | Where-Object ProcessName -match '^Stata' | Stop-Process -Force`
- 超时未退出 → `Stop-Process` 并如实报告（很可能弹了对话框）
- 长任务用后台 job，别阻塞对话

### 3.4 表格与结果导出
- 现代内建：`etable, export("out/表1.xlsx", replace) title("...")`（多模型：`etable, estimates(m1 m2 m3) export(...)`）
- 其它：`putexcel`（逐格）、`estimates table`（纯文本进 log）、SSC 的 `esttab`/`outreg2`（需 `ssc install`，联网先试再告知）
- 描述统计：`etable, statistic(N mean sd min max) export(...)`

### 3.5 循环与收敛
读 log → 见错即改（贴 `r(码)`）→ 重跑 → 直到 `ALL DONE`；每个 do 只做一件事，便于定位。

---

## 4. Step 4｜数据可视化

1. **先给图清单**（编号/类型/横纵轴/分组/核心信息），用户勾选或默认全出；
2. 统一规格：中文标签、`graph export "out/图N.png", replace width(2400)`；期刊用 `as(pdf)` 或 `tif` 且 `width(3000)`；
3. 多面板用 `graph combine`；
4. **导出后我必须 `read_image` 读回确认**（轴标签是否被截断、图例是否遮挡、中文是否乱码）：乱码就改 `set font`/字体或改英文标签后重出；
5. 图形命令一律 `name(gN, replace)` + `graph close`，避免批处理残留。

---

## 5. 交付与归档

- 产物清单表：文件 | 内容 | 大小
- 把 `out\` 与 log 拷一份到会话工作区 `D:\AAAAA\A workplace\dsh file\_stata输出\<项目>\`，用 `present` 给文件卡片（≤4 个）
- 附"结论摘要"：每个表/图 1–2 句**只陈述本次结果**（含系数、标准误、显著性、N、R²/拟合指标）
- 结尾写明：do 文件位置（可复现）、下次可继续的编号

---

## 6. 本机环境事实（直接引用，不必重新探测）

| 项 | 值 |
|---|---|
| Stata | `D:\AAAAA\stata\StataMP-64.exe`（备选 `StataSE-64.exe`） |
| 版本/许可 | **StataNow 19.5 MP**，`Single-user 16-core perpetual`，`MP=1`、`processors=16` |
| `maxvar` 默认 | **5,000**（MP 上限 120,000，宽表先 `set maxvar 120000`） |
| 工作目录（Stata 默认） | `D:\AAAAA\stata\work`（注册表 `StataNow19Start\StartUpDir`） |
| 批处理模式 | `/e do <绝对路径.do>` → 同名 `.log` |
| Python（转换用） | `D:\AAAAA\python\python.exe`，`pyreadstat 1.3.6` |
| 会话工作区 | `D:\AAAAA\A workplace\dsh file`（Excel/Word 类工具**只能**读该目录内文件；外部产物先拷贝进来） |

## 7. 已知坑（本机实测，直接规避）

1. **`log using` 冲突**：批处理已占用 `<dofile>.log`，do 内再开同名 log → `r(608)`。要么不开 log，要么换名（如 `analysis.log`）。
2. **`estimates table`**：`star()` 与 `se/t/p` **互斥** → `r(198)`；二者只取其一。
3. **`etable` 不吃 varlist**：`etable m1 m2` 报 `varlist not allowed` → 写成 `etable, estimates(m1 m2)`。
4. **图形无窗口**：批处理必须 `graph export` 落盘；否则图丢掉。
5. **残留进程**：上一次卡死的 Stata 进程会让下一次启动挂起 → 跑前清理。
6. **`sysuse auto`** 若失败（sysdir 异常）→ 直接 `use "D:/AAAAA/stata/auto.dta"`。
7. **`estimates store`** 会生成 `_est_*` 变量 → 导出数据前 drop。
8. **中文路径/文件名**：Stata 19 支持，但 do 文件务必 UTF-8 写盘、路径加引号。
9. **SSC 包**（`esttab`/`outreg2`/`coefplot`/`winsor2`/`ivreg2`/`medeff`）需 `ssc install`；本机外网时好时坏，先试一次，失败就改用内建等价命令并告知。

## 8. 禁止事项

- 未获需求与编号选择前，**不执行任何 Stata 操作**（R1/R2）；
- 不修改原始数据文件、不在项目目录之外写文件；
- 不把"没搜到/没跑出"说成"不存在/不显著"；
- 不打印许可证序列号、注册码、API key；
- 不擅自 `set maxvar`/`ssc install`/改 Stata 全局设置而不告知。

## 9. 调用方式（给用户看）

```
/stata
【数据】把文件直接拖进来（任意格式），或写路径
【需求】一句话，例如：比较实验组与对照组的绩效差异，并检验组织支持的中介作用
```
- 只给数据不给需求 → 我只做勘察并问你要什么（不跑分析）
- 给了需求 → 我直接出「分析方式清单」，你用编号点菜
- 中途可加约束：`样本只保留 2020 年后`、`控制年龄性别`、`按省份聚类`、`图要英文`

#Requires -Version 7.0
<#
.SYNOPSIS
  把本技能库里的技能安装 / 更新到 DSH 的个人技能目录（~\.dsh\skills\<name>\SKILL.md）。

.DESCRIPTION
  · 安装前会按 DSH 加载器的规则做校验：技能名正则、frontmatter 必填字段、拒绝旧字段名、BOM 提示；
  · 覆盖前自动备份旧文件为 SKILL.md.bak-yyyyMMdd-HHmmss；
  · 只写 ~\.dsh\skills，不触碰其它任何位置。

.EXAMPLE
  pwsh -File install.ps1                 # 同步全部技能
.EXAMPLE
  pwsh -File install.ps1 -Skill stata    # 只装/更新某一个
.EXAMPLE
  pwsh -File install.ps1 -DryRun         # 只显示将要做什么，不写盘
#>
[CmdletBinding()]
param(
  [string[]]$Skill,
  [switch]$DryRun,
  [switch]$NoBackup
)

$ErrorActionPreference = 'Stop'
$NamePattern = '^[a-z0-9]+(?:-[a-z0-9]+)*$'      # DSH 加载器硬性要求
$LegacyKeys  = '^(disableModelInvocation|modelInvocable):'

$libRoot = Split-Path -Parent $PSCommandPath
$srcRoot = Join-Path $libRoot 'skills'
$dstRoot = Join-Path $HOME '.dsh\skills'

if (-not (Test-Path $srcRoot)) { throw "找不到 skills 目录：$srcRoot" }
if (-not (Test-Path $dstRoot)) { New-Item -ItemType Directory -Force $dstRoot | Out-Null }

$names = if ($Skill) { $Skill } else { (Get-ChildItem $srcRoot -Directory | Sort-Object Name).Name }
Write-Host "技能库：$libRoot"
Write-Host "目标  ：$dstRoot"
Write-Host ("-" * 72)

$ok = 0; $skip = 0
foreach ($n in $names) {
  $src = Join-Path $srcRoot "$n\SKILL.md"
  if (-not (Test-Path $src))                      { Write-Warning "跳过 $n ：找不到 $src"; $skip++; continue }
  if ($n -notmatch $NamePattern)                  { Write-Warning "跳过 $n ：技能名不合规（须为小写字母/数字/-）"; $skip++; continue }

  $text = Get-Content $src -Raw
  $m = [regex]::Match($text, '(?s)^---\s*\r?\n(.*?)\r?\n---')
  if (-not $m.Success)                            { Write-Warning "跳过 $n ：缺少 YAML frontmatter"; $skip++; continue }
  $fm = $m.Groups[1].Value
  if ($fm -notmatch '(?m)^name:\s*\S')            { Write-Warning "跳过 $n ：frontmatter 缺 name"; $skip++; continue }
  if ($fm -notmatch '(?m)^description:\s*\S')     { Write-Warning "跳过 $n ：frontmatter 缺 description"; $skip++; continue }
  if ($fm -match "(?m)$LegacyKeys")               { Write-Warning "跳过 $n ：使用了加载器拒绝的旧字段名，请改用 disable-model-invocation"; $skip++; continue }

  $bytes = [IO.File]::ReadAllBytes($src)
  if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    Write-Warning "$n ：SKILL.md 带 UTF-8 BOM（建议去掉，避免个别解析器读歪 frontmatter）"
  }

  $dstDir = Join-Path $dstRoot $n
  $dst    = Join-Path $dstDir 'SKILL.md'
  $action = if (Test-Path $dst) { '更新' } else { '新建' }
  Write-Host ("[{0}] {1}" -f $action, $n)

  if ($DryRun) { $ok++; continue }

  New-Item -ItemType Directory -Force $dstDir | Out-Null
  if ((Test-Path $dst) -and -not $NoBackup) {
    $bak = "$dst.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item $dst $bak -Force
    Write-Host "        旧版已备份 → $(Split-Path $bak -Leaf)"
  }
  Copy-Item $src $dst -Force
  $ok++
}

Write-Host ("-" * 72)
Write-Host "完成：成功 $ok 个，跳过 $skip 个。"
if ($DryRun) { Write-Host "（DryRun：未写入任何文件）" }
Write-Host "提示：技能放入 ~\.dsh\skills 后由 DSH 扫描纳入，输入 /<技能名> 调用。"

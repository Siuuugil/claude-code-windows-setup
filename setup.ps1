<#
  새 PC 개발 환경 세팅. 여러 번 실행해도 안전하다 (이미 된 단계는 건너뜀).

  사용 (setup.cmd 가 실행 정책을 바꾸지 않고 이 스크립트를 실행한다):
    setup.cmd               # 전체 세팅 (더블클릭)
    setup.cmd -UpdateAll    # 업데이트 질문에 전부 '예'
    setup.cmd -SaveMemory   # 이 PC의 Claude 메모리를 ..\.personal\memory 로 백업 (본인 PC끼리 옮길 때)
#>
param([switch]$SaveMemory, [switch]$UpdateAll)

$hub = Split-Path $PSScriptRoot -Parent
# 개인 메모리 백업은 공유 키트(setup\) 밖에 둔다: setup 폴더만 남에게 줘도 개인정보가 따라가지 않음
$memoryBackup = Join-Path $hub ".personal\memory"
# Claude Code 메모리 폴더 이름 = 프로젝트 경로의 영문·숫자 외 문자를 - 로 바꾼 것 ("OneDrive - 개인" 같은 경로 대비)
$memoryDir = Join-Path $HOME (".claude\projects\" + ($hub -replace '[^A-Za-z0-9]', '-') + "\memory")

function Step($msg) { Write-Host "`n=== $msg" -ForegroundColor Cyan }
function RefreshPath { $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User") }

if ($SaveMemory) {
    if (-not (Test-Path "$memoryDir\*.md")) { Write-Warning "백업할 Claude 메모리 없음: $memoryDir"; return }
    New-Item -ItemType Directory -Force $memoryBackup | Out-Null
    Copy-Item "$memoryDir\*.md" $memoryBackup -Force -ErrorAction Stop
    Write-Host "메모리 백업 완료: $memoryBackup"
    return
}

Step "1. 프로그램 설치 (winget)"
RefreshPath
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Warning "winget 없음. Microsoft Store 에서 '앱 설치 관리자(App Installer)' 를 설치/업데이트한 뒤 새 터미널에서 다시 실행"
    return
}
# 명령이 이미 실행 가능하면 설치 방법(직접 설치, Store, nvm 등)과 상관없이 건드리지 않는다 (중복 설치 방지)
$packages = [ordered]@{
    "Git.Git"                    = "git"
    "OpenJS.NodeJS.LTS"          = "node"
    "Python.Python.3.12"         = "python"
    "astral-sh.uv"               = "uv"
    "GitHub.cli"                 = "gh"
    "rtk-ai.rtk"                 = "rtk"
    "Microsoft.VisualStudioCode" = "code"
}
function HasCommand($name) {
    $cmd = Get-Command $name -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $cmd) { return $false }
    if ($name -ne "python") { return $true }
    # WindowsApps 의 python 은 Store 로 보내는 가짜 바로가기일 수도, 진짜 Store 판 Python 일 수도 있어서 실행해 보고 판단
    if ((Get-Command py -ErrorAction SilentlyContinue)) { return $true }
    return ((& python --version 2>&1 | Out-String) -match 'Python \d')
}
# 이 환경이 동작하는 데 필요한 최소 버전 (Ponytail 훅: Node, watch 플러그인: Python 3.10+)
$minVersion = @{ node = [version]"18.0"; python = [version]"3.10" }
# 최소 버전 미달인데 winget 으로 관리되지 않는 경우 (nvm, Store, 다른 버전 등) 안내
$manualHelp = @{
    node   = "nvm 을 쓰면: nvm install lts; nvm use lts  /  아니면 기존 Node 제거 후 이 스크립트 다시 실행"
    python = "winget install Python.Python.3.12 로 나란히 설치 후 'py -3.12' 사용 (기존 버전은 그대로 둠)"
}
function GetVersion($name) {
    $exe = if ($name -eq "python" -and (Get-Command py -ErrorAction SilentlyContinue)) { "py" } else { $name }
    $out = & $exe --version 2>&1 | Out-String
    if ($out -match '(\d+\.\d+(\.\d+)?)') { return [version]$Matches[1] }
}
function Ask($question) {
    if ($UpdateAll) { return $true }
    # 비대화형 실행(Claude 등)에서는 묻지 않고 '아니요'
    try { $a = Read-Host "  $question [y/N]" } catch { return $false }
    return $a -match '^(y|yes|ㅇ|예|네)$'
}
function WingetManaged($id) { winget list --id $id -e --accept-source-agreements *> $null; return $LASTEXITCODE -eq 0 }

$upgradable = @()
foreach ($id in $packages.Keys) {
    $name = $packages[$id]
    if (HasCommand $name) {
        $ver = GetVersion $name
        Write-Host "  [있음] $name $ver -> $((Get-Command $name).Source)"
        if ($minVersion[$name] -and $ver -and $ver -lt $minVersion[$name]) {
            Write-Warning "[필수 업데이트] $name $ver 은(는) 너무 오래됨. $($minVersion[$name]) 이상 필요"
            if ((WingetManaged $id) -and (Ask "$name 을(를) 지금 업데이트할까요?")) {
                winget upgrade --id $id -e --accept-package-agreements --accept-source-agreements --silent
            } else { Write-Host "  직접 업데이트: $($manualHelp[$name])" }
            continue
        }
        # --upgrade-available 은 결과가 없어도 exit 0 이라 출력에 id 가 있는지로 판단
        $out = winget list --id $id -e --upgrade-available --accept-source-agreements 2>&1 | Out-String
        if ($out -match [regex]::Escape($id)) { $upgradable += $id }
        continue
    }
    if (WingetManaged $id) { Write-Host "  [있음] $id (설치됨, 새 터미널에서 명령 인식)"; continue }
    Write-Host "  [설치] $id (관리자 확인 창이 뜨면 '예')"
    winget install --id $id -e --source winget --accept-package-agreements --accept-source-agreements --silent
    if ($LASTEXITCODE -ne 0) { Write-Warning "$id 설치 실패 (exit $LASTEXITCODE). 관리자 확인 창을 거절했으면 다시 실행" }
}

if ($upgradable) {
    Write-Host "`n  [선택 업데이트] 새 버전이 있음 (지금 버전도 동작에는 문제 없음): $($upgradable -join ', ')"
    if (Ask "모두 업데이트할까요?") {
        foreach ($id in $upgradable) { winget upgrade --id $id -e --accept-package-agreements --accept-source-agreements --silent }
    } else { Write-Host "  건너뜀. 나중에: winget upgrade --id <이름> -e" }
}
RefreshPath

Step "2. git 사용자 (커밋에 남는 이름·이메일)"
if (Get-Command git -ErrorAction SilentlyContinue) {
    # 이미 설정돼 있으면 그대로 둔다. 비어 있을 때만 묻는다
    foreach ($key in "user.name", "user.email") {
        if (git config --global $key) { continue }
        $label = if ($key -eq "user.name") { "git 이름 (예: GitHub 사용자명)" } else { "git 이메일" }
        try { $v = Read-Host "  $label" } catch { $v = "" }
        if ($v) { git config --global $key $v } else { Write-Warning "$key 비어 있음: 나중에 git config --global $key `"값`"" }
    }
    Write-Host "  $(git config --global user.name) <$(git config --global user.email)>"
} else { Write-Warning "git 명령 없음: 새 터미널에서 다시 실행" }

Step "3. VS Code Claude Code 확장"
if (Get-Command code -ErrorAction SilentlyContinue) {
    code --install-extension anthropic.claude-code 2>&1 | Select-Object -Last 1
} else { Write-Warning "code 명령 없음: 새 터미널에서 다시 실행" }

Step "4. Claude Code 설정 (플러그인, rtk, MCP)"
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Host "  [설치] Claude Code CLI (공식 설치 스크립트)"
    Invoke-RestMethod https://claude.ai/install.ps1 | Invoke-Expression
    $env:Path += ";$HOME\.local\bin"
}
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Warning "claude CLI 없음: 새 터미널에서 다시 실행"
} else {
    # Ponytail 저장소가 커서 기본 2분 제한으로는 clone 이 끊김
    $env:CLAUDE_CODE_PLUGIN_GIT_TIMEOUT_MS = "540000"
    $installed = claude plugin list 2>&1 | Out-String
    $plugins = @{ "ponytail@ponytail" = "DietrichGebert/ponytail"; "watch@claude-video" = "bradautomates/claude-video" }
    foreach ($p in $plugins.Keys) {
        if ($installed -match [regex]::Escape($p)) { Write-Host "  [있음] $p"; continue }
        claude plugin marketplace add $plugins[$p]
        claude plugin install $p
        if (-not ((claude plugin list 2>&1 | Out-String) -match [regex]::Escape($p))) { Write-Warning "$p 설치 실패: 네트워크 확인 후 다시 실행" }
    }

    # 출력을 다 받은 뒤 자른다 (파이프에서 바로 자르면 rtk 가 설정을 쓰다 중단될 수 있음)
    if (Get-Command rtk -ErrorAction SilentlyContinue) { $o = rtk init -g --auto-patch 2>&1; $o | Select-Object -First 2 }
    else { Write-Warning "rtk 명령 없음: 새 터미널에서 다시 실행" }

    claude mcp get context7 *> $null
    if ($LASTEXITCODE -eq 0) { Write-Host "  [있음] context7 MCP" }
    else { claude mcp add --scope user --transport http context7 https://mcp.context7.com/mcp }
}

Step "5. Claude 메모리 복원 (본인 PC끼리 옮길 때만, ..\.personal\memory 가 있을 때)"
if (Test-Path $memoryBackup) {
    New-Item -ItemType Directory -Force $memoryDir | Out-Null
    foreach ($f in Get-ChildItem "$memoryBackup\*.md") {
        $dest = Join-Path $memoryDir $f.Name
        # 대상 PC에 이미 있는 메모리는 덮어쓰지 않음 (그 PC에서 쌓인 내용 보호)
        if (Test-Path $dest) { Write-Host "  [유지] $($f.Name)" } else { Copy-Item $f.FullName $dest; Write-Host "  [복원] $($f.Name)" }
    }
} else { Write-Host "  건너뜀 (개인 메모리 백업 없음)" }

Step "남은 수동 단계"
Write-Host "  - GitHub 로그인: gh auth login --web --git-protocol https  (그다음 gh auth setup-git)"
Write-Host "  - Claude 앱 완전 종료 후 재시작"
Write-Host "  - VS Code 에서 Claude 확장 첫 로그인"

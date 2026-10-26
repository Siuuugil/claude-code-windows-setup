# Claude Code status line: model | context % | session cost | 5h limit % | Ponytail level
# Input: session JSON on stdin. Output: one line on stdout (ASCII only, safe for any console code page).
$j = $input | Out-String | ConvertFrom-Json
$parts = @()
$parts += "[$($j.model.display_name)]"

$ctx = $j.context_window.used_percentage
if ($null -ne $ctx) {
    $pct = [int]$ctx
    $filled = [math]::Min(10, [math]::Floor($pct / 10))
    $bar = ('#' * $filled) + ('-' * (10 - $filled))
    $parts += "ctx $bar $pct%"
}
if ($null -ne $j.cost.total_cost_usd) { $parts += ('$' + ('{0:N2}' -f [double]$j.cost.total_cost_usd)) }
$five = $j.rate_limits.five_hour.used_percentage
if ($null -ne $five) { $parts += "5h $([int]$five)%" }

$claudeDir = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME ".claude" }
$flag = Join-Path $claudeDir ".ponytail-active"
if (Test-Path $flag) {
    $mode = (Get-Content $flag -ErrorAction SilentlyContinue | Select-Object -First 1)
    $parts += if ($mode -and $mode.Trim() -ne "full") { "PONYTAIL:$($mode.Trim().ToUpper())" } else { "PONYTAIL" }
}
[Console]::Out.Write($parts -join " | ")

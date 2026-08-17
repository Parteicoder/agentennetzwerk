# Soft dependency check for native Windows / PowerShell.
# This helper never blocks Agentennetzwerk. The active plugin hook uses the Bash variant.

$missing = @()
foreach ($command in @('git', 'codex', 'grok')) {
    if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
        $missing += $command
    }
}

if ($missing.Count -gt 0) {
    Write-Warning "Agentennetzwerk: optionale Abhaengigkeit(en) fehlen: $($missing -join ', '). Das Plugin funktioniert weiter mit Einschraenkungen und Claude-Agenten als Fallback."
}

exit 0

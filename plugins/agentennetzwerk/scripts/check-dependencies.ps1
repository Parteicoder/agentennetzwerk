# Agentennetzwerk hard dependency gate for native Windows / PowerShell.
# Exit code 2 is intentional: Claude Code treats it as a blocking hook error.

$missing = @()

foreach ($command in @('git', 'codex', 'grok')) {
    if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
        $missing += $command
    }
}

if ($missing.Count -gt 0) {
    [Console]::Error.WriteLine("Agentennetzwerk kann nicht gestartet werden. Fehlende harte Abhaengigkeit(en): $($missing -join ', '). Installiere und authentifiziere alle benoetigten Coding-CLIs und starte Claude Code danach neu.")
    exit 2
}

try {
    & git --version *> $null
    if ($LASTEXITCODE -ne 0) { throw 'git' }
} catch {
    [Console]::Error.WriteLine('Agentennetzwerk blockiert: git wurde gefunden, kann aber nicht ausgefuehrt werden.')
    exit 2
}

try {
    & codex --version *> $null
    if ($LASTEXITCODE -ne 0) { throw 'codex' }
} catch {
    [Console]::Error.WriteLine('Agentennetzwerk blockiert: codex wurde gefunden, kann aber nicht ausgefuehrt werden. Pruefe Installation und PATH.')
    exit 2
}

try {
    & grok version *> $null
    if ($LASTEXITCODE -ne 0) { throw 'grok' }
} catch {
    [Console]::Error.WriteLine('Agentennetzwerk blockiert: grok wurde gefunden, kann aber nicht ausgefuehrt werden. Pruefe Installation und PATH.')
    exit 2
}

exit 0

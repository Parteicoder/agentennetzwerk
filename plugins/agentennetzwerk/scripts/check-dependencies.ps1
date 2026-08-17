# Optional local dependency probe for Windows. Never blocks Agentennetzwerk.
$missing = @()

try { & git --version *> $null; if ($LASTEXITCODE -ne 0) { throw } } catch { $missing += 'git' }
try { & codex --version *> $null; if ($LASTEXITCODE -ne 0) { throw } } catch { $missing += 'codex' }
try { & grok version *> $null; if ($LASTEXITCODE -ne 0) { throw } } catch { $missing += 'grok' }

if ($missing.Count -gt 0) {
    Write-Warning "Agentennetzwerk: optional tool(s) unavailable: $($missing -join ', '). The plugin still works with reduced capabilities."
}

exit 0

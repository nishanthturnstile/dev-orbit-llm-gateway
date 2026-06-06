[CmdletBinding()]
param(
    [switch]$SkipGitleaks
)

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$GitleaksImage = "ghcr.io/gitleaks/gitleaks:v8.24.2@sha256:b5918eb91b8d2473cec722f066abb4352e4ffdc4ec9f4283ec143aba9ec9ebc4"

function Fail([string]$Message) {
    throw $Message
}

function Redact([string]$Value) {
    if ($Value.Length -le 8) {
        return "<redacted>"
    }
    return ($Value.Substring(0, [Math]::Min(4, $Value.Length)) + "...<redacted>")
}

function Get-ScannedFiles {
    $files = & git -C $RepoRoot ls-files --cached --others --exclude-standard
    if ($LASTEXITCODE -ne 0) {
        Fail "Unable to list repository files for secret scanning."
    }
    $files | Where-Object {
        $_ -and
        $_ -notmatch '(^|/)\.git/' -and
        $_ -notmatch '(^|/)node_modules/' -and
        $_ -notmatch '(^|/)\.pytest_cache/' -and
        $_ -notmatch '(^|/)__pycache__/'
    }
}

function Test-AllowedHistoricalPhase0Url([string]$Path) {
    return $Path -match '^docs/(decisions/phase-0-|operations/implementation-status\.md|decisions/public-origin-risk-acceptance\.md)'
}

function Invoke-Gitleaks {
    if ($SkipGitleaks) {
        Write-Host "Skipping Gitleaks by request"
        return
    }

    $configPath = Join-Path $RepoRoot ".gitleaks.toml"
    if (-not (Test-Path $configPath)) {
        Fail "Missing .gitleaks.toml"
    }

    $gitleaks = Get-Command gitleaks -ErrorAction SilentlyContinue
    if ($gitleaks) {
        & $gitleaks.Source dir $RepoRoot --config $configPath --no-banner --redact --exit-code 1
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
        return
    }

    $docker = Get-Command docker -ErrorAction SilentlyContinue
    if (-not $docker) {
        Fail "Gitleaks is required. Install gitleaks or Docker, or pass -SkipGitleaks only for targeted script debugging."
    }

    $volume = "${RepoRoot}:/repo"
    & $docker.Source run --rm -v $volume $GitleaksImage dir /repo --config /repo/.gitleaks.toml --no-banner --redact --exit-code 1
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

$forbiddenTrackedFilePatterns = @(
    '(^|/)\.env$',
    '(^|/)\.env\.[^/]+$',
    '\.(key|pem|p12|pfx|dump|sql|bak)$'
)

$secretRules = @(
    @{ Id = "openai-key"; Pattern = 'sk-[A-Za-z0-9_-]{16,}' },
    @{ Id = "anthropic-key"; Pattern = 'sk-ant-[A-Za-z0-9_-]{16,}' },
    @{ Id = "litellm-key"; Pattern = 'sk-[A-Za-z0-9]{20,}' },
    @{ Id = "database-url"; Pattern = 'postgres(?:ql)?://[^<\s''"]+' },
    @{ Id = "redis-url"; Pattern = 'redis://[^<\s''"]+' },
    @{ Id = "private-key"; Pattern = 'BEGIN (?:RSA|OPENSSH|PRIVATE) KEY' },
    @{ Id = "railway-private-host"; Pattern = 'railway\.internal' },
    @{ Id = "railway-public-proof-host"; Pattern = '\.up\.railway\.app' },
    @{ Id = "cloudflare-token-assignment"; Pattern = '(?i)(TUNNEL_TOKEN|CLOUDFLARE_API_TOKEN|CLOUDFLARE_TUNNEL_TOKEN)\s*[:=]\s*["'']?[A-Za-z0-9_\-]{20,}' },
    @{ Id = "backup-secret-assignment"; Pattern = '(?i)(BACKUP_ENCRYPTION_KEY|RCLONE_CONFIG_[A-Z0-9_]+_(SECRET_ACCESS_KEY|ACCESS_KEY_ID))\s*[:=]\s*["'']?[A-Za-z0-9_\-+/=]{16,}' }
)

$violations = New-Object System.Collections.Generic.List[string]
$files = Get-ScannedFiles

foreach ($file in $files) {
    $normalized = $file -replace '\\', '/'
    foreach ($pattern in $forbiddenTrackedFilePatterns) {
        if ($normalized -match $pattern -and $normalized -ne ".env.example") {
            $violations.Add("Forbidden tracked local/secret artifact: $normalized")
        }
    }

    $path = Join-Path $RepoRoot $file
    if (-not (Test-Path $path -PathType Leaf)) {
        continue
    }

    $content = Get-Content $path -Raw -ErrorAction SilentlyContinue
    if ($null -eq $content) {
        continue
    }
    if ($normalized -in @(
        ".gitleaks.toml",
        "config/litellm/provider-denylist.yaml",
        "scripts/check-secrets.ps1",
        "scripts/phase0-validate-litellm.ps1",
        "scripts/validate-litellm-config.py"
    )) {
        continue
    }

    foreach ($rule in $secretRules) {
        $matches = [regex]::Matches($content, $rule.Pattern)
        foreach ($match in $matches) {
            if ($rule.Id -eq "railway-public-proof-host" -and (Test-AllowedHistoricalPhase0Url $normalized)) {
                continue
            }
            $line = ($content.Substring(0, $match.Index) -split "`n").Count
            $violations.Add("${normalized}:$line $($rule.Id) matched $(Redact $match.Value)")
        }
    }
}

if ($violations.Count -gt 0) {
    $violations | ForEach-Object { Write-Error $_ }
    Fail "Secret and repository artifact checks failed."
}

Invoke-Gitleaks

Write-Host "Secret scanning checks passed"

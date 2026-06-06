[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Fail([string]$Message) {
    throw $Message
}

function Get-PythonCommand {
    foreach ($candidate in @("python", "python3", "py")) {
        $command = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($command) {
            return $candidate
        }
    }
    Fail "Python 3 is required for LiteLLM config linting."
}

function Invoke-PythonValidator {
    $python = Get-PythonCommand
    $validator = Join-Path $RepoRoot "scripts\validate-litellm-config.py"
    if ($python -eq "py") {
        & $python -3 $validator --root $RepoRoot
    } else {
        & $python $validator --root $RepoRoot
    }
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

function Assert-Exists([string]$RelativePath) {
    if (-not (Test-Path (Join-Path $RepoRoot $RelativePath))) {
        Fail "Missing required file: $RelativePath"
    }
}

function Assert-TextContains([string]$RelativePath, [string]$Pattern, [string]$Message) {
    $path = Join-Path $RepoRoot $RelativePath
    $text = Get-Content $path -Raw
    if ($text -notmatch $Pattern) {
        Fail $Message
    }
}

function Assert-DockerfilesPinned {
    $dockerfiles = Get-ChildItem (Join-Path $RepoRoot "services") -Filter "Dockerfile" -Recurse
    foreach ($dockerfile in $dockerfiles) {
        $relative = [System.IO.Path]::GetRelativePath($RepoRoot, $dockerfile.FullName)
        $fromLines = Select-String -Path $dockerfile.FullName -Pattern '^\s*FROM\s+(.+)$'
        foreach ($line in $fromLines) {
            $image = $line.Matches[0].Groups[1].Value.Trim()
            if ($image -match ':latest(?:\s|$)') {
                Fail "$relative uses a latest tag: $image"
            }
            if ($image -notmatch '@sha256:[a-f0-9]{64}(?:\s|$)') {
                Fail "$relative must pin every FROM image by sha256 digest: $image"
            }
        }
    }
}

function Assert-GitignoreCoverage {
    $gitignore = Join-Path $RepoRoot ".gitignore"
    Assert-Exists ".gitignore"
    $required = @(".env", ".env.*", "!.env.example", "*.key", "*.pem", "*.p12", "*.pfx", "*.bak", "*.dump", "*.sql")
    $lines = Get-Content $gitignore
    foreach ($entry in $required) {
        if ($entry -notin $lines) {
            Fail ".gitignore is missing required protection: $entry"
        }
    }
}

function Assert-WorkflowPolicy {
    $workflowRoot = Join-Path $RepoRoot ".github\workflows"
    if (-not (Test-Path $workflowRoot)) {
        return
    }

    $workflows = Get-ChildItem $workflowRoot -Include "*.yml", "*.yaml" -Recurse
    foreach ($workflow in $workflows) {
        $relative = [System.IO.Path]::GetRelativePath($RepoRoot, $workflow.FullName)
        $text = Get-Content $workflow.FullName -Raw

        if ($text -match 'pull_request_target') {
            Fail "$relative must not use pull_request_target"
        }

        if ($text -match '(?m)^\s*(contents|actions|checks|deployments|id-token|packages|pull-requests|repository-projects|security-events|statuses):\s*write(?:\s*(?:#.*)?)?$') {
            Fail "$relative has a write permission not approved for Phase 3"
        }
        if ($text -match '(?m)^\s*permissions:\s*write-all(?:\s*(?:#.*)?)?$') {
            Fail "$relative must not use permissions: write-all"
        }

        if ($text -match '\$\{\{\s*secrets\.') {
            Fail "$relative must not reference GitHub secrets in Phase 3"
        }

        if ($text -match '(?im)\b(railway\s+(up|add|deploy)|railway\s+variable\s+set|cloudflared\s+tunnel\s+create|gh\s+secret\s+set)\b') {
            Fail "$relative contains a forbidden external mutation command"
        }

        $usesMatches = [regex]::Matches($text, '(?m)^\s*uses:\s*([^\s#]+)')
        foreach ($match in $usesMatches) {
            $uses = $match.Groups[1].Value
            if ($uses.StartsWith("./")) {
                continue
            }
            if ($uses -notmatch '@[a-f0-9]{40}$') {
                Fail "$relative has an unpinned uses reference: $uses"
            }
        }
    }
}

function Assert-YamlParses {
    $python = Get-PythonCommand
    $script = @"
from pathlib import Path
import yaml
root = Path(r'''$RepoRoot''')
paths = [
    root / 'services' / 'litellm' / 'config.yaml',
    root / 'config' / 'litellm' / 'model-aliases.yaml',
    root / 'config' / 'litellm' / 'provider-denylist.yaml',
    root / 'services' / 'cloudflared-tunnel' / 'config.example.yml',
]
workflow_root = root / '.github' / 'workflows'
if workflow_root.exists():
    paths.extend(workflow_root.glob('*.yml'))
    paths.extend(workflow_root.glob('*.yaml'))
for path in paths:
    with path.open('r', encoding='utf-8') as handle:
        yaml.safe_load(handle)
print('YAML parse checks passed')
"@
    $temp = Join-Path ([System.IO.Path]::GetTempPath()) "phase3-yaml-parse.py"
    [System.IO.File]::WriteAllText($temp, $script, [System.Text.UTF8Encoding]::new($false))
    try {
        if ($python -eq "py") {
            & $python -3 $temp
        } else {
            & $python $temp
        }
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
    } finally {
        Remove-Item $temp -Force -ErrorAction SilentlyContinue
    }
}

Assert-Exists "scripts\validate-litellm-config.py"
Assert-Exists "services\litellm\scripts\verify-config.sh"
Assert-Exists "services\litellm\config.yaml"
Assert-Exists "config\litellm\model-aliases.yaml"
Assert-Exists "config\litellm\provider-denylist.yaml"
Assert-Exists "services\litellm\Dockerfile"

if (Test-Path (Join-Path $RepoRoot "config\litellm\config.yaml")) {
    Fail "Former runtime config path must remain absent: config\litellm\config.yaml"
}

Assert-TextContains "services\litellm\Dockerfile" 'COPY\s+services/litellm/config\.yaml\s+/app/config\.yaml' "LiteLLM Dockerfile must copy services/litellm/config.yaml"
Invoke-PythonValidator
Assert-DockerfilesPinned
Assert-GitignoreCoverage
Assert-WorkflowPolicy
Assert-YamlParses

Write-Host "Phase 3 LiteLLM/config policy lint passed"

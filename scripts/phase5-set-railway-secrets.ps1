[CmdletBinding()]
param(
    [string]$Project = "0b1bc0ec-4ace-47c3-bd13-214256c27ad5",
    [string]$Environment = "staging",
    [string]$Service = "litellm-proxy"
)

$ErrorActionPreference = "Stop"

$railway = Get-Command railway -ErrorAction SilentlyContinue
if (-not $railway) {
    $candidate = Join-Path $env:APPDATA "npm\railway.cmd"
    if (Test-Path $candidate) {
        $railwayPath = $candidate
    } else {
        throw "Railway CLI was not found. Install it and authenticate with railway login first."
    }
} else {
    $railwayPath = $railway.Source
}

function ConvertFrom-SecureStringToPlainText {
    param([securestring]$Secure)

    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secure)
    try {
        [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

function Set-RailwaySecret {
    param(
        [string]$Name,
        [string]$Value
    )

    $Value | & $railwayPath variable set $Name --stdin --project $Project --environment $Environment --service $Service --skip-deploys --json | Out-Null
    Write-Host "Set $Name on $Service"
}

function Set-RailwayValue {
    param(
        [string]$Pair
    )

    & $railwayPath variable set $Pair --project $Project --environment $Environment --service $Service --skip-deploys --json | Out-Null
}

$masterKey = ConvertFrom-SecureStringToPlainText (Read-Host "Enter LITELLM_MASTER_KEY (must start with sk-)" -AsSecureString)
if (-not $masterKey.StartsWith("sk-")) {
    throw "LITELLM_MASTER_KEY must start with sk-"
}

$saltKey = ConvertFrom-SecureStringToPlainText (Read-Host "Enter LITELLM_SALT_KEY (strong random value, 32+ characters)" -AsSecureString)
if ($saltKey.Length -lt 32) {
    throw "LITELLM_SALT_KEY must be at least 32 characters"
}

$openAiKey = ConvertFrom-SecureStringToPlainText (Read-Host "Enter OPENAI_API_KEY" -AsSecureString)
if ([string]::IsNullOrWhiteSpace($openAiKey)) {
    throw "OPENAI_API_KEY cannot be empty"
}

$perplexityKey = ConvertFrom-SecureStringToPlainText (Read-Host "Enter PERPLEXITY_API_KEY" -AsSecureString)
if ([string]::IsNullOrWhiteSpace($perplexityKey)) {
    throw "PERPLEXITY_API_KEY cannot be empty"
}

Set-RailwaySecret -Name "LITELLM_MASTER_KEY" -Value $masterKey
Set-RailwaySecret -Name "LITELLM_SALT_KEY" -Value $saltKey
Set-RailwaySecret -Name "OPENAI_API_KEY" -Value $openAiKey
Set-RailwaySecret -Name "PERPLEXITY_API_KEY" -Value $perplexityKey

Set-RailwayValue -Pair 'DATABASE_URL=${{Postgres.DATABASE_URL}}'
Set-RailwayValue -Pair "ENVIRONMENT=staging"
Set-RailwayValue -Pair "PORT=4000"
Set-RailwayValue -Pair "NO_DOCS=True"
Set-RailwayValue -Pair "NO_REDOC=True"
Set-RailwayValue -Pair "NO_OPENAPI=True"
Set-RailwayValue -Pair "DISABLE_ADMIN_UI=true"

Write-Host "Phase 5 Railway variables are set. Values were not printed and deploys were skipped."

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

$perplexityKey = ConvertFrom-SecureStringToPlainText (Read-Host "Enter approved PERPLEXITY_API_KEY" -AsSecureString)
if ([string]::IsNullOrWhiteSpace($perplexityKey)) {
    throw "PERPLEXITY_API_KEY cannot be empty"
}

$perplexityKey | & $railwayPath variable set PERPLEXITY_API_KEY --stdin --project $Project --environment $Environment --service $Service --skip-deploys --json | Out-Null
Write-Host "Set PERPLEXITY_API_KEY on $Service. Value was not printed and deploys were skipped."

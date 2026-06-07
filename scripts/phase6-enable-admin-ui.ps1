[CmdletBinding()]
param(
    [string]$Project = "0b1bc0ec-4ace-47c3-bd13-214256c27ad5",
    [string]$Environment = "staging",
    [string]$Service = "litellm-proxy",
    [switch]$SkipRedeploy
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
    param([string]$Pair)

    & $railwayPath variable set $Pair --project $Project --environment $Environment --service $Service --skip-deploys --json | Out-Null
}

$username = Read-Host "Enter Admin UI username"
if ([string]::IsNullOrWhiteSpace($username)) {
    throw "Admin UI username cannot be empty"
}

$password = ConvertFrom-SecureStringToPlainText (Read-Host "Enter Admin UI password (minimum 16 characters)" -AsSecureString)
if ($password.Length -lt 16) {
    throw "Admin UI password must be at least 16 characters"
}

Set-RailwaySecret -Name "UI_USERNAME" -Value $username
Set-RailwaySecret -Name "UI_PASSWORD" -Value $password
Set-RailwayValue -Pair "DISABLE_ADMIN_UI=false"

Write-Host "Admin UI variables are set. Values were not printed."

if (-not $SkipRedeploy) {
    & $railwayPath redeploy --project $Project --environment $Environment --service $Service --yes | Out-Null
    Write-Host "Redeploy requested for $Service."
} else {
    Write-Host "Redeploy skipped by request. Redeploy $Service before testing /ui."
}

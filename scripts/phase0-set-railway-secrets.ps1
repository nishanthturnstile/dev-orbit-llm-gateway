param(
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

    $Value | & $railwayPath variable set $Name --stdin --service $Service --skip-deploys --json | Out-Null
    Write-Host "Set $Name on $Service"
}

$masterKey = ConvertFrom-SecureStringToPlainText (Read-Host "Enter LITELLM_MASTER_KEY (must start with sk-)" -AsSecureString)
if (-not $masterKey.StartsWith("sk-")) {
    throw "LITELLM_MASTER_KEY must start with sk-"
}

$openAiKey = ConvertFrom-SecureStringToPlainText (Read-Host "Enter OPENAI_API_KEY" -AsSecureString)
if ([string]::IsNullOrWhiteSpace($openAiKey)) {
    throw "OPENAI_API_KEY cannot be empty"
}

$uiPassword = ConvertFrom-SecureStringToPlainText (Read-Host "Enter UI_PASSWORD for LiteLLM Admin UI" -AsSecureString)
if ($uiPassword.Length -lt 16) {
    throw "UI_PASSWORD must be at least 16 characters for the public-origin proof"
}

Set-RailwaySecret -Name "LITELLM_MASTER_KEY" -Value $masterKey
Set-RailwaySecret -Name "OPENAI_API_KEY" -Value $openAiKey
Set-RailwaySecret -Name "UI_PASSWORD" -Value $uiPassword

Write-Host "Secret variables are set. Values were not printed."

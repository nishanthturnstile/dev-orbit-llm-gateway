[CmdletBinding()]
param(
    [switch]$ValidateOnly,
    [string]$GatewayBaseUrl,
    [string]$VirtualKey
)

$ErrorActionPreference = "Stop"

if ($ValidateOnly) {
    Write-Host "Staging smoke skeleton validated. Runtime smoke is deferred until durable staging exists."
    exit 0
}

if ([string]::IsNullOrWhiteSpace($GatewayBaseUrl)) {
    throw "GatewayBaseUrl is required for future runtime smoke tests."
}

if ([string]::IsNullOrWhiteSpace($VirtualKey)) {
    throw "VirtualKey is required for future runtime smoke tests."
}

throw "Runtime smoke execution is deferred until Phase 4/5 staging is available and explicitly approved."

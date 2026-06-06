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

function Invoke-SmokeRequest {
    param(
        [string]$Uri,
        [string]$Method = "GET",
        [hashtable]$Headers,
        [string]$ContentType,
        [string]$Body,
        [int]$TimeoutSec = 90
    )

    $params = @{
        Uri = $Uri
        Method = $Method
        TimeoutSec = $TimeoutSec
        ErrorAction = "Stop"
        UseBasicParsing = $true
    }
    if ((Get-Command Invoke-WebRequest).Parameters.ContainsKey("SkipHttpErrorCheck")) {
        $params.SkipHttpErrorCheck = $true
    }
    if ($Headers) { $params.Headers = $Headers }
    if ($ContentType) { $params.ContentType = $ContentType }
    if ($Body) { $params.Body = $Body }

    try {
        $response = Invoke-WebRequest @params
        return [pscustomobject]@{
            StatusCode = [int]$response.StatusCode
            Content = [string]$response.Content
        }
    } catch {
        return [pscustomobject]@{
            StatusCode = 0
            Content = $_.Exception.Message
        }
    }
}

function Redact([string]$Value) {
    $safe = $Value -replace "(?i)(sk-[A-Za-z0-9_\-]+|Bearer\s+\S+|postgres(?:ql)?://[^\s,}]+|[A-Za-z0-9_.-]+\.railway\.internal)", "[REDACTED]"
    if ($safe.Length -gt 240) { $safe = $safe.Substring(0, 240) }
    return $safe
}

$headers = @{ Authorization = "Bearer $VirtualKey" }
$results = @()

$chatBody = @{
    model = "dev-fast"
    messages = @(@{ role = "user"; content = "Reply with exactly OK." })
    max_tokens = 10
} | ConvertTo-Json -Depth 6

$chat = Invoke-SmokeRequest -Uri "$GatewayBaseUrl/v1/chat/completions" -Method POST -Headers $headers -ContentType "application/json" -Body $chatBody
$results += [pscustomobject]@{
    test = "dev-fast chat"
    status = [int]$chat.StatusCode
    passed = ($chat.StatusCode -ge 200 -and $chat.StatusCode -lt 300)
    detail = Redact $chat.Content
}

$streamBody = @{
    model = "dev-fast"
    messages = @(@{ role = "user"; content = "Reply with exactly STREAM_OK." })
    max_tokens = 10
    stream = $true
} | ConvertTo-Json -Depth 6

$stream = Invoke-SmokeRequest -Uri "$GatewayBaseUrl/v1/chat/completions" -Method POST -Headers $headers -ContentType "application/json" -Body $streamBody
$streamContent = [string]$stream.Content
$results += [pscustomobject]@{
    test = "dev-fast streaming"
    status = [int]$stream.StatusCode
    passed = ($stream.StatusCode -ge 200 -and $stream.StatusCode -lt 300 -and $streamContent.Contains("data:"))
    detail = if ($streamContent.Contains("data:")) { "stream chunks received" } else { Redact $streamContent }
}

$results | ConvertTo-Json -Depth 5

if ($results.Where({ -not $_.passed }).Count -gt 0) {
    exit 1
}

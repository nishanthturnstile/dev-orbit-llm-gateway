param(
    [string]$BaseUrl = "https://litellm-proxy-production-bd81.up.railway.app"
)

$ErrorActionPreference = "Continue"

$results = @()

function Invoke-Phase0Request {
    param(
        [string]$Uri,
        [string]$Method = "GET",
        [hashtable]$Headers,
        [string]$ContentType,
        [string]$Body,
        [int]$TimeoutSec = 30
    )

    try {
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

        $response = Invoke-WebRequest @params
        return [pscustomobject]@{
            StatusCode = [int]$response.StatusCode
            Content = [string]$response.Content
        }
    } catch {
        $statusCode = 0
        $content = $_.Exception.Message
        if ($_.Exception.Response) {
            try {
                $statusCode = [int]$_.Exception.Response.StatusCode
                if ($_.Exception.Response.Content -and $_.Exception.Response.Content.ReadAsStringAsync) {
                    $content = $_.Exception.Response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
                } elseif ($_.Exception.Response.GetResponseStream) {
                    $stream = $_.Exception.Response.GetResponseStream()
                    if ($stream) {
                        $reader = New-Object System.IO.StreamReader($stream)
                        $content = $reader.ReadToEnd()
                    }
                }
            } catch {
                $content = $_.Exception.Message
            }
        }

        return [pscustomobject]@{
            StatusCode = $statusCode
            Content = [string]$content
        }
    }
}

function Add-Phase0Result {
    param(
        [string]$Test,
        [int]$Status,
        [string]$Detail = ""
    )

    $safe = $Detail -replace "(?i)(sk-[A-Za-z0-9_\-]+|Bearer\s+\S+|OPENAI_API_KEY[^\s,}]*|postgresql://[^\s,}]+)", "[REDACTED]"
    if ($safe.Length -gt 240) {
        $safe = $safe.Substring(0, 240)
    }

    $script:results += [pscustomobject]@{
        test = $Test
        status = $Status
        detail = $safe
    }
}

$master = $env:LITELLM_MASTER_KEY
if ([string]::IsNullOrWhiteSpace($master)) {
    Add-Phase0Result -Test "master key env" -Status 0 -Detail "LITELLM_MASTER_KEY missing"
    $results | ConvertTo-Json -Depth 5
    exit 0
}

try {
    $headers = @{ Authorization = "Bearer $master" }
    $keyAlias = "phase0-proof-{0}" -f ([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())
    $payload = @{
        key_alias = $keyAlias
        models = @("dev-fast")
        max_budget = 0.05
        rpm_limit = 10
        duration = "1d"
    } | ConvertTo-Json -Depth 6

    $resp = Invoke-Phase0Request -Uri "$BaseUrl/key/generate" -Method POST -Headers $headers -ContentType "application/json" -Body $payload -TimeoutSec 60
    Add-Phase0Result -Test "generate virtual key" -Status ([int]$resp.StatusCode) -Detail $resp.Content
    if ($resp.StatusCode -lt 200 -or $resp.StatusCode -ge 300) {
        $results | ConvertTo-Json -Depth 5
        exit 0
    }

    $generated = $resp.Content | ConvertFrom-Json
    $devKey = if ($generated.key) { $generated.key } elseif ($generated.token) { $generated.token } else { $null }
    if ([string]::IsNullOrWhiteSpace($devKey)) {
        Add-Phase0Result -Test "extract virtual key" -Status 0 -Detail "No key/token property in response"
        $results | ConvertTo-Json -Depth 5
        exit 0
    }

    $devHeaders = @{ Authorization = "Bearer $devKey" }
    $sentinel = "phase0_no_log_sentinel_20260606"

    $chatBody = @{
        model = "dev-fast"
        messages = @(@{ role = "user"; content = "Reply with exactly OK. Sentinel: $sentinel" })
        max_tokens = 10
    } | ConvertTo-Json -Depth 6
    $chat = Invoke-Phase0Request -Uri "$BaseUrl/v1/chat/completions" -Method POST -Headers $devHeaders -ContentType "application/json" -Body $chatBody -TimeoutSec 90
    Add-Phase0Result -Test "valid-key chat" -Status ([int]$chat.StatusCode) -Detail $chat.Content

    $streamBody = @{
        model = "dev-fast"
        messages = @(@{ role = "user"; content = "Reply with exactly STREAM_OK" })
        max_tokens = 10
        stream = $true
    } | ConvertTo-Json -Depth 6
    $stream = Invoke-Phase0Request -Uri "$BaseUrl/v1/chat/completions" -Method POST -Headers $devHeaders -ContentType "application/json" -Body $streamBody -TimeoutSec 90
    $streamText = [string]$stream.Content
    $streamDetail = if ($streamText -match "data:") { "stream chunks received" } else { $streamText }
    Add-Phase0Result -Test "valid-key streaming" -Status ([int]$stream.StatusCode) -Detail $streamDetail

    $admin = Invoke-Phase0Request -Uri "$BaseUrl/key/list" -Method GET -Headers $devHeaders -TimeoutSec 30
    Add-Phase0Result -Test "developer key admin route" -Status ([int]$admin.StatusCode) -Detail $admin.Content

    Add-Phase0Result -Test "sentinel" -Status 200 -Detail $sentinel
} catch {
    Add-Phase0Result -Test "exception" -Status 0 -Detail $_.Exception.Message
}

$results | ConvertTo-Json -Depth 5

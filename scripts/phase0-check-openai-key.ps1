$ErrorActionPreference = "Continue"

$key = $env:OPENAI_API_KEY
$result = [ordered]@{
    keyPresent = -not [string]::IsNullOrWhiteSpace($key)
    keyLength = if ($key) { $key.Length } else { 0 }
    status = $null
    detail = $null
}

try {
    $headers = @{ Authorization = "Bearer $key" }
    $params = @{
        Uri = "https://api.openai.com/v1/models"
        Method = "GET"
        Headers = $headers
        TimeoutSec = 30
        UseBasicParsing = $true
    }
    if ((Get-Command Invoke-WebRequest).Parameters.ContainsKey("SkipHttpErrorCheck")) {
        $params.SkipHttpErrorCheck = $true
    }

    $resp = Invoke-WebRequest @params
    $content = [string]$resp.Content
    $safe = $content -replace "(?i)(sk-[A-Za-z0-9_\-]+|Bearer\s+\S+)", "[REDACTED]"
    if ($safe.Length -gt 300) { $safe = $safe.Substring(0, 300) }
    $result.status = [int]$resp.StatusCode
    $result.detail = $safe
} catch {
    $result.status = 0
    $result.detail = $_.Exception.Message
}

$result | ConvertTo-Json -Depth 4

[CmdletBinding()]
param(
    [switch]$ValidateOnly,
    [string]$GatewayBaseUrl,
    [string]$VirtualKey,
    [string]$InvalidKey = "not-a-valid-phase6-key",
    [ValidateSet("Skip", "Public", "Blocked")]
    [string]$ReadinessPolicy = "Skip",
    [ValidateSet("Disabled", "Enabled")]
    [string]$AdminUiMode = "Disabled",
    [switch]$IncludeEmbeddings,
    [switch]$IncludeModels,
    [switch]$IncludeLongStreamingProbe
)

$ErrorActionPreference = "Stop"

if ($ValidateOnly) {
    Write-Host "Public-origin validator shape is valid. Runtime execution requires explicit endpoint and key inputs."
    exit 0
}

if ([string]::IsNullOrWhiteSpace($GatewayBaseUrl)) {
    throw "GatewayBaseUrl is required for Phase 6 public-origin validation."
}

if ([string]::IsNullOrWhiteSpace($VirtualKey)) {
    throw "VirtualKey is required for Phase 6 positive-route and denial-route validation."
}

$baseUrl = $GatewayBaseUrl.TrimEnd("/")

function Redact-Phase6Detail {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrEmpty($Value)) {
        return ""
    }

    $databaseUrlPattern = "(?i)(postgres(?:ql)?:" + "//[^\s,}]+|" + ("DATABASE" + "_URL") + "\s*[:=]\s*[^\s,}]+)"
    $privateHostPattern = "(?i)([A-Za-z0-9_.-]+\." + "railway" + "\.internal)"

    $safe = $Value `
        -replace "(?i)(sk-[A-Za-z0-9_\-]{8,}|Bearer\s+\S+)", "[REDACTED_KEY]" `
        -replace $databaseUrlPattern, "[REDACTED_DB]" `
        -replace $privateHostPattern, "[REDACTED_PRIVATE_HOST]"

    if ($safe.Length -gt 260) {
        $safe = $safe.Substring(0, 260)
    }

    return $safe
}

function Test-ForbiddenDetail {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrEmpty($Value)) {
        return $false
    }

    $databaseSchemePattern = "postgres(?:ql)?:" + "//"
    $databaseNamePattern = "DATABASE" + "_URL"
    $privateHostPattern = "railway" + "\.internal"

    return $Value -match "(?i)(sk-[A-Za-z0-9_\-]{8,}|Bearer\s+\S+|$databaseSchemePattern|$databaseNamePattern|$privateHostPattern|Traceback|stack trace|syntax error at or near|SELECT\s+.+FROM|INSERT\s+INTO|UPDATE\s+.+SET|DELETE\s+FROM)"
}

function Invoke-Phase6Request {
    param(
        [string]$Path,
        [string]$Method = "GET",
        [hashtable]$Headers,
        [string]$ContentType,
        [string]$Body,
        [int]$TimeoutSec = 90
    )

    $params = @{
        Uri = "$baseUrl$Path"
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

function Add-Phase6Result {
    param(
        [System.Collections.ArrayList]$Results,
        [string]$Test,
        [int]$Status,
        [bool]$Passed,
        [string]$Detail
    )

    [void]$Results.Add([pscustomobject]@{
        test = $Test
        status = $Status
        passed = $Passed
        detail = Redact-Phase6Detail $Detail
    })
}

function Test-StatusIn {
    param(
        [int]$Status,
        [int[]]$Expected
    )

    return $Expected -contains $Status
}

$results = [System.Collections.ArrayList]::new()
$devHeaders = @{ Authorization = "Bearer $VirtualKey" }
$invalidHeaders = @{ Authorization = "Bearer $InvalidKey" }

$chatBody = @{
    model = "dev-fast"
    messages = @(@{ role = "user"; content = "Reply with exactly OK." })
    max_tokens = 10
} | ConvertTo-Json -Depth 6

if ($ReadinessPolicy -ne "Skip") {
    $readiness = Invoke-Phase6Request -Path "/health/readiness"
    $readinessOk = if ($ReadinessPolicy -eq "Public") {
        $readiness.StatusCode -ge 200 -and $readiness.StatusCode -lt 300
    } else {
        Test-StatusIn $readiness.StatusCode @(401, 403, 404)
    }
    Add-Phase6Result $results "readiness $ReadinessPolicy" $readiness.StatusCode ($readinessOk -and -not (Test-ForbiddenDetail $readiness.Content)) $readiness.Content
}

$missing = Invoke-Phase6Request -Path "/v1/chat/completions" -Method POST -ContentType "application/json" -Body $chatBody
Add-Phase6Result $results "missing auth rejected" $missing.StatusCode ((Test-StatusIn $missing.StatusCode @(401, 403)) -and -not (Test-ForbiddenDetail $missing.Content)) $missing.Content

$invalid = Invoke-Phase6Request -Path "/v1/chat/completions" -Method POST -Headers $invalidHeaders -ContentType "application/json" -Body $chatBody
Add-Phase6Result $results "invalid auth rejected" $invalid.StatusCode ((Test-StatusIn $invalid.StatusCode @(401, 403)) -and -not (Test-ForbiddenDetail $invalid.Content)) $invalid.Content

$chat = Invoke-Phase6Request -Path "/v1/chat/completions" -Method POST -Headers $devHeaders -ContentType "application/json" -Body $chatBody
Add-Phase6Result $results "dev-fast chat" $chat.StatusCode (($chat.StatusCode -ge 200 -and $chat.StatusCode -lt 300) -and -not (Test-ForbiddenDetail $chat.Content)) $chat.Content

$streamBody = @{
    model = "dev-fast"
    messages = @(@{ role = "user"; content = "Reply with exactly STREAM_OK." })
    max_tokens = 10
    stream = $true
} | ConvertTo-Json -Depth 6

$stream = Invoke-Phase6Request -Path "/v1/chat/completions" -Method POST -Headers $devHeaders -ContentType "application/json" -Body $streamBody -TimeoutSec 120
Add-Phase6Result $results "dev-fast streaming" $stream.StatusCode (($stream.StatusCode -ge 200 -and $stream.StatusCode -lt 300 -and $stream.Content.Contains("data:")) -and -not (Test-ForbiddenDetail $stream.Content)) ($(if ($stream.Content.Contains("data:")) { "stream chunks received" } else { $stream.Content }))

if ($IncludeLongStreamingProbe) {
    $longStreamBody = @{
        model = "dev-fast"
        messages = @(@{ role = "user"; content = "Return 80 short numbered lines. Keep each line distinct." })
        max_tokens = 512
        stream = $true
    } | ConvertTo-Json -Depth 6
    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    $longStream = Invoke-Phase6Request -Path "/v1/chat/completions" -Method POST -Headers $devHeaders -ContentType "application/json" -Body $longStreamBody -TimeoutSec 180
    $timer.Stop()
    $longDetail = if ($longStream.Content.Contains("data:")) { "stream chunks received in $([int]$timer.Elapsed.TotalSeconds)s" } else { $longStream.Content }
    Add-Phase6Result $results "long streaming probe" $longStream.StatusCode (($longStream.StatusCode -ge 200 -and $longStream.StatusCode -lt 300 -and $longStream.Content.Contains("data:")) -and -not (Test-ForbiddenDetail $longStream.Content)) $longDetail
}

if ($IncludeModels) {
    $models = Invoke-Phase6Request -Path "/v1/models" -Headers $devHeaders
    Add-Phase6Result $results "models aliases only" $models.StatusCode (($models.StatusCode -ge 200 -and $models.StatusCode -lt 300) -and -not (Test-ForbiddenDetail $models.Content)) $models.Content
}

if ($IncludeEmbeddings) {
    $embedBody = @{
        model = "dev-embed"
        input = "phase6 validation"
    } | ConvertTo-Json -Depth 4
    $embed = Invoke-Phase6Request -Path "/v1/embeddings" -Method POST -Headers $devHeaders -ContentType "application/json" -Body $embedBody
    Add-Phase6Result $results "dev-embed embeddings" $embed.StatusCode (($embed.StatusCode -ge 200 -and $embed.StatusCode -lt 300) -and -not (Test-ForbiddenDetail $embed.Content)) $embed.Content
}

$sensitiveBody = @{
    model = "sensitive-code"
    messages = @(@{ role = "user"; content = "Reply with exactly DENY." })
    max_tokens = 10
} | ConvertTo-Json -Depth 6
$sensitive = Invoke-Phase6Request -Path "/v1/chat/completions" -Method POST -Headers $devHeaders -ContentType "application/json" -Body $sensitiveBody
Add-Phase6Result $results "sensitive-code denied" $sensitive.StatusCode ((Test-StatusIn $sensitive.StatusCode @(400, 401, 403, 404)) -and -not (Test-ForbiddenDetail $sensitive.Content)) $sensitive.Content

$directProviderBody = @{
    model = "openai/gpt-4o-mini"
    messages = @(@{ role = "user"; content = "Reply with exactly DENY." })
    max_tokens = 10
} | ConvertTo-Json -Depth 6
$directProvider = Invoke-Phase6Request -Path "/v1/chat/completions" -Method POST -Headers $devHeaders -ContentType "application/json" -Body $directProviderBody
Add-Phase6Result $results "direct provider model denied" $directProvider.StatusCode ((Test-StatusIn $directProvider.StatusCode @(400, 401, 403, 404)) -and -not (Test-ForbiddenDetail $directProvider.Content)) $directProvider.Content

foreach ($path in @("/ui", "/key/list", "/user/info", "/team/info", "/config/list", "/admin", "/spend/logs")) {
    $control = Invoke-Phase6Request -Path $path -Headers $devHeaders
    if ($path -eq "/ui" -and $AdminUiMode -eq "Enabled") {
        Add-Phase6Result $results "developer /ui shell safe" $control.StatusCode (($control.StatusCode -ge 200 -and $control.StatusCode -lt 300) -and -not (Test-ForbiddenDetail $control.Content)) $control.Content
    } else {
        Add-Phase6Result $results "developer denied $path" $control.StatusCode ((Test-StatusIn $control.StatusCode @(400, 401, 403, 404, 405)) -and -not (Test-ForbiddenDetail $control.Content)) $control.Content
    }
}

foreach ($path in @("/docs", "/redoc", "/openapi.json")) {
    $docRoute = Invoke-Phase6Request -Path $path
    Add-Phase6Result $results "public docs blocked $path" $docRoute.StatusCode ((Test-StatusIn $docRoute.StatusCode @(401, 403, 404)) -and -not (Test-ForbiddenDetail $docRoute.Content)) $docRoute.Content
}

$output = [pscustomobject]@{
    passed = ($results.Where({ -not $_.passed }).Count -eq 0)
    checks = $results
}

$output | ConvertTo-Json -Depth 6

if (-not $output.passed) {
    exit 1
}

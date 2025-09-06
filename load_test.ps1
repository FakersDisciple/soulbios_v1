# PowerShell script for load testing /chat endpoint with 10 concurrent requests
# Measures P95 latency and performance metrics

param(
    [string]$BaseUrl = "http://localhost:8000"
)

$ErrorActionPreference = "Continue"
$results = @()
$startTime = Get-Date

Write-Host "🚀 Starting load test with 10 concurrent requests to $BaseUrl/chat..." -ForegroundColor Green

# Define the request body
$requestBody = @{
    user_id = "load_test_user"
    message = "Performance test - optimize my personal growth"
} | ConvertTo-Json

# Function to make a single request and measure time
function Invoke-TimedRequest {
    param($RequestNumber)
    
    $requestStart = Get-Date
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/chat" -Method Post -Body $requestBody -ContentType "application/json" -TimeoutSec 30
        $requestEnd = Get-Date
        $latency = ($requestEnd - $requestStart).TotalMilliseconds
        
        return @{
            RequestNumber = $RequestNumber
            Success = $true
            LatencyMs = $latency
            ResponseLength = $response.response.Length
            Timestamp = $requestStart
        }
    }
    catch {
        $requestEnd = Get-Date
        $latency = ($requestEnd - $requestStart).TotalMilliseconds
        
        return @{
            RequestNumber = $RequestNumber
            Success = $false
            LatencyMs = $latency
            Error = $_.Exception.Message
            Timestamp = $requestStart
        }
    }
}

# Execute 10 concurrent requests using PowerShell jobs
Write-Host "Launching 10 concurrent requests..." -ForegroundColor Yellow

$jobs = @()
for ($i = 1; $i -le 10; $i++) {
    $job = Start-Job -ScriptBlock ${function:Invoke-TimedRequest} -ArgumentList $i -InitializationScript {
        param($BaseUrl, $requestBody)
        
        function Invoke-TimedRequest {
            param($RequestNumber)
            
            $requestStart = Get-Date
            try {
                $response = Invoke-RestMethod -Uri "$using:BaseUrl/chat" -Method Post -Body $using:requestBody -ContentType "application/json" -TimeoutSec 30
                $requestEnd = Get-Date
                $latency = ($requestEnd - $requestStart).TotalMilliseconds
                
                return @{
                    RequestNumber = $RequestNumber
                    Success = $true
                    LatencyMs = $latency
                    ResponseLength = $response.response.Length
                    Timestamp = $requestStart
                }
            }
            catch {
                $requestEnd = Get-Date
                $latency = ($requestEnd - $requestStart).TotalMilliseconds
                
                return @{
                    RequestNumber = $RequestNumber
                    Success = $false
                    LatencyMs = $latency
                    Error = $_.Exception.Message
                    Timestamp = $requestStart
                }
            }
        }
    }
    $jobs += $job
}

# Wait for all jobs to complete
Write-Host "Waiting for requests to complete..." -ForegroundColor Yellow
$results = $jobs | Wait-Job | Receive-Job
$jobs | Remove-Job

$endTime = Get-Date
$totalDuration = ($endTime - $startTime).TotalMilliseconds

# Process results
$successfulRequests = $results | Where-Object { $_.Success -eq $true }
$failedRequests = $results | Where-Object { $_.Success -eq $false }

Write-Host "`n📊 LOAD TEST RESULTS" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan

if ($successfulRequests.Count -gt 0) {
    $latencies = $successfulRequests | ForEach-Object { $_.LatencyMs }
    $sortedLatencies = $latencies | Sort-Object
    
    $min = [math]::Round($sortedLatencies[0], 1)
    $max = [math]::Round($sortedLatencies[-1], 1)
    $avg = [math]::Round(($latencies | Measure-Object -Average).Average, 1)
    $median = [math]::Round($sortedLatencies[[math]::Floor($sortedLatencies.Count / 2)], 1)
    
    # Calculate P95 (95th percentile)
    $p95Index = [math]::Floor($sortedLatencies.Count * 0.95)
    $p95 = [math]::Round($sortedLatencies[$p95Index], 1)
    
    Write-Host "✅ Successful requests: $($successfulRequests.Count)/10" -ForegroundColor Green
    Write-Host "❌ Failed requests: $($failedRequests.Count)/10" -ForegroundColor Red
    Write-Host ""
    Write-Host "⏱️  LATENCY METRICS:" -ForegroundColor White
    Write-Host "   Min: ${min}ms" -ForegroundColor White
    Write-Host "   Max: ${max}ms" -ForegroundColor White
    Write-Host "   Avg: ${avg}ms" -ForegroundColor White
    Write-Host "   Median: ${median}ms" -ForegroundColor White
    Write-Host "   P95: ${p95}ms" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "🎯 TARGET ANALYSIS:" -ForegroundColor White
    Write-Host "   Target Range: 800-1000ms" -ForegroundColor White
    
    if ($p95 -le 1000) {
        Write-Host "   P95 Status: ✅ WITHIN TARGET" -ForegroundColor Green
    } elseif ($p95 -le 1500) {
        Write-Host "   P95 Status: ⚠️  ABOVE TARGET BUT ACCEPTABLE" -ForegroundColor Yellow
    } else {
        Write-Host "   P95 Status: ❌ ESCALATION REQUIRED (>1.5s)" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "📈 PERFORMANCE BREAKDOWN:" -ForegroundColor White
    $results | Sort-Object RequestNumber | ForEach-Object {
        $status = if ($_.Success) { "✅" } else { "❌" }
        $latency = [math]::Round($_.LatencyMs, 1)
        Write-Host "   Request $($_.RequestNumber): $status ${latency}ms" -ForegroundColor Gray
    }
    
    # Log to file
    $logEntry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Load test: 10 concurrent requests - P95: ${p95}ms, Avg: ${avg}ms, Success: $($successfulRequests.Count)/10"
    Add-Content -Path "claude_log.txt" -Value $logEntry
    
    Write-Host "`n📝 Results logged to claude_log.txt" -ForegroundColor Cyan
    
} else {
    Write-Host "❌ All requests failed!" -ForegroundColor Red
    $failedRequests | ForEach-Object {
        Write-Host "Request $($_.RequestNumber): $($_.Error)" -ForegroundColor Red
    }
}

Write-Host "`nTotal test duration: $([math]::Round($totalDuration, 1))ms" -ForegroundColor Gray
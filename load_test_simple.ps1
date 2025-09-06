# Simplified PowerShell script for load testing /chat endpoint
$results = @()
$startTime = Get-Date

Write-Host "Starting load test with 10 concurrent requests..." -ForegroundColor Green

# Create 10 concurrent requests
$jobs = @()
for ($i = 1; $i -le 10; $i++) {
    $jobs += Start-Job -ScriptBlock {
        param($requestNum)
        $start = Get-Date
        try {
            $body = '{"user_id": "load_test_user", "message": "Performance test - optimize my personal growth"}'
            $response = Invoke-RestMethod -Uri "http://localhost:8000/chat" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
            $end = Get-Date
            $latency = ($end - $start).TotalMilliseconds
            return @{ Success = $true; Latency = $latency; Request = $requestNum }
        }
        catch {
            $end = Get-Date
            $latency = ($end - $start).TotalMilliseconds
            return @{ Success = $false; Latency = $latency; Request = $requestNum; Error = $_.Exception.Message }
        }
    } -ArgumentList $i
}

# Wait for all jobs and collect results
$results = $jobs | Wait-Job | Receive-Job
$jobs | Remove-Job

$endTime = Get-Date
$totalDuration = ($endTime - $startTime).TotalMilliseconds

# Process results
$successful = $results | Where-Object { $_.Success -eq $true }
$failed = $results | Where-Object { $_.Success -eq $false }

Write-Host ""
Write-Host "LOAD TEST RESULTS" -ForegroundColor Cyan
Write-Host "=================" -ForegroundColor Cyan

if ($successful.Count -gt 0) {
    $latencies = $successful | ForEach-Object { $_.Latency }
    $sortedLatencies = $latencies | Sort-Object
    
    $min = [math]::Round($sortedLatencies[0], 1)
    $max = [math]::Round($sortedLatencies[-1], 1)
    $avg = [math]::Round(($latencies | Measure-Object -Average).Average, 1)
    
    # Calculate P95
    $p95Index = [math]::Floor($sortedLatencies.Count * 0.95)
    $p95 = [math]::Round($sortedLatencies[$p95Index], 1)
    
    Write-Host "Successful: $($successful.Count)/10" -ForegroundColor Green
    Write-Host "Failed: $($failed.Count)/10" -ForegroundColor Red
    Write-Host "Min: ${min}ms, Max: ${max}ms, Avg: ${avg}ms" -ForegroundColor White
    Write-Host "P95: ${p95}ms" -ForegroundColor Yellow
    
    if ($p95 -le 1000) {
        Write-Host "P95 Status: WITHIN TARGET (800-1000ms)" -ForegroundColor Green
    } elseif ($p95 -le 1500) {
        Write-Host "P95 Status: ABOVE TARGET BUT ACCEPTABLE" -ForegroundColor Yellow
    } else {
        Write-Host "P95 Status: ESCALATION REQUIRED (>1.5s)" -ForegroundColor Red
    }
    
    # Log results
    $logEntry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Load test: P95=${p95}ms, Avg=${avg}ms, Success=$($successful.Count)/10"
    Add-Content -Path "claude_log.txt" -Value $logEntry
    Write-Host "Results logged to claude_log.txt" -ForegroundColor Cyan
}

Write-Host "Total duration: $([math]::Round($totalDuration, 1))ms" -ForegroundColor Gray
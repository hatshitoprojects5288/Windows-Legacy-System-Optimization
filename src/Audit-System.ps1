<#
.SYNOPSIS
    System Environment Auditor for Legacy Windows Architecture.
.AUTHOR
    JOSHUA SAMAL | Digital Infrastructure
#>

$ErrorActionPreference = "Stop"

function Get-SystemMetrics {
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "   RDJ | System Infrastructure Audit   " -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan

    $processCount = (Get-Process).Count
    Write-Host "[+] Total Active Processes: $processCount" -ForegroundColor Green

    $threadCount = (Get-Process | Select-Object -ExpandProperty Threads).Count
    Write-Host "[+] Total Active Threads:   $threadCount" -ForegroundColor White

    $osInfo = Get-CimInstance Win32_OperatingSystem
    $totalRam = [math]::Round($osInfo.TotalVisibleMemorySize / 1MB, 2)
    $freeRam = [math]::Round($osInfo.FreePhysicalMemory / 1MB, 2)
    $usedRam = $totalRam - $freeRam

    Write-Host "[+] Physical Memory Usage:  $usedRam GB / $totalRam GB" -ForegroundColor White
    Write-Host "==========================================" -ForegroundColor Cyan
}

Get-SystemMetrics

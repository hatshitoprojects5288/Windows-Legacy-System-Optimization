<#
.SYNOPSIS
    Centralized logging framework for Windows optimization scripts.

.DESCRIPTION
    Provides standardized logging functions with severity levels, timestamps, and file output.
    Supports console output with color-coding and persistent file logging for troubleshooting.

.EXAMPLE
    Initialize-Logging -LogPath "C:\Logs\optimization.log"
    Write-LogMessage -Level "INFO" -Message "Starting optimization process"
    Write-LogMessage -Level "WARN" -Message "Critical registry change ahead"
    Write-LogMessage -Level "ERROR" -Message "Operation failed"
    Close-Logging

.NOTES
    Author: Windows-Legacy-System-Optimization Team
    Version: 1.0
    Production-Ready: Yes
#>

# Module-level variables
$script:LogPath = $null
$script:LogFileHandle = $null
$script:LogLevels = @{
    'DEBUG'   = 0
    'INFO'    = 1
    'WARN'    = 2
    'ERROR'   = 3
    'CRITICAL' = 4
}

<#
.SYNOPSIS
    Initialize the logging system.

.PARAMETER LogPath
    Path where log file will be created. If not specified, uses temp directory.

.PARAMETER Append
    If $true, appends to existing log file. If $false, creates new log file.
#>
function Initialize-Logging {
    param(
        [Parameter(Mandatory=$false)]
        [string]$LogPath,
        
        [Parameter(Mandatory=$false)]
        [bool]$Append = $true
    )
    
    try {
        # Default log path if not specified
        if ([string]::IsNullOrWhiteSpace($LogPath)) {
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $LogPath = Join-Path $env:TEMP "Windows-Optimization_$timestamp.log"
        }
        
        # Ensure log directory exists
        $logDir = Split-Path -Parent $LogPath
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        
        # Create or append to log file
        $fileMode = if ($Append) { [System.IO.FileMode]::Append } else { [System.IO.FileMode]::Create }
        $script:LogFileHandle = New-Object System.IO.FileStream(
            $LogPath,
            $fileMode,
            [System.IO.FileAccess]::Write,
            [System.IO.FileShare]::Read
        )
        
        $script:LogPath = $LogPath
        
        Write-LogMessage -Level "INFO" -Message "Logging initialized: $LogPath"
    }
    catch {
        Write-Error "Failed to initialize logging: $_"
        throw
    }
}

<#
.SYNOPSIS
    Write a log message with timestamp and severity level.

.PARAMETER Level
    Severity level: DEBUG, INFO, WARN, ERROR, CRITICAL

.PARAMETER Message
    The message to log

.PARAMETER ShowConsole
    If $true, also display message on console (default: $true)
#>
function Write-LogMessage {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('DEBUG', 'INFO', 'WARN', 'ERROR', 'CRITICAL')]
        [string]$Level,
        
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [bool]$ShowConsole = $true
    )
    
    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        $logEntry = "[$timestamp] [$Level] $Message"
        
        # Write to file if logging is initialized
        if ($script:LogFileHandle) {
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($logEntry + "`n")
            $script:LogFileHandle.Write($bytes, 0, $bytes.Length)
            $script:LogFileHandle.Flush()
        }
        
        # Console output with color coding
        if ($ShowConsole) {
            $consoleColor = switch ($Level) {
                'DEBUG'    { 'Gray' }
                'INFO'     { 'White' }
                'WARN'     { 'Yellow' }
                'ERROR'    { 'Red' }
                'CRITICAL' { 'Red' }
                default    { 'White' }
            }
            
            Write-Host $logEntry -ForegroundColor $consoleColor
        }
    }
    catch {
        Write-Error "Failed to write log message: $_"
    }
}

<#
.SYNOPSIS
    Write a debug message to log.
#>
function Write-LogDebug {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    Write-LogMessage -Level "DEBUG" -Message $Message -ShowConsole $false
}

<#
.SYNOPSIS
    Write an info message to log.
#>
function Write-LogInfo {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    Write-LogMessage -Level "INFO" -Message $Message
}

<#
.SYNOPSIS
    Write a warning message to log.
#>
function Write-LogWarning {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    Write-LogMessage -Level "WARN" -Message $Message
}

<#
.SYNOPSIS
    Write an error message to log.
#>
function Write-LogError {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [Exception]$Exception
    )
    
    $msg = if ($Exception) { "$Message : $($Exception.Message)" } else { $Message }
    Write-LogMessage -Level "ERROR" -Message $msg
}

<#
.SYNOPSIS
    Write a critical message to log.
#>
function Write-LogCritical {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [Exception]$Exception
    )
    
    $msg = if ($Exception) { "$Message : $($Exception.Message)" } else { $Message }
    Write-LogMessage -Level "CRITICAL" -Message $msg
}

<#
.SYNOPSIS
    Close the logging system and flush all pending writes.
#>
function Close-Logging {
    try {
        if ($script:LogFileHandle) {
            $script:LogFileHandle.Flush()
            $script:LogFileHandle.Dispose()
            $script:LogFileHandle = $null
            
            Write-Host "Log saved: $script:LogPath" -ForegroundColor Green
        }
    }
    catch {
        Write-Error "Failed to close logging: $_"
    }
}

<#
.SYNOPSIS
    Get the current log file path.
#>
function Get-LogPath {
    return $script:LogPath
}

# Export public functions
Export-ModuleMember -Function @(
    'Initialize-Logging',
    'Write-LogMessage',
    'Write-LogDebug',
    'Write-LogInfo',
    'Write-LogWarning',
    'Write-LogError',
    'Write-LogCritical',
    'Close-Logging',
    'Get-LogPath'
)

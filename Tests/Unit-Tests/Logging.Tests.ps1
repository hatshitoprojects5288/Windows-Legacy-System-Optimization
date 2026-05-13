# Unit Tests for Logging Module
# Tests/Unit-Tests/Logging.Tests.ps1

BeforeAll {
    $ModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) "..\Scripts\Utils\Logging.ps1"
    Import-Module $ModulePath -Force
}

AfterAll {
    Remove-Module Logging -ErrorAction SilentlyContinue
}

Describe "Logging Module - Initialize-Logging" {
    Context "Initialization with Default Path" {
        It "Creates log file in temp directory" {
            Initialize-Logging
            $logPath = Get-LogPath
            
            $logPath | Should -Not -BeNullOrEmpty
            Test-Path $logPath | Should -Be $true
            
            Close-Logging
        }
        
        It "Creates log file with proper format" {
            Initialize-Logging
            $logPath = Get-LogPath
            
            $logPath | Should -Match "Windows-Optimization_\d{8}_\d{6}\.log"
            
            Close-Logging
        }
    }
    
    Context "Initialization with Custom Path" {
        It "Creates log file at specified location" {
            $testPath = Join-Path $TestDrive "custom-log.txt"
            Initialize-Logging -LogPath $testPath
            
            $logPath = Get-LogPath
            $logPath | Should -Be $testPath
            Test-Path $testPath | Should -Be $true
            
            Close-Logging
        }
        
        It "Creates directory if it doesn't exist" {
            $testDir = Join-Path $TestDrive "logs\custom\path"
            $testPath = Join-Path $testDir "test.log"
            
            Initialize-Logging -LogPath $testPath
            
            Test-Path $testDir | Should -Be $true
            Test-Path $testPath | Should -Be $true
            
            Close-Logging
        }
    }
}

Describe "Logging Module - Write-LogMessage" {
    BeforeEach {
        Initialize-Logging -LogPath (Join-Path $TestDrive "test.log") -Append $false
    }
    
    AfterEach {
        Close-Logging
    }
    
    Context "Message Content" {
        It "Writes timestamp with message" {
            Write-LogMessage -Level "INFO" -Message "Test message" -ShowConsole $false
            
            $content = Get-Content (Join-Path $TestDrive "test.log")
            $content | Should -Match "\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}\]"
            $content | Should -Match "Test message"
        }
        
        It "Includes log level in message" {
            Write-LogMessage -Level "ERROR" -Message "Error occurred" -ShowConsole $false
            
            $content = Get-Content (Join-Path $TestDrive "test.log")
            $content | Should -Match "\[ERROR\]"
        }
    }
    
    Context "Log Levels" {
        It "Accepts valid log levels" {
            $validLevels = @('DEBUG', 'INFO', 'WARN', 'ERROR', 'CRITICAL')
            
            foreach ($level in $validLevels) {
                { Write-LogMessage -Level $level -Message "Test" -ShowConsole $false } | Should -Not -Throw
            }
        }
        
        It "Rejects invalid log levels" {
            { Write-LogMessage -Level "INVALID" -Message "Test" -ShowConsole $false } | Should -Throw
        }
    }
}

Describe "Logging Module - Helper Functions" {
    BeforeEach {
        Initialize-Logging -LogPath (Join-Path $TestDrive "test.log") -Append $false
    }
    
    AfterEach {
        Close-Logging
    }
    
    Context "Level-Specific Logging Functions" {
        It "Write-LogDebug writes DEBUG level" {
            Write-LogDebug "Debug message"
            
            $content = Get-Content (Join-Path $TestDrive "test.log")
            $content | Should -Match "\[DEBUG\].*Debug message"
        }
        
        It "Write-LogInfo writes INFO level" {
            Write-LogInfo "Info message"
            
            $content = Get-Content (Join-Path $TestDrive "test.log")
            $content | Should -Match "\[INFO\].*Info message"
        }
        
        It "Write-LogWarning writes WARN level" {
            Write-LogWarning "Warning message"
            
            $content = Get-Content (Join-Path $TestDrive "test.log")
            $content | Should -Match "\[WARN\].*Warning message"
        }
        
        It "Write-LogError writes ERROR level" {
            Write-LogError "Error message"
            
            $content = Get-Content (Join-Path $TestDrive "test.log")
            $content | Should -Match "\[ERROR\].*Error message"
        }
        
        It "Write-LogCritical writes CRITICAL level" {
            Write-LogCritical "Critical message"
            
            $content = Get-Content (Join-Path $TestDrive "test.log")
            $content | Should -Match "\[CRITICAL\].*Critical message"
        }
    }
}

Describe "Logging Module - Get-LogPath" {
    It "Returns current log path" {
        $testPath = Join-Path $TestDrive "custom.log"
        Initialize-Logging -LogPath $testPath
        
        Get-LogPath | Should -Be $testPath
        
        Close-Logging
    }
    
    It "Returns null if logging not initialized" {
        Get-LogPath | Should -BeNullOrEmpty
    }
}

Describe "Logging Module - Close-Logging" {
    It "Closes log file handle" {
        Initialize-Logging -LogPath (Join-Path $TestDrive "test.log")
        Close-Logging
        
        # Verify file can be read (not locked)
        { Get-Content (Join-Path $TestDrive "test.log") | Out-Null } | Should -Not -Throw
    }
}

# Unit Tests for Validation Module
# Tests/Unit-Tests/Validation.Tests.ps1

BeforeAll {
    $ModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) "..\Scripts\Utils\Validation.ps1"
    $LoggingPath = Join-Path (Split-Path -Parent $PSScriptRoot) "..\Scripts\Utils\Logging.ps1"
    
    Import-Module $LoggingPath -Force
    Import-Module $ModulePath -Force
}

AfterAll {
    Remove-Module Validation -ErrorAction SilentlyContinue
    Remove-Module Logging -ErrorAction SilentlyContinue
}

Describe "Validation Module - Test-AdminPrivileges" {
    BeforeEach {
        Initialize-Logging -LogPath (Join-Path $TestDrive "test.log") -Append $false
    }
    
    AfterEach {
        Close-Logging
    }
    
    Context "Admin Check" {
        It "Returns boolean result" {
            $result = Test-AdminPrivileges
            $result | Should -BeOfType [bool]
        }
    }
}

Describe "Validation Module - Get-WindowsVersionInfo" {
    BeforeEach {
        Initialize-Logging -LogPath (Join-Path $TestDrive "test.log") -Append $false
    }
    
    AfterEach {
        Close-Logging
    }
    
    Context "Version Information" {
        It "Returns hashtable with OS info" {
            $info = Get-WindowsVersionInfo
            $info | Should -BeOfType [hashtable]
        }
        
        It "Contains required properties" {
            $info = Get-WindowsVersionInfo
            $info.ContainsKey('OSName') | Should -Be $true
            $info.ContainsKey('OSVersion') | Should -Be $true
            $info.ContainsKey('OSBuild') | Should -Be $true
            $info.ContainsKey('Architecture') | Should -Be $true
        }
        
        It "Detects Windows 10 or 11" {
            $info = Get-WindowsVersionInfo
            ($info['IsWindows10'] -or $info['IsWindows11']) | Should -Be $true
        }
    }
}

Describe "Validation Module - Test-WindowsVersionCompatibility" {
    BeforeEach {
        Initialize-Logging -LogPath (Join-Path $TestDrive "test.log") -Append $false
    }
    
    AfterEach {
        Close-Logging
    }
    
    Context "Compatibility Check" {
        It "Returns boolean result" {
            $result = Test-WindowsVersionCompatibility
            $result | Should -BeOfType [bool]
        }
        
        It "Current system should be compatible" {
            $result = Test-WindowsVersionCompatibility
            $result | Should -Be $true
        }
    }
}

Describe "Validation Module - Test-DiskSpace" {
    BeforeEach {
        Initialize-Logging -LogPath (Join-Path $TestDrive "test.log") -Append $false
    }
    
    AfterEach {
        Close-Logging
    }
    
    Context "Disk Space Check" {
        It "Returns boolean result" {
            $result = Test-DiskSpace
            $result | Should -BeOfType [bool]
        }
        
        It "Accepts custom minimum requirement" {
            $result = Test-DiskSpace -MinimumMBRequired 100
            $result | Should -BeOfType [bool]
        }
    }
}

Describe "Validation Module - Get-RAMInfo" {
    BeforeEach {
        Initialize-Logging -LogPath (Join-Path $TestDrive "test.log") -Append $false
    }
    
    AfterEach {
        Close-Logging
    }
    
    Context "RAM Information" {
        It "Returns hashtable with RAM info" {
            $info = Get-RAMInfo
            $info | Should -BeOfType [hashtable]
        }
        
        It "Contains required properties" {
            $info = Get-RAMInfo
            $info.ContainsKey('TotalGB') | Should -Be $true
            $info.ContainsKey('TotalBytes') | Should -Be $true
            $info.ContainsKey('IsLowEndPC') | Should -Be $true
        }
        
        It "Reports RAM in GB as decimal" {
            $info = Get-RAMInfo
            $info['TotalGB'] | Should -BeGreaterThan 0
        }
    }
}

Describe "Validation Module - Test-PreFlightValidation" {
    BeforeEach {
        Initialize-Logging -LogPath (Join-Path $TestDrive "test.log") -Append $false
    }
    
    AfterEach {
        Close-Logging
    }
    
    Context "Full Validation" {
        It "Returns hashtable with validation results" {
            $results = Test-PreFlightValidation -SkipAdminCheck $true -SkipVersionCheck $true -SkipDiskSpaceCheck $true
            $results | Should -BeOfType [hashtable]
        }
        
        It "Contains required keys" {
            $results = Test-PreFlightValidation -SkipAdminCheck $true -SkipVersionCheck $true -SkipDiskSpaceCheck $true
            $results.ContainsKey('AllTestsPassed') | Should -Be $true
            $results.ContainsKey('Details') | Should -Be $true
        }
        
        It "Allows skipping individual checks" {
            $results = Test-PreFlightValidation -SkipAdminCheck $true -SkipVersionCheck $true -SkipDiskSpaceCheck $true
            $results['AllTestsPassed'] | Should -Be $true
        }
    }
}

Describe "Validation Module - Generate-SystemCompatibilityReport" {
    BeforeEach {
        Initialize-Logging -LogPath (Join-Path $TestDrive "test.log") -Append $false
    }
    
    AfterEach {
        Close-Logging
    }
    
    Context "Report Generation" {
        It "Returns hashtable with system info" {
            $report = Generate-SystemCompatibilityReport
            $report | Should -BeOfType [hashtable]
        }
        
        It "Contains required sections" {
            $report = Generate-SystemCompatibilityReport
            $report.ContainsKey('Timestamp') | Should -Be $true
            $report.ContainsKey('WindowsInfo') | Should -Be $true
            $report.ContainsKey('RAMInfo') | Should -Be $true
        }
    }
}

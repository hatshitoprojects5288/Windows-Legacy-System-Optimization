# Integration Tests for Windows Optimization Scripts
# Tests/Integration-Tests/Integration.Tests.ps1
#
# This file provides end-to-end testing for the complete optimization workflow.
# Tests are designed to run on actual Windows systems with proper isolation.

BeforeAll {
    $ScriptsPath = Join-Path (Split-Path -Parent $PSScriptRoot) "..\Scripts"
    
    # Import all utility modules
    Import-Module (Join-Path $ScriptsPath "Utils\Logging.ps1") -Force
    Import-Module (Join-Path $ScriptsPath "Utils\Validation.ps1") -Force
    Import-Module (Join-Path $ScriptsPath "Utils\Registry-Operations.ps1") -Force
    Import-Module (Join-Path $ScriptsPath "Utils\Backup-Management.ps1") -Force
}

AfterAll {
    Remove-Module Logging -ErrorAction SilentlyContinue
    Remove-Module Validation -ErrorAction SilentlyContinue
    Remove-Module Registry-Operations -ErrorAction SilentlyContinue
    Remove-Module Backup-Management -ErrorAction SilentlyContinue
}

Describe "Integration Tests - Logging + Validation" {
    Context "System Initialization" {
        It "Initializes logging and validation modules" {
            Initialize-Logging -LogPath (Join-Path $TestDrive "integration.log") -Append $false
            
            $logPath = Get-LogPath
            $logPath | Should -Not -BeNullOrEmpty
            
            Close-Logging
        }
        
        It "Performs pre-flight validation without errors" {
            Initialize-Logging -LogPath (Join-Path $TestDrive "integration.log") -Append $false
            
            $results = Test-PreFlightValidation -SkipAdminCheck $true -SkipDiskSpaceCheck $false
            $results | Should -Not -BeNullOrEmpty
            
            Close-Logging
        }
    }
}

Describe "Integration Tests - Registry Backup and Restore" {
    Context "Registry Operations Workflow" {
        It "Creates backup and restores successfully" {
            Initialize-Logging -LogPath (Join-Path $TestDrive "integration.log") -Append $false
            Initialize-BackupManagement -BackupPath (Join-Path $TestDrive "backups")
            
            # Create snapshot
            $paths = @("HKCU:\Software\Microsoft")
            $result = New-BackupSnapshot -SnapshotName "TestSnapshot" -RegistryPaths $paths
            $result | Should -Be $true
            
            # Verify snapshot exists
            $snapshot = Get-BackupSnapshot -SnapshotName "TestSnapshot"
            $snapshot | Should -Not -BeNullOrEmpty
            
            Close-Logging
        }
    }
}

Describe "Integration Tests - Complete Optimization Flow" {
    BeforeEach {
        Initialize-Logging -LogPath (Join-Path $TestDrive "integration.log") -Append $false
        Initialize-BackupManagement -BackupPath (Join-Path $TestDrive "backups")
    }
    
    AfterEach {
        Close-Logging
    }
    
    Context "Optimization Workflow" {
        It "Completes system validation before optimization" {
            # Pre-flight checks
            $validation = Test-PreFlightValidation -SkipAdminCheck $true
            $validation['AllTestsPassed'] | Should -Be $true -ErrorAction SilentlyContinue
            
            Write-LogInfo "Pre-flight validation passed"
        }
        
        It "Creates system snapshot before modifications" {
            $paths = @("HKCU:\Software\Microsoft\Windows")
            $result = New-BackupSnapshot -SnapshotName "PreOptimization" -RegistryPaths $paths
            
            $result | Should -Be $true
            
            $snapshot = Get-BackupSnapshot -SnapshotName "PreOptimization"
            $snapshot['SuccessCount'] | Should -BeGreaterThan 0
        }
    }
}

# ============================================================================
# NOTE: Integration tests require execution on actual Windows systems
# Additional tests should be added here as scripts are developed:
# - Debloat-Windows.ps1 integration
# - Registry tweaks application integration
# - Telemetry removal verification
# - DPC latency measurement verification
# ============================================================================

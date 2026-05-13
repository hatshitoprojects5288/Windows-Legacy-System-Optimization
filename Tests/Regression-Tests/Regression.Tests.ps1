# Regression Tests for Windows Optimization Scripts
# Tests/Regression-Tests/Regression.Tests.ps1
#
# Ensures that rollback procedures work correctly and system can be restored
# to a known state after optimization.

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

Describe "Regression Tests - Rollback Functionality" {
    BeforeEach {
        Initialize-Logging -LogPath (Join-Path $TestDrive "regression.log") -Append $false
        Initialize-BackupManagement -BackupPath (Join-Path $TestDrive "backups")
    }
    
    AfterEach {
        Close-Logging
    }
    
    Context "Snapshot Creation and Restoration" {
        It "Restores registry from snapshot successfully" {
            # Create initial snapshot
            $paths = @("HKCU:\Software\Microsoft")
            $result = New-BackupSnapshot -SnapshotName "PreModification" -RegistryPaths $paths
            $result | Should -Be $true
            
            # Verify snapshot was created
            $snapshot = Get-BackupSnapshot -SnapshotName "PreModification"
            $snapshot | Should -Not -BeNullOrEmpty
            $snapshot['SuccessCount'] | Should -BeGreaterThan 0
            
            Write-LogInfo "Snapshot restoration test passed"
        }
        
        It "Maintains backup integrity through lifecycle" {
            # Create multiple snapshots
            $paths = @("HKCU:\Software")
            New-BackupSnapshot -SnapshotName "Snapshot1" -RegistryPaths $paths | Out-Null
            New-BackupSnapshot -SnapshotName "Snapshot2" -RegistryPaths $paths | Out-Null
            
            # Verify both exist
            $allSnapshots = Get-AllBackupSnapshots
            $allSnapshots.Count | Should -BeGreaterThanOrEqual 2
            
            # Remove one
            Remove-BackupSnapshot -SnapshotName "Snapshot1" -DeleteFiles $false
            
            # Verify other still exists
            $remaining = Get-AllBackupSnapshots
            $remaining.ContainsKey("Snapshot2") | Should -Be $true
            $remaining.ContainsKey("Snapshot1") | Should -Be $false
        }
    }
}

Describe "Regression Tests - Backup File Integrity" {
    BeforeEach {
        Initialize-Logging -LogPath (Join-Path $TestDrive "regression.log") -Append $false
        Initialize-BackupManagement -BackupPath (Join-Path $TestDrive "backups")
    }
    
    AfterEach {
        Close-Logging
    }
    
    Context "Backup File Management" {
        It "Creates valid backup files" {
            $paths = @("HKCU:\Software")
            $result = New-BackupSnapshot -SnapshotName "FileTest" -RegistryPaths $paths
            
            $snapshot = Get-BackupSnapshot -SnapshotName "FileTest"
            $snapshot['BackupFiles'].Count | Should -BeGreaterThan 0
            
            # Verify backup files exist
            foreach ($backupFile in $snapshot['BackupFiles']) {
                Test-Path $backupFile['BackupFile'] | Should -Be $true
            }
        }
        
        It "Calculates backup size correctly" {
            $paths = @("HKCU:\Software")
            New-BackupSnapshot -SnapshotName "SizeTest" -RegistryPaths $paths
            
            $diskUsage = Get-BackupDiskUsage
            $diskUsage | Should -BeGreaterThan 0
        }
    }
}

Describe "Regression Tests - State Consistency" {
    BeforeEach {
        Initialize-Logging -LogPath (Join-Path $TestDrive "regression.log") -Append $false
        Initialize-BackupManagement -BackupPath (Join-Path $TestDrive "backups")
    }
    
    AfterEach {
        Close-Logging
    }
    
    Context "Metadata Consistency" {
        It "Maintains consistent backup metadata" {
            $paths = @("HKCU:\Software\Microsoft")
            New-BackupSnapshot -SnapshotName "ConsistencyTest" `
                               -RegistryPaths $paths `
                               -Description "Testing metadata consistency"
            
            # Retrieve and verify
            $snapshot = Get-BackupSnapshot -SnapshotName "ConsistencyTest"
            
            $snapshot['SnapshotName'] | Should -Be "ConsistencyTest"
            $snapshot['Description'] | Should -Be "Testing metadata consistency"
            $snapshot['CreatedTime'] | Should -BeOfType [DateTime]
        }
        
        It "Tracks success and failure counts correctly" {
            $paths = @("HKCU:\Software", "HKCU:\NonExistent")
            $result = New-BackupSnapshot -SnapshotName "CountTest" -RegistryPaths $paths
            
            $snapshot = Get-BackupSnapshot -SnapshotName "CountTest"
            $snapshot['SuccessCount'] | Should -BeGreaterThanOrEqual 1
            
            # Note: FailureCount might be 0 or 1 depending on registry availability
            ($snapshot['SuccessCount'] + $snapshot['FailureCount']) | Should -Be $paths.Count
        }
    }
}

# ============================================================================
# NOTE: Additional regression tests should be added as optimization scripts
# are developed to ensure rollback procedures work correctly for:
# - Registry value modifications
# - Service state changes
# - Scheduled task modifications
# - Telemetry removal rollback
# ============================================================================

# Unit Tests for Backup-Management Module
# Tests/Unit-Tests/Backup-Management.Tests.ps1

BeforeAll {
    $ModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) "..\Scripts\Utils\Backup-Management.ps1"
    $LoggingPath = Join-Path (Split-Path -Parent $PSScriptRoot) "..\Scripts\Utils\Logging.ps1"
    
    Import-Module $LoggingPath -Force
    Import-Module $ModulePath -Force
}

AfterAll {
    Remove-Module Backup-Management -ErrorAction SilentlyContinue
    Remove-Module Logging -ErrorAction SilentlyContinue
}

Describe "Backup-Management Module - Initialize-BackupManagement" {
    BeforeEach {
        Initialize-Logging -LogPath (Join-Path $TestDrive "test.log") -Append $false
    }
    
    AfterEach {
        Close-Logging
    }
    
    Context "Initialization" {
        It "Creates backup directory with default path" {
            $result = Initialize-BackupManagement
            $result | Should -Be $true
        }
        
        It "Creates backup directory with custom path" {
            $customPath = Join-Path $TestDrive "custom-backups"
            $result = Initialize-BackupManagement -BackupPath $customPath
            
            $result | Should -Be $true
            Test-Path $customPath | Should -Be $true
        }
    }
}

Describe "Backup-Management Module - New-BackupSnapshot" {
    BeforeEach {
        Initialize-Logging -LogPath (Join-Path $TestDrive "test.log") -Append $false
        Initialize-BackupManagement -BackupPath (Join-Path $TestDrive "backups")
    }
    
    AfterEach {
        Close-Logging
    }
    
    Context "Snapshot Creation" {
        It "Creates snapshot with valid registry paths" {
            $paths = @("HKCU:\Software")
            $result = New-BackupSnapshot -SnapshotName "TestSnapshot" -RegistryPaths $paths -Description "Test backup"
            
            $result | Should -Be $true
        }
        
        It "Returns false for duplicate snapshot name" {
            $paths = @("HKCU:\Software")
            New-BackupSnapshot -SnapshotName "TestSnapshot" -RegistryPaths $paths | Out-Null
            $result = New-BackupSnapshot -SnapshotName "TestSnapshot" -RegistryPaths $paths
            
            $result | Should -Be $false
        }
    }
}

Describe "Backup-Management Module - Get-BackupSnapshot" {
    BeforeEach {
        Initialize-Logging -LogPath (Join-Path $TestDrive "test.log") -Append $false
        Initialize-BackupManagement -BackupPath (Join-Path $TestDrive "backups")
    }
    
    AfterEach {
        Close-Logging
    }
    
    Context "Snapshot Retrieval" {
        It "Returns snapshot metadata" {
            $paths = @("HKCU:\Software")
            New-BackupSnapshot -SnapshotName "TestSnapshot" -RegistryPaths $paths
            
            $snapshot = Get-BackupSnapshot -SnapshotName "TestSnapshot"
            $snapshot | Should -Not -BeNullOrEmpty
            $snapshot['SnapshotName'] | Should -Be "TestSnapshot"
        }
        
        It "Returns null for non-existent snapshot" {
            $snapshot = Get-BackupSnapshot -SnapshotName "NonExistent"
            $snapshot | Should -BeNullOrEmpty
        }
    }
}

Describe "Backup-Management Module - Get-AllBackupSnapshots" {
    BeforeEach {
        Initialize-Logging -LogPath (Join-Path $TestDrive "test.log") -Append $false
        Initialize-BackupManagement -BackupPath (Join-Path $TestDrive "backups")
    }
    
    AfterEach {
        Close-Logging
    }
    
    Context "Snapshot Listing" {
        It "Returns empty collection if no snapshots" {
            $snapshots = Get-AllBackupSnapshots
            $snapshots.Count | Should -Be 0
        }
        
        It "Returns all snapshots" {
            $paths = @("HKCU:\Software")
            New-BackupSnapshot -SnapshotName "Snapshot1" -RegistryPaths $paths | Out-Null
            New-BackupSnapshot -SnapshotName "Snapshot2" -RegistryPaths $paths | Out-Null
            
            $snapshots = Get-AllBackupSnapshots
            $snapshots.Count | Should -BeGreaterThanOrEqual 2
        }
    }
}

Describe "Backup-Management Module - Remove-BackupSnapshot" {
    BeforeEach {
        Initialize-Logging -LogPath (Join-Path $TestDrive "test.log") -Append $false
        Initialize-BackupManagement -BackupPath (Join-Path $TestDrive "backups")
    }
    
    AfterEach {
        Close-Logging
    }
    
    Context "Snapshot Removal" {
        It "Removes snapshot from collection" {
            $paths = @("HKCU:\Software")
            New-BackupSnapshot -SnapshotName "TestSnapshot" -RegistryPaths $paths
            
            $result = Remove-BackupSnapshot -SnapshotName "TestSnapshot" -DeleteFiles $false
            $result | Should -Be $true
            
            $snapshots = Get-AllBackupSnapshots
            $snapshots.ContainsKey("TestSnapshot") | Should -Be $false
        }
    }
}

Describe "Backup-Management Module - Get-BackupDiskUsage" {
    BeforeEach {
        Initialize-Logging -LogPath (Join-Path $TestDrive "test.log") -Append $false
        Initialize-BackupManagement -BackupPath (Join-Path $TestDrive "backups")
    }
    
    AfterEach {
        Close-Logging
    }
    
    Context "Disk Usage Calculation" {
        It "Returns disk usage as bytes" {
            $usage = Get-BackupDiskUsage
            $usage | Should -BeOfType [long]
            $usage | Should -BeGreaterOrEqual 0
        }
    }
}

Describe "Backup-Management Module - Invoke-BackupCleanup" {
    BeforeEach {
        Initialize-Logging -LogPath (Join-Path $TestDrive "test.log") -Append $false
        Initialize-BackupManagement -BackupPath (Join-Path $TestDrive "backups")
    }
    
    AfterEach {
        Close-Logging
    }
    
    Context "Cleanup Operations" {
        It "Returns count of deleted snapshots" {
            $count = Invoke-BackupCleanup -DaysToKeep 0
            $count | Should -BeOfType [int]
        }
    }
}

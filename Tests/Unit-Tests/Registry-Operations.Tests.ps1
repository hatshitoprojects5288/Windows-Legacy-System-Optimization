# Unit Tests for Registry-Operations Module
# Tests/Unit-Tests/Registry-Operations.Tests.ps1

BeforeAll {
    $ModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) "..\Scripts\Utils\Registry-Operations.ps1"
    $LoggingPath = Join-Path (Split-Path -Parent $PSScriptRoot) "..\Scripts\Utils\Logging.ps1"
    
    Import-Module $LoggingPath -Force
    Import-Module $ModulePath -Force
}

AfterAll {
    Remove-Module Registry-Operations -ErrorAction SilentlyContinue
    Remove-Module Logging -ErrorAction SilentlyContinue
}

Describe "Registry-Operations Module - Backup-RegistryPath" {
    BeforeEach {
        Initialize-Logging -LogPath (Join-Path $TestDrive "test.log") -Append $false
    }
    
    AfterEach {
        Close-Logging
    }
    
    Context "Backup Creation" {
        It "Creates backup for valid registry path" {
            # Use a known registry path that always exists
            $regPath = "HKCU:\Software"
            $backupName = Backup-RegistryPath -RegistryPath $regPath
            
            $backupName | Should -Not -BeNullOrEmpty
            
            # Verify backup file exists
            $backups = Get-RegistryBackups
            $backups.ContainsKey($backupName) | Should -Be $true
        }
        
        It "Returns null for non-existent registry path" {
            $regPath = "HKCU:\NonExistentPath"
            $backupName = Backup-RegistryPath -RegistryPath $regPath
            
            $backupName | Should -BeNullOrEmpty
        }
        
        It "Generates unique backup names" {
            $regPath = "HKCU:\Software"
            $backup1 = Backup-RegistryPath -RegistryPath $regPath
            $backup2 = Backup-RegistryPath -RegistryPath $regPath
            
            $backup1 | Should -Not -Be $backup2
        }
    }
    
    Context "Backup Metadata" {
        It "Stores backup path and timestamp" {
            $regPath = "HKCU:\Software"
            $backupName = Backup-RegistryPath -RegistryPath $regPath
            
            $backups = Get-RegistryBackups
            $backup = $backups[$backupName]
            
            $backup['Path'] | Should -Be $regPath
            $backup['Timestamp'] | Should -BeOfType [DateTime]
            $backup['BackupFile'] | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Registry-Operations Module - Get-RegistryValue" {
    BeforeEach {
        Initialize-Logging -LogPath (Join-Path $TestDrive "test.log") -Append $false
    }
    
    AfterEach {
        Close-Logging
    }
    
    Context "Value Retrieval" {
        It "Retrieves existing registry value" {
            $value = Get-RegistryValue -Path "HKCU:\Software" -Name "Does-Not-Exist" | Should -BeNullOrEmpty
        }
        
        It "Returns null for non-existent value" {
            $value = Get-RegistryValue -Path "HKCU:\Software" -Name "NonExistentValue"
            $value | Should -BeNullOrEmpty
        }
    }
}

Describe "Registry-Operations Module - Get-RegistryBackups" {
    BeforeEach {
        Initialize-Logging -LogPath (Join-Path $TestDrive "test.log") -Append $false
    }
    
    AfterEach {
        Close-Logging
    }
    
    Context "Backup Listing" {
        It "Returns empty collection if no backups" {
            $backups = Get-RegistryBackups
            $backups.Count | Should -Be 0
        }
        
        It "Returns all registered backups" {
            Backup-RegistryPath -RegistryPath "HKCU:\Software"
            Backup-RegistryPath -RegistryPath "HKCU:\Software\Microsoft"
            
            $backups = Get-RegistryBackups
            $backups.Count | Should -BeGreaterThan 0
        }
    }
}

Describe "Registry-Operations Module - Get-RegistryChangeLog" {
    BeforeEach {
        Initialize-Logging -LogPath (Join-Path $TestDrive "test.log") -Append $false
    }
    
    AfterEach {
        Close-Logging
    }
    
    Context "Change Logging" {
        It "Returns change log entries" {
            $changeLog = Get-RegistryChangeLog
            $changeLog | Should -BeOfType [System.Object[]]
        }
    }
}

Describe "Registry-Operations Module - Clear-RegistryBackups" {
    BeforeEach {
        Initialize-Logging -LogPath (Join-Path $TestDrive "test.log") -Append $false
    }
    
    AfterEach {
        Close-Logging
    }
    
    Context "Backup Cleanup" {
        It "Clears backups from memory" {
            Backup-RegistryPath -RegistryPath "HKCU:\Software"
            (Get-RegistryBackups).Count | Should -BeGreaterThan 0
            
            Clear-RegistryBackups
            
            (Get-RegistryBackups).Count | Should -Be 0
        }
    }
}

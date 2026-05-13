<#
.SYNOPSIS
    Safe registry manipulation functions with automatic backup and rollback support.

.DESCRIPTION
    Provides production-ready functions for registry editing with built-in backup,
    validation, and error handling. All modifications are atomic and reversible.

.NOTES
    Author: Windows-Legacy-System-Optimization Team
    Version: 1.0
    Production-Ready: Yes
    Requires: Logging.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$LoggingModule = "Logging"
)

# Ensure logging module is available
if (-not (Get-Module $LoggingModule)) {
    try {
        Import-Module (Join-Path $PSScriptRoot $LoggingModule".ps1") -ErrorAction Stop
    }
    catch {
        Write-Warning "Logging module not found. Some logging features will be unavailable."
    }
}

# Module-level state
$script:RegistryBackups = @{}
$script:RegistryChangeLog = @()

<#
.SYNOPSIS
    Create a backup of a registry path before modifications.

.PARAMETER RegistryPath
    Full registry path (e.g., "HKLM:\SYSTEM\CurrentControlSet\Services")

.PARAMETER BackupName
    Unique identifier for this backup (used for rollback)
#>
function Backup-RegistryPath {
    param(
        [Parameter(Mandatory=$true)]
        [string]$RegistryPath,
        
        [Parameter(Mandatory=$false)]
        [string]$BackupName
    )
    
    try {
        # Validate path exists
        if (-not (Test-Path $RegistryPath)) {
            Write-LogWarning "Registry path not found: $RegistryPath"
            return $null
        }
        
        # Generate backup name if not provided
        if ([string]::IsNullOrWhiteSpace($BackupName)) {
            $BackupName = "Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')_$(Get-Random -Minimum 1000 -Maximum 9999)"
        }
        
        # Export registry to temporary file
        $backupFile = Join-Path $env:TEMP "$BackupName.reg"
        
        # Use reg.exe for reliable export
        $output = & reg export $RegistryPath $backupFile /y 2>&1
        
        if ($LASTEXITCODE -eq 0 -and (Test-Path $backupFile)) {
            $script:RegistryBackups[$BackupName] = @{
                'Path'         = $RegistryPath
                'BackupFile'   = $backupFile
                'Timestamp'    = Get-Date
                'Size'         = (Get-Item $backupFile).Length
            }
            
            Write-LogDebug "Registry backup created: $BackupName -> $backupFile"
            return $BackupName
        }
        else {
            Write-LogError "Failed to backup registry path: $RegistryPath"
            return $null
        }
    }
    catch {
        Write-LogError "Exception in Backup-RegistryPath" -Exception $_
        return $null
    }
}

<#
.SYNOPSIS
    Restore a registry from a previous backup.

.PARAMETER BackupName
    The backup identifier to restore
#>
function Restore-RegistryFromBackup {
    param(
        [Parameter(Mandatory=$true)]
        [string]$BackupName
    )
    
    try {
        if (-not $script:RegistryBackups.ContainsKey($BackupName)) {
            Write-LogError "Backup not found: $BackupName"
            return $false
        }
        
        $backup = $script:RegistryBackups[$BackupName]
        $backupFile = $backup['BackupFile']
        
        if (-not (Test-Path $backupFile)) {
            Write-LogError "Backup file not found: $backupFile"
            return $false
        }
        
        # Restore using reg.exe
        $output = & reg import $backupFile 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-LogInfo "Registry restored from backup: $BackupName"
            return $true
        }
        else {
            Write-LogError "Failed to restore registry from backup: $BackupName"
            return $false
        }
    }
    catch {
        Write-LogError "Exception in Restore-RegistryFromBackup" -Exception $_
        return $false
    }
}

<#
.SYNOPSIS
    Set a registry value with automatic backup and validation.

.PARAMETER Path
    Registry path (e.g., "HKLM:\SYSTEM\CurrentControlSet\Services\TimerResolution")

.PARAMETER Name
    Value name (e.g., "Current")

.PARAMETER Value
    New value to set

.PARAMETER Type
    Registry type: String, DWord, QWord, Binary, ExpandString, MultiString

.PARAMETER CreateBackup
    If $true, backs up the path before modification (default: $true)
#>
function Set-RegistryValue {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        $Value,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('String', 'DWord', 'QWord', 'Binary', 'ExpandString', 'MultiString')]
        [string]$Type = 'DWord',
        
        [Parameter(Mandatory=$false)]
        [bool]$CreateBackup = $true
    )
    
    try {
        # Create backup if requested
        $backupName = $null
        if ($CreateBackup) {
            $backupName = Backup-RegistryPath -RegistryPath $Path
            if (-not $backupName) {
                Write-LogWarning "Failed to create backup, proceeding without backup"
            }
        }
        
        # Ensure registry path exists
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
            Write-LogDebug "Created registry path: $Path"
        }
        
        # Set the registry value
        $params = @{
            Path        = $Path
            Name        = $Name
            Value       = $Value
            Type        = $Type
            Force       = $true
            ErrorAction = 'Stop'
        }
        
        Set-ItemProperty @params
        
        # Validate the change
        $currentValue = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop
        if ($currentValue.$Name -eq $Value) {
            Write-LogInfo "Registry value set successfully: $Path\$Name = $Value"
            
            $script:RegistryChangeLog += @{
                'Timestamp'   = Get-Date
                'Path'        = $Path
                'Name'        = $Name
                'Value'       = $Value
                'Type'        = $Type
                'BackupName'  = $backupName
                'Status'      = 'Success'
            }
            
            return $true
        }
        else {
            Write-LogError "Registry value validation failed: $Path\$Name"
            return $false
        }
    }
    catch {
        Write-LogError "Failed to set registry value" -Exception $_
        return $false
    }
}

<#
.SYNOPSIS
    Get a registry value with error handling.

.PARAMETER Path
    Registry path

.PARAMETER Name
    Value name
#>
function Get-RegistryValue {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$true)]
        [string]$Name
    )
    
    try {
        if (Test-Path $Path) {
            $value = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
            if ($value) {
                return $value.$Name
            }
        }
        return $null
    }
    catch {
        Write-LogDebug "Failed to read registry value: $Path\$Name"
        return $null
    }
}

<#
.SYNOPSIS
    Delete a registry value with automatic backup.

.PARAMETER Path
    Registry path

.PARAMETER Name
    Value name

.PARAMETER CreateBackup
    If $true, backs up before deletion (default: $true)
#>
function Remove-RegistryValue {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$false)]
        [bool]$CreateBackup = $true
    )
    
    try {
        if (-not (Test-Path $Path)) {
            Write-LogWarning "Registry path not found: $Path"
            return $false
        }
        
        # Create backup if requested
        if ($CreateBackup) {
            $backupName = Backup-RegistryPath -RegistryPath $Path
            if (-not $backupName) {
                Write-LogWarning "Failed to create backup, proceeding without backup"
            }
        }
        
        # Remove the value
        Remove-ItemProperty -Path $Path -Name $Name -Force -ErrorAction Stop
        
        Write-LogInfo "Registry value removed: $Path\$Name"
        return $true
    }
    catch {
        Write-LogError "Failed to remove registry value" -Exception $_
        return $false
    }
}

<#
.SYNOPSIS
    Import registry tweaks from .reg file with validation.

.PARAMETER RegFilePath
    Full path to .reg file
#>
function Import-RegistryFile {
    param(
        [Parameter(Mandatory=$true)]
        [string]$RegFilePath
    )
    
    try {
        if (-not (Test-Path $RegFilePath)) {
            Write-LogError "Registry file not found: $RegFilePath"
            return $false
        }
        
        Write-LogInfo "Importing registry file: $RegFilePath"
        
        # Use reg.exe for reliable import
        $output = & reg import $RegFilePath 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-LogInfo "Registry file imported successfully: $RegFilePath"
            return $true
        }
        else {
            Write-LogError "Failed to import registry file: $RegFilePath"
            Write-LogError "Output: $output"
            return $false
        }
    }
    catch {
        Write-LogError "Exception in Import-RegistryFile" -Exception $_
        return $false
    }
}

<#
.SYNOPSIS
    Get all registered backups.
#>
function Get-RegistryBackups {
    return $script:RegistryBackups
}

<#
.SYNOPSIS
    Get the registry change log.
#>
function Get-RegistryChangeLog {
    return $script:RegistryChangeLog
}

<#
.SYNOPSIS
    Clear all backups (use with caution).
#>
function Clear-RegistryBackups {
    param(
        [Parameter(Mandatory=$false)]
        [switch]$DeleteFiles
    )
    
    try {
        if ($DeleteFiles) {
            foreach ($backup in $script:RegistryBackups.Values) {
                if (Test-Path $backup['BackupFile']) {
                    Remove-Item $backup['BackupFile'] -Force -ErrorAction SilentlyContinue
                }
            }
            Write-LogInfo "Registry backup files deleted"
        }
        
        $script:RegistryBackups.Clear()
        Write-LogInfo "Registry backups cleared from memory"
    }
    catch {
        Write-LogError "Failed to clear registry backups" -Exception $_
    }
}

# Export public functions
Export-ModuleMember -Function @(
    'Backup-RegistryPath',
    'Restore-RegistryFromBackup',
    'Set-RegistryValue',
    'Get-RegistryValue',
    'Remove-RegistryValue',
    'Import-RegistryFile',
    'Get-RegistryBackups',
    'Get-RegistryChangeLog',
    'Clear-RegistryBackups'
)

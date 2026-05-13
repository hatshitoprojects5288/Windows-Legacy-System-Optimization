<#
.SYNOPSIS
    Registry backup and restore management for disaster recovery.

.DESCRIPTION
    Provides comprehensive backup management including snapshots, batch operations,
    and recovery procedures with metadata tracking.

.NOTES
    Author: Windows-Legacy-System-Optimization Team
    Version: 1.0
    Production-Ready: Yes
    Requires: Logging.ps1, Registry-Operations.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$LoggingModule = "Logging",
    
    [Parameter(Mandatory=$false)]
    [string]$RegistryModule = "Registry-Operations"
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

# Ensure registry module is available
if (-not (Get-Module $RegistryModule)) {
    try {
        Import-Module (Join-Path $PSScriptRoot $RegistryModule".ps1") -ErrorAction Stop
    }
    catch {
        Write-Warning "Registry-Operations module not found."
    }
}

# Module-level state
$script:BackupMetadata = @{}
$script:BackupDirectory = Join-Path $env:TEMP "Windows-Optimization-Backups"

<#
.SYNOPSIS
    Initialize backup directory and metadata store.

.PARAMETER BackupPath
    Custom backup directory path (default: $env:TEMP\Windows-Optimization-Backups)
#>
function Initialize-BackupManagement {
    param(
        [Parameter(Mandatory=$false)]
        [string]$BackupPath
    )
    
    try {
        if (-not [string]::IsNullOrWhiteSpace($BackupPath)) {
            $script:BackupDirectory = $BackupPath
        }
        
        if (-not (Test-Path $script:BackupDirectory)) {
            New-Item -ItemType Directory -Path $script:BackupDirectory -Force | Out-Null
        }
        
        Write-LogInfo "Backup management initialized: $script:BackupDirectory"
        return $true
    }
    catch {
        Write-LogError "Failed to initialize backup management" -Exception $_
        return $false
    }
}

<#
.SYNOPSIS
    Create a system backup snapshot at a specific point in time.

.PARAMETER SnapshotName
    Unique identifier for this snapshot

.PARAMETER RegistryPaths
    Array of registry paths to back up

.PARAMETER Description
    Human-readable description of why this snapshot was created
#>
function New-BackupSnapshot {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SnapshotName,
        
        [Parameter(Mandatory=$true)]
        [string[]]$RegistryPaths,
        
        [Parameter(Mandatory=$false)]
        [string]$Description = ""
    )
    
    try {
        # Validate snapshot name
        if ([string]::IsNullOrWhiteSpace($SnapshotName)) {
            Write-LogError "Snapshot name cannot be empty"
            return $false
        }
        
        # Prevent duplicate snapshot names
        if ($script:BackupMetadata.ContainsKey($SnapshotName)) {
            Write-LogError "Snapshot already exists: $SnapshotName"
            return $false
        }
        
        Write-LogInfo "Creating backup snapshot: $SnapshotName"
        
        $snapshotDir = Join-Path $script:BackupDirectory $SnapshotName
        if (-not (Test-Path $snapshotDir)) {
            New-Item -ItemType Directory -Path $snapshotDir -Force | Out-Null
        }
        
        $backupFiles = @()
        $successCount = 0
        $failCount = 0
        
        # Back up each registry path
        foreach ($path in $RegistryPaths) {
            try {
                $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
                $backupFileName = "$($path -replace '[\\\/:*?"<>|]', '_')_$timestamp.reg"
                $backupFilePath = Join-Path $snapshotDir $backupFileName
                
                # Use reg.exe for reliable export
                $output = & reg export $path $backupFilePath /y 2>&1
                
                if ($LASTEXITCODE -eq 0 -and (Test-Path $backupFilePath)) {
                    $backupFiles += @{
                        'SourcePath'    = $path
                        'BackupFile'    = $backupFilePath
                        'Size'          = (Get-Item $backupFilePath).Length
                        'ExportTime'    = Get-Date
                    }
                    $successCount++
                    Write-LogDebug "Backed up: $path"
                }
                else {
                    Write-LogWarning "Failed to backup: $path"
                    $failCount++
                }
            }
            catch {
                Write-LogWarning "Exception backing up $path : $_"
                $failCount++
            }
        }
        
        # Save snapshot metadata
        $script:BackupMetadata[$SnapshotName] = @{
            'SnapshotName'   = $SnapshotName
            'CreatedTime'    = Get-Date
            'Description'    = $Description
            'BackupDir'      = $snapshotDir
            'BackupFiles'    = $backupFiles
            'SuccessCount'   = $successCount
            'FailureCount'   = $failCount
            'TotalSize'      = ($backupFiles | Measure-Object -Property 'Size' -Sum).Sum
        }
        
        # Write metadata to file for persistence
        Save-BackupMetadata
        
        Write-LogInfo "Snapshot created: $SnapshotName ($successCount succeeded, $failCount failed)"
        return $true
    }
    catch {
        Write-LogError "Failed to create backup snapshot" -Exception $_
        return $false
    }
}

<#
.SYNOPSIS
    Restore system from a snapshot.

.PARAMETER SnapshotName
    Name of the snapshot to restore from
#>
function Restore-BackupSnapshot {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SnapshotName
    )
    
    try {
        if (-not $script:BackupMetadata.ContainsKey($SnapshotName)) {
            Write-LogError "Snapshot not found: $SnapshotName"
            return $false
        }
        
        $snapshot = $script:BackupMetadata[$SnapshotName]
        $backupFiles = $snapshot['BackupFiles']
        
        Write-LogInfo "Restoring from snapshot: $SnapshotName"
        
        $successCount = 0
        $failCount = 0
        
        foreach ($backupInfo in $backupFiles) {
            try {
                $backupFile = $backupInfo['BackupFile']
                
                if (-not (Test-Path $backupFile)) {
                    Write-LogWarning "Backup file not found: $backupFile"
                    $failCount++
                    continue
                }
                
                # Import registry backup
                $output = & reg import $backupFile 2>&1
                
                if ($LASTEXITCODE -eq 0) {
                    $successCount++
                    Write-LogDebug "Restored: $($backupInfo['SourcePath'])"
                }
                else {
                    Write-LogWarning "Failed to restore: $($backupInfo['SourcePath'])"
                    $failCount++
                }
            }
            catch {
                Write-LogWarning "Exception restoring backup: $_"
                $failCount++
            }
        }
        
        Write-LogInfo "Snapshot restore complete: $SnapshotName ($successCount succeeded, $failCount failed)"
        return ($failCount -eq 0)
    }
    catch {
        Write-LogError "Failed to restore snapshot" -Exception $_
        return $false
    }
}

<#
.SYNOPSIS
    Get metadata for a specific snapshot.

.PARAMETER SnapshotName
    Name of the snapshot
#>
function Get-BackupSnapshot {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SnapshotName
    )
    
    try {
        if ($script:BackupMetadata.ContainsKey($SnapshotName)) {
            return $script:BackupMetadata[$SnapshotName]
        }
        else {
            Write-LogWarning "Snapshot not found: $SnapshotName"
            return $null
        }
    }
    catch {
        Write-LogError "Failed to retrieve snapshot metadata" -Exception $_
        return $null
    }
}

<#
.SYNOPSIS
    List all available snapshots.
#>
function Get-AllBackupSnapshots {
    try {
        return $script:BackupMetadata
    }
    catch {
        Write-LogError "Failed to retrieve snapshots" -Exception $_
        return @{}
    }
}

<#
.SYNOPSIS
    Delete a snapshot and its backup files.

.PARAMETER SnapshotName
    Name of the snapshot to delete

.PARAMETER DeleteFiles
    If $true, also deletes the backup files (default: $true)
#>
function Remove-BackupSnapshot {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SnapshotName,
        
        [Parameter(Mandatory=$false)]
        [bool]$DeleteFiles = $true
    )
    
    try {
        if (-not $script:BackupMetadata.ContainsKey($SnapshotName)) {
            Write-LogWarning "Snapshot not found: $SnapshotName"
            return $false
        }
        
        $snapshot = $script:BackupMetadata[$SnapshotName]
        
        if ($DeleteFiles) {
            $snapshotDir = $snapshot['BackupDir']
            if (Test-Path $snapshotDir) {
                Remove-Item -Path $snapshotDir -Recurse -Force -ErrorAction SilentlyContinue
                Write-LogDebug "Deleted snapshot directory: $snapshotDir"
            }
        }
        
        $script:BackupMetadata.Remove($SnapshotName)
        Save-BackupMetadata
        
        Write-LogInfo "Snapshot removed: $SnapshotName"
        return $true
    }
    catch {
        Write-LogError "Failed to remove snapshot" -Exception $_
        return $false
    }
}

<#
.SYNOPSIS
    Save metadata to persistent storage.
#>
function Save-BackupMetadata {
    try {
        $metadataFile = Join-Path $script:BackupDirectory "metadata.json"
        
        # Convert metadata to JSON-serializable format
        $jsonData = @{
            'Snapshots' = @()
        }
        
        foreach ($snapshot in $script:BackupMetadata.Values) {
            $jsonData['Snapshots'] += @{
                'SnapshotName'   = $snapshot['SnapshotName']
                'CreatedTime'    = $snapshot['CreatedTime'].ToString('o')
                'Description'    = $snapshot['Description']
                'BackupDir'      = $snapshot['BackupDir']
                'SuccessCount'   = $snapshot['SuccessCount']
                'FailureCount'   = $snapshot['FailureCount']
                'TotalSize'      = $snapshot['TotalSize']
                'FileCount'      = $snapshot['BackupFiles'].Count
            }
        }
        
        $jsonData | ConvertTo-Json | Out-File -FilePath $metadataFile -Encoding UTF8 -Force
        Write-LogDebug "Backup metadata saved: $metadataFile"
        
        return $true
    }
    catch {
        Write-LogError "Failed to save backup metadata" -Exception $_
        return $false
    }
}

<#
.SYNOPSIS
    Load metadata from persistent storage.
#>
function Load-BackupMetadata {
    try {
        $metadataFile = Join-Path $script:BackupDirectory "metadata.json"
        
        if (Test-Path $metadataFile) {
            $jsonData = Get-Content -Path $metadataFile -Raw | ConvertFrom-Json
            Write-LogDebug "Backup metadata loaded from: $metadataFile"
            return $jsonData
        }
        
        return $null
    }
    catch {
        Write-LogWarning "Failed to load backup metadata: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Get total backup size on disk.
#>
function Get-BackupDiskUsage {
    try {
        if (-not (Test-Path $script:BackupDirectory)) {
            return 0
        }
        
        $totalSize = (Get-ChildItem -Path $script:BackupDirectory -Recurse -File | Measure-Object -Property Length -Sum).Sum
        return $totalSize
    }
    catch {
        Write-LogError "Failed to calculate backup disk usage" -Exception $_
        return 0
    }
}

<#
.SYNOPSIS
    Clean up old snapshots based on retention policy.

.PARAMETER DaysToKeep
    Delete snapshots older than this many days (default: 30)
#>
function Invoke-BackupCleanup {
    param(
        [Parameter(Mandatory=$false)]
        [int]$DaysToKeep = 30
    )
    
    try {
        $cutoffDate = (Get-Date).AddDays(-$DaysToKeep)
        $deletedCount = 0
        
        $snapshotsToDelete = @()
        foreach ($snapshot in $script:BackupMetadata.Values) {
            if ($snapshot['CreatedTime'] -lt $cutoffDate) {
                $snapshotsToDelete += $snapshot['SnapshotName']
            }
        }
        
        foreach ($snapshotName in $snapshotsToDelete) {
            if (Remove-BackupSnapshot -SnapshotName $snapshotName) {
                $deletedCount++
            }
        }
        
        Write-LogInfo "Backup cleanup complete: Deleted $deletedCount old snapshots"
        return $deletedCount
    }
    catch {
        Write-LogError "Failed to cleanup old backups" -Exception $_
        return 0
    }
}

# Export public functions
Export-ModuleMember -Function @(
    'Initialize-BackupManagement',
    'New-BackupSnapshot',
    'Restore-BackupSnapshot',
    'Get-BackupSnapshot',
    'Get-AllBackupSnapshots',
    'Remove-BackupSnapshot',
    'Save-BackupMetadata',
    'Load-BackupMetadata',
    'Get-BackupDiskUsage',
    'Invoke-BackupCleanup'
)

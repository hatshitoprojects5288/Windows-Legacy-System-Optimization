<#
.SYNOPSIS
    System validation and pre-flight checks for Windows optimization.

.DESCRIPTION
    Provides comprehensive pre-deployment validation functions to ensure system
    compatibility, permissions, disk space, and other prerequisites.

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

<#
.SYNOPSIS
    Check if running with administrator privileges.
#>
function Test-AdminPrivileges {
    try {
        $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
        $isAdmin = $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
        
        if ($isAdmin) {
            Write-LogDebug "Administrator privileges verified"
            return $true
        }
        else {
            Write-LogError "Script requires administrator privileges"
            return $false
        }
    }
    catch {
        Write-LogError "Failed to check admin privileges" -Exception $_
        return $false
    }
}

<#
.SYNOPSIS
    Get Windows version and build information.
#>
function Get-WindowsVersionInfo {
    try {
        $osInfo = Get-WmiObject Win32_OperatingSystem
        
        $versionInfo = @{
            'OSName'              = $osInfo.Caption
            'OSVersion'           = $osInfo.Version
            'OSBuild'             = [System.Environment]::OSVersion.Version.Build
            'ReleaseID'           = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'ReleaseID' -ErrorAction SilentlyContinue).ReleaseID
            'DisplayVersion'      = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'DisplayVersion' -ErrorAction SilentlyContinue).DisplayVersion
            'WindowsEdition'      = $osInfo.OSType
            'Architecture'        = if ([System.Environment]::Is64BitOperatingSystem) { 'x64' } else { 'x86' }
            'IsWindows10'         = $osInfo.Caption -like '*Windows 10*'
            'IsWindows11'         = $osInfo.Caption -like '*Windows 11*'
        }
        
        Write-LogDebug "OS Info: $($versionInfo.OSName) Build $($versionInfo.OSBuild)"
        return $versionInfo
    }
    catch {
        Write-LogError "Failed to get Windows version info" -Exception $_
        return $null
    }
}

<#
.SYNOPSIS
    Validate Windows version is compatible (Windows 10 22H2 or Windows 11 24H2).
#>
function Test-WindowsVersionCompatibility {
    try {
        $osInfo = Get-WindowsVersionInfo
        
        if (-not $osInfo) {
            Write-LogError "Unable to retrieve Windows version information"
            return $false
        }
        
        # Check Windows 10 22H2
        if ($osInfo.IsWindows10) {
            if ($osInfo.DisplayVersion -eq '22H2' -or $osInfo.ReleaseID -ge '22H2') {
                Write-LogInfo "Windows 10 22H2 detected - compatible"
                return $true
            }
            else {
                Write-LogWarning "Windows 10 version older than 22H2 detected. Compatibility may be limited."
                return $true  # Allow with warning
            }
        }
        
        # Check Windows 11 24H2 or later
        if ($osInfo.IsWindows11) {
            $build = [int]$osInfo.OSBuild
            if ($build -ge 26100) {  # 24H2 is build 26100+
                Write-LogInfo "Windows 11 24H2+ detected - compatible"
                return $true
            }
            else {
                Write-LogWarning "Windows 11 build is older than 24H2. Some optimizations may not apply."
                return $true  # Allow with warning
            }
        }
        
        Write-LogError "Unsupported Windows version: $($osInfo.OSName)"
        return $false
    }
    catch {
        Write-LogError "Failed to validate Windows version" -Exception $_
        return $false
    }
}

<#
.SYNOPSIS
    Check available disk space.

.PARAMETER MinimumMBRequired
    Minimum disk space required in MB (default: 500)
#>
function Test-DiskSpace {
    param(
        [Parameter(Mandatory=$false)]
        [int]$MinimumMBRequired = 500
    )
    
    try {
        $systemDrive = $env:SystemDrive
        $disk = Get-Volume -DriveLetter $systemDrive[0]
        
        $freeSpaceMB = $disk.SizeRemaining / 1MB
        
        if ($freeSpaceMB -ge $MinimumMBRequired) {
            Write-LogDebug "Disk space check passed: $([int]$freeSpaceMB)MB free (required: $MinimumMBRequired MB)"
            return $true
        }
        else {
            Write-LogError "Insufficient disk space: $([int]$freeSpaceMB)MB free (required: $MinimumMBRequired MB)"
            return $false
        }
    }
    catch {
        Write-LogError "Failed to check disk space" -Exception $_
        return $false
    }
}

<#
.SYNOPSIS
    Check available RAM.
#>
function Get-RAMInfo {
    try {
        $osInfo = Get-WmiObject Win32_ComputerSystem
        $totalRAM_GB = $osInfo.TotalPhysicalMemory / 1GB
        
        $ramInfo = @{
            'TotalGB'        = [math]::Round($totalRAM_GB, 2)
            'TotalBytes'     = $osInfo.TotalPhysicalMemory
            'IsLowEndPC'     = $totalRAM_GB -le 8
            'IsUltraLowEnd'  = $totalRAM_GB -le 4
        }
        
        Write-LogDebug "RAM Info: $($ramInfo.TotalGB)GB total"
        return $ramInfo
    }
    catch {
        Write-LogError "Failed to get RAM info" -Exception $_
        return $null
    }
}

<#
.SYNOPSIS
    Check if a PowerShell module is available.

.PARAMETER ModuleName
    Name of the module to check
#>
function Test-PowerShellModule {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ModuleName
    )
    
    try {
        $module = Get-Module -Name $ModuleName -ListAvailable -ErrorAction SilentlyContinue
        
        if ($module) {
            Write-LogDebug "PowerShell module available: $ModuleName"
            return $true
        }
        else {
            Write-LogWarning "PowerShell module not found: $ModuleName"
            return $false
        }
    }
    catch {
        Write-LogError "Failed to check PowerShell module" -Exception $_
        return $false
    }
}

<#
.SYNOPSIS
    Check if a registry path is accessible.

.PARAMETER RegistryPath
    Full registry path to check
#>
function Test-RegistryPathAccess {
    param(
        [Parameter(Mandatory=$true)]
        [string]$RegistryPath
    )
    
    try {
        if (Test-Path $RegistryPath -ErrorAction SilentlyContinue) {
            Write-LogDebug "Registry path accessible: $RegistryPath"
            return $true
        }
        else {
            Write-LogWarning "Registry path not accessible: $RegistryPath"
            return $false
        }
    }
    catch {
        Write-LogDebug "Failed to test registry path access: $RegistryPath"
        return $false
    }
}

<#
.SYNOPSIS
    Check if a Windows service exists.

.PARAMETER ServiceName
    Name of the service to check
#>
function Test-WindowsServiceExists {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ServiceName
    )
    
    try {
        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        
        if ($service) {
            Write-LogDebug "Windows service found: $ServiceName"
            return $true
        }
        else {
            Write-LogWarning "Windows service not found: $ServiceName"
            return $false
        }
    }
    catch {
        Write-LogDebug "Failed to check Windows service: $ServiceName"
        return $false
    }
}

<#
.SYNOPSIS
    Run comprehensive pre-flight validation.

.PARAMETER SkipAdminCheck
    If $true, skips admin privilege check (default: $false)

.PARAMETER SkipVersionCheck
    If $true, skips Windows version check (default: $false)

.PARAMETER SkipDiskSpaceCheck
    If $true, skips disk space check (default: $false)
#>
function Test-PreFlightValidation {
    param(
        [Parameter(Mandatory=$false)]
        [bool]$SkipAdminCheck = $false,
        
        [Parameter(Mandatory=$false)]
        [bool]$SkipVersionCheck = $false,
        
        [Parameter(Mandatory=$false)]
        [bool]$SkipDiskSpaceCheck = $false
    )
    
    try {
        Write-LogInfo "=== Running Pre-Flight Validation ==="
        
        $validationResults = @{
            'AdminPrivileges'      = $true
            'WindowsVersion'       = $true
            'DiskSpace'            = $true
            'AllTestsPassed'       = $true
            'Details'              = @()
        }
        
        # Check admin privileges
        if (-not $SkipAdminCheck) {
            $result = Test-AdminPrivileges
            $validationResults['AdminPrivileges'] = $result
            $validationResults['Details'] += "Admin Privileges: $(if ($result) { 'PASS' } else { 'FAIL' })"
            if (-not $result) { $validationResults['AllTestsPassed'] = $false }
        }
        
        # Check Windows version
        if (-not $SkipVersionCheck) {
            $result = Test-WindowsVersionCompatibility
            $validationResults['WindowsVersion'] = $result
            $validationResults['Details'] += "Windows Version: $(if ($result) { 'PASS' } else { 'FAIL' })"
            if (-not $result) { $validationResults['AllTestsPassed'] = $false }
        }
        
        # Check disk space
        if (-not $SkipDiskSpaceCheck) {
            $result = Test-DiskSpace
            $validationResults['DiskSpace'] = $result
            $validationResults['Details'] += "Disk Space: $(if ($result) { 'PASS' } else { 'FAIL' })"
            if (-not $result) { $validationResults['AllTestsPassed'] = $false }
        }
        
        Write-LogInfo "=== Pre-Flight Validation Complete ==="
        foreach ($detail in $validationResults['Details']) {
            Write-LogInfo $detail
        }
        
        return $validationResults
    }
    catch {
        Write-LogError "Pre-flight validation failed" -Exception $_
        return @{ 'AllTestsPassed' = $false }
    }
}

<#
.SYNOPSIS
    Generate a system compatibility report.
#>
function Generate-SystemCompatibilityReport {
    try {
        Write-LogInfo "Generating system compatibility report..."
        
        $report = @{
            'Timestamp'          = Get-Date
            'WindowsInfo'        = Get-WindowsVersionInfo
            'RAMInfo'            = Get-RAMInfo
            'AdminPrivileges'    = Test-AdminPrivileges
            'WindowsCompatible'  = Test-WindowsVersionCompatibility
            'DiskSpaceOK'        = Test-DiskSpace
        }
        
        Write-LogInfo "System compatibility report generated"
        return $report
    }
    catch {
        Write-LogError "Failed to generate compatibility report" -Exception $_
        return $null
    }
}

# Export public functions
Export-ModuleMember -Function @(
    'Test-AdminPrivileges',
    'Get-WindowsVersionInfo',
    'Test-WindowsVersionCompatibility',
    'Test-DiskSpace',
    'Get-RAMInfo',
    'Test-PowerShellModule',
    'Test-RegistryPathAccess',
    'Test-WindowsServiceExists',
    'Test-PreFlightValidation',
    'Generate-SystemCompatibilityReport'
)

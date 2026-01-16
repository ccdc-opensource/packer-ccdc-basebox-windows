<#
.SYNOPSIS
    Windows Setup Script for Packer Provisioning
.DESCRIPTION
    Configures network profile, WinRM settings, firewall rules, and disables auto-logon
    for use with Packer/Ansible provisioning.
.NOTES
    Requires Administrator privileges
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message"
}

try {
    # Configure Network Profile
    Write-Log "Configuring network connection profile to Private..."
    Get-NetConnectionProfile | 
        Where-Object {$_.NetworkCategory -ne 'DomainAuthenticated'} | 
        Set-NetConnectionProfile -NetworkCategory Private -ErrorAction Stop
    Write-Log "Network profile configured successfully"

    # Configure WinRM
    Write-Log "Configuring WinRM..."
    winrm quickconfig -quiet
    if ($LASTEXITCODE -ne 0) {
        throw "WinRM quickconfig failed with exit code $LASTEXITCODE"
    }
    Write-Log "WinRM quickconfig completed"

    # Enable unencrypted WinRM (required for Ansible)
    Write-Log "Enabling unencrypted WinRM traffic..."
    winrm set winrm/config/service '@{AllowUnencrypted="true"}'
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to enable unencrypted WinRM"
    }

    # Enable basic authentication
    Write-Log "Enabling basic authentication for WinRM..."
    winrm set winrm/config/service/auth '@{Basic="true"}'
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to enable basic authentication"
    }
    Write-Log "WinRM configured successfully"

    # Configure Firewall Rules
    Write-Log "Configuring firewall rules for remote administration..."
    netsh advfirewall firewall set rule group="Windows Remote Administration" new enable=yes
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Warning: Failed to enable Windows Remote Administration firewall group"
    }

    netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" new enable=yes action=allow
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Warning: Failed to enable WinRM HTTP-In firewall rule"
    }
    Write-Log "Firewall rules configured successfully"

    # Disable Auto-Logon
    Write-Log "Disabling auto-logon..."
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoLogonCount -Value 0 -ErrorAction Stop
    Write-Log "Auto-logon disabled successfully"

    Write-Log "Windows setup completed successfully!"
    exit 0

} catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    Write-Log "Setup failed. Please review the error and try again."
    exit 1
}
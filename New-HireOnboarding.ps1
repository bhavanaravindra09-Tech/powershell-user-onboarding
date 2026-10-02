#Requires -Version 5.1
#Requires -Modules ActiveDirectory

<#
.SYNOPSIS
    Automates new-hire IT onboarding in Active Directory.

.DESCRIPTION
    Creates an AD user account for a new hire, adds the account to the
    standard security groups for their department, creates a personal home
    folder on the file server (mapped as H:), forces a password change at
    next logon, and writes every action to a timestamped log file.

    Supports -WhatIf, so the entire run can be previewed safely before any
    change is made in Active Directory.

    Prerequisites:
      - Windows with the RSAT "ActiveDirectory" PowerShell module installed
      - An account with rights to create users, modify group membership,
        and create folders / set ACLs on the file share

.NOTES
    Domain references (contoso.local / CONTOSO) are placeholders — replace
    them with your organisation's real domain before use.

.EXAMPLE
    .\New-HireOnboarding.ps1 -FirstName "Aarav" -LastName "Sharma" -Department "Support" -WhatIf
    Preview every change without touching Active Directory.

.EXAMPLE
    .\New-HireOnboarding.ps1 -FirstName "Aarav" -LastName "Sharma" -Department "IT"
    Run the full onboarding with default OU and home-folder locations.

.EXAMPLE
    .\New-HireOnboarding.ps1 -FirstName "Priya" -LastName "Nair" -Department "Finance" `
        -OrganizationalUnit "OU=Finance,OU=Users,DC=contoso,DC=local" `
        -HomeFolderRoot "\\fs02\home$"
    Run with a custom OU and file server.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true, HelpMessage = "New hire's first name.")]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern('^[A-Za-z''\-\s]+$')]
    [string]$FirstName,

    [Parameter(Mandatory = $true, HelpMessage = "New hire's last name.")]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern('^[A-Za-z''\-\s]+$')]
    [string]$LastName,

    [Parameter(Mandatory = $true, HelpMessage = "New hire's department.")]
    [ValidateSet('IT', 'Finance', 'HR', 'Sales', 'Support', 'Operations')]
    [string]$Department,

    [Parameter(HelpMessage = "Distinguished name of the OU for the new account.")]
    [ValidateNotNullOrEmpty()]
    [string]$OrganizationalUnit = 'OU=Users,DC=contoso,DC=local',

    [Parameter(HelpMessage = "UNC root under which the home folder is created.")]
    [ValidateNotNullOrEmpty()]
    [string]$HomeFolderRoot = '\\fileserver\home$',

    [Parameter(HelpMessage = "Folder where the timestamped log file is written.")]
    [ValidateNotNullOrEmpty()]
    [string]$LogDirectory = (Join-Path $PSScriptRoot 'Logs')
)

# Standard security groups per department. Group names are examples —
# align them with your organisation's actual group naming convention.
$DepartmentGroups = @{
    'IT'         = @('GG_IT_Support', 'GG_VPN_Users', 'GG_Software_Install')
    'Finance'    = @('GG_Finance_Users', 'GG_VPN_Users')
    'HR'         = @('GG_HR_Users', 'GG_VPN_Users')
    'Sales'      = @('GG_Sales_Users', 'GG_CRM_Users', 'GG_VPN_Users')
    'Support'    = @('GG_Helpdesk_Agents', 'GG_VPN_Users', 'GG_Ticketing_System')
    'Operations' = @('GG_Operations_Users', 'GG_VPN_Users')
}

function Write-Log {
    <#
    .SYNOPSIS
        Writes a timestamped line to the log file and the console.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter()]
        [ValidateSet('INFO', 'WARN', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[$timestamp] [$Level] $Message"
    Add-Content -Path $script:LogFile -Value $line

    switch ($Level) {
        'ERROR'   { Write-Host $line -ForegroundColor Red }
        'WARN'    { Write-Host $line -ForegroundColor Yellow }
        'SUCCESS' { Write-Host $line -ForegroundColor Green }
        default   { Write-Host $line }
    }
}

function New-TemporaryPassword {
    <#
    .SYNOPSIS
        Generates a random temporary password meeting typical complexity rules.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateRange(12, 32)]
        [int]$Length = 14
    )

    $sets = @(
        'ABCDEFGHJKLMNPQRSTUVWXYZ',   # upper-case (no I, O)
        'abcdefghijkmnpqrstuvwxyz',   # lower-case (no l)
        '23456789',                   # digits (no 0, 1)
        '!@#$%^&*()-_=+'              # symbols
    )

    # Guarantee at least two characters from each set, then fill the rest.
    $chars = foreach ($set in $sets) {
        1..2 | ForEach-Object { $set[(Get-Random -Maximum $set.Length)] }
    }
    $all = -join $sets
    while ($chars.Count -lt $Length) {
        $chars += $all[(Get-Random -Maximum $all.Length)]
    }

    -join ($chars | Sort-Object { Get-Random })
}

function Get-AvailableSamAccountName {
    <#
    .SYNOPSIS
        Builds a unique sAMAccountName (first initial + last name), appending
        a number if the name already exists in Active Directory.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$FirstName,
        [Parameter(Mandatory = $true)][string]$LastName
    )

    $base = (($FirstName.Substring(0, 1) + $LastName) -replace '[^A-Za-z]', '').ToLower()
    if ([string]::IsNullOrEmpty($base)) {
        throw "Could not derive an account name from '$FirstName $LastName'."
    }
    if ($base.Length -gt 18) { $base = $base.Substring(0, 18) }

    $candidate = $base
    $suffix = 1
    while (Get-ADUser -Filter "SamAccountName -eq '$candidate'" -ErrorAction SilentlyContinue) {
        $suffix++
        $candidate = "$base$suffix"
        if ($candidate.Length -gt 20) {
            # sAMAccountName limit is 20 characters — trim the base to fit.
            $candidate = $base.Substring(0, 20 - $suffix.ToString().Length) + $suffix
        }
    }

    return $candidate
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

if (-not (Test-Path -Path $LogDirectory)) {
    New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
}
$script:LogFile = Join-Path $LogDirectory ("Onboarding_{0:yyyyMMdd_HHmmss}.log" -f (Get-Date))

Write-Log "Starting onboarding for $FirstName $LastName (Department: $Department)"

try {
    # 1. Derive a unique account name and a temporary password.
    $samAccountName = Get-AvailableSamAccountName -FirstName $FirstName -LastName $LastName
    $userPrincipalName = "$samAccountName@contoso.local"   # placeholder domain
    $displayName = "$FirstName $LastName"
    $tempPassword = New-TemporaryPassword
    $securePassword = ConvertTo-SecureString $tempPassword -AsPlainText -Force
    Write-Log "Generated account name: $samAccountName"

    # 2. Create the AD user (password must change at next logon).
    $newUserParams = @{
        Name                  = $displayName
        GivenName             = $FirstName
        Surname               = $LastName
        SamAccountName        = $samAccountName
        UserPrincipalName     = $userPrincipalName
        Path                  = $OrganizationalUnit
        AccountPassword       = $securePassword
        Enabled               = $true
        ChangePasswordAtLogon = $true
        Department            = $Department
        Description           = "Created by New-HireOnboarding.ps1 on $(Get-Date -Format 'yyyy-MM-dd')"
    }

    if ($PSCmdlet.ShouldProcess($displayName, "Create AD user '$samAccountName'")) {
        New-ADUser @newUserParams -ErrorAction Stop
        Write-Log "Created AD user '$samAccountName' in $OrganizationalUnit" -Level SUCCESS
    }

    # 3. Add to the department's standard security groups.
    #    A failure on one group is logged but does not stop the rest.
    foreach ($group in $DepartmentGroups[$Department]) {
        try {
            if ($PSCmdlet.ShouldProcess($samAccountName, "Add to group '$group'")) {
                Add-ADGroupMember -Identity $group -Members $samAccountName -ErrorAction Stop
                Write-Log "Added '$samAccountName' to group '$group'" -Level SUCCESS
            }
        }
        catch {
            Write-Log "Could not add '$samAccountName' to group '$group': $($_.Exception.Message)" -Level ERROR
        }
    }

    # 4. Create the home folder, lock the ACL to the user, map it as H:.
    $homeFolder = Join-Path $HomeFolderRoot $samAccountName
    if ($PSCmdlet.ShouldProcess($homeFolder, 'Create home folder')) {
        try {
            New-Item -ItemType Directory -Path $homeFolder -Force -ErrorAction Stop | Out-Null

            $acl = Get-Acl -Path $homeFolder
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                "CONTOSO\$samAccountName", 'FullControl',
                'ContainerInherit,ObjectInherit', 'None', 'Allow'
            )
            $acl.SetAccessRule($rule)
            Set-Acl -Path $homeFolder -AclObject $acl -ErrorAction Stop

            Set-ADUser -Identity $samAccountName `
                -HomeDirectory $homeFolder -HomeDrive 'H:' -ErrorAction Stop

            Write-Log "Created home folder $homeFolder and mapped H: drive" -Level SUCCESS
        }
        catch {
            Write-Log "Home-folder step failed: $($_.Exception.Message)" -Level ERROR
        }
    }

    Write-Log "Onboarding complete for $displayName ($samAccountName)." -Level SUCCESS
    Write-Log 'Share the temporary password through a secure channel (sealed envelope or password vault) — never by plain email.'
    Write-Log "Log file: $script:LogFile"
}
catch {
    Write-Log "Onboarding FAILED: $($_.Exception.Message)" -Level ERROR
    exit 1
}

@{
    # Script module or binary module file associated with this manifest
    RootModule = 'UniFiAccess.psm1'
    
    # Version number of this module
    ModuleVersion = '0.1'
    
    # ID used to uniquely identify this module
    GUID = '8c5e8f4a-9b3c-4d2e-8a1f-6c7d9e0f1a2b'
    
    # Author of this module
    Author = 'Justin Simmonds'
    
    # Copyright statement for this module
    Copyright = '(c) 2025. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'PowerShell 7 module for interacting with UniFi Access API'
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '7.0'
    
    # Functions to export from this module
    FunctionsToExport = @(
        # Connection
        'Connect-UniFiAccess',
        'Disconnect-UniFiAccess',
        'Get-UniFiAccessConnection',
        
        # Users
        'New-UniFiAccessUser',
        'Get-UniFiAccessUser',
        'Get-UniFiAccessUsers',
        'Set-UniFiAccessUser',
        'Remove-UniFiAccessUser',
        'Search-UniFiAccessUser',
        'Set-UniFiAccessUserProfilePicture',
        
        # User Groups
        'New-UniFiAccessUserGroup',
        'Get-UniFiAccessUserGroup',
        'Get-UniFiAccessUserGroups',
        'Set-UniFiAccessUserGroup',
        'Remove-UniFiAccessUserGroup',
        'Add-UniFiAccessUserToGroup',
        'Remove-UniFiAccessUserFromGroup',
        'Get-UniFiAccessUserGroupMembers',
        
        # Visitors
        'New-UniFiAccessVisitor',
        'Get-UniFiAccessVisitor',
        'Get-UniFiAccessVisitors',
        'Set-UniFiAccessVisitor',
        'Remove-UniFiAccessVisitor',
        
        # Access Policies
        'New-UniFiAccessPolicy',
        'Get-UniFiAccessPolicy',
        'Get-UniFiAccessPolicies',
        'Set-UniFiAccessPolicy',
        'Remove-UniFiAccessPolicy',
        'Add-UniFiAccessPolicyToUser',
        'Add-UniFiAccessPolicyToUserGroup',
        'Get-UniFiAccessUserPolicies',
        'Get-UniFiAccessUserGroupPolicies',
        
        # Schedules
        'New-UniFiAccessSchedule',
        'Get-UniFiAccessSchedule',
        'Get-UniFiAccessSchedules',
        'Set-UniFiAccessSchedule',
        'Remove-UniFiAccessSchedule',
        
        # Holiday Groups
        'New-UniFiAccessHolidayGroup',
        'Get-UniFiAccessHolidayGroup',
        'Get-UniFiAccessHolidayGroups',
        'Set-UniFiAccessHolidayGroup',
        'Remove-UniFiAccessHolidayGroup',
        
        # Credentials
        'New-UniFiAccessPINCode',
        'New-UniFiAccessNFCEnrollment',
        'Get-UniFiAccessNFCEnrollmentStatus',
        'Remove-UniFiAccessNFCEnrollmentSession',
        'Get-UniFiAccessNFCCard',
        'Get-UniFiAccessNFCCards',
        'Set-UniFiAccessNFCCard',
        'Remove-UniFiAccessNFCCard',
        'Add-UniFiAccessNFCCardToUser',
        'Remove-UniFiAccessNFCCardFromUser',
        'Add-UniFiAccessNFCCardToVisitor',
        'Remove-UniFiAccessNFCCardFromVisitor',
        'Add-UniFiAccessPINToUser',
        'Remove-UniFiAccessPINFromUser',
        'Add-UniFiAccessPINToVisitor',
        'Remove-UniFiAccessPINFromVisitor',
        'Import-UniFiAccessThirdPartyNFCCard',
        
        # Touch Pass
        'Get-UniFiAccessTouchPass',
        'Get-UniFiAccessTouchPasses',
        'Search-UniFiAccessTouchPass',
        'Get-UniFiAccessAssignableTouchPasses',
        'Set-UniFiAccessTouchPass',
        'Get-UniFiAccessTouchPassDetails',
        'New-UniFiAccessTouchPassPurchase',
        'Add-UniFiAccessTouchPassToUser',
        'Remove-UniFiAccessTouchPassFromUser',
        'Add-UniFiAccessTouchPassesToUsers',
        
        # License Plates
        'Add-UniFiAccessLicensePlateToUser',
        'Remove-UniFiAccessLicensePlateFromUser',
        'Add-UniFiAccessLicensePlateToVisitor',
        'Remove-UniFiAccessLicensePlateFromVisitor',
        
        # QR Codes
        'Add-UniFiAccessQRCodeToVisitor',
        'Remove-UniFiAccessQRCodeFromVisitor',
        'Get-UniFiAccessQRCodeImage',
        
        # Doors
        'Get-UniFiAccessDoor',
        'Get-UniFiAccessDoors',
        'Unlock-UniFiAccessDoor',
        'Set-UniFiAccessDoorTemporaryUnlock',
        'Get-UniFiAccessDoorLockStatus',
        
        # Door Groups
        'Get-UniFiAccessDoorGroupTopology',
        'New-UniFiAccessDoorGroup',
        'Get-UniFiAccessDoorGroup',
        'Get-UniFiAccessDoorGroups',
        'Set-UniFiAccessDoorGroup',
        'Remove-UniFiAccessDoorGroup',
        
        # Devices
        'Get-UniFiAccessDevice',
        'Get-UniFiAccessDevices',
        'Get-UniFiAccessDeviceAccessMethod',
        'Set-UniFiAccessDeviceAccessMethod',
        
        # Logs
        'Get-UniFiAccessLogs',
        
        # Webhooks
        'New-UniFiAccessWebhook',
        'Get-UniFiAccessWebhook',
        'Get-UniFiAccessWebhooks',
        'Set-UniFiAccessWebhook',
        'Remove-UniFiAccessWebhook',
        'Test-UniFiAccessWebhook',
        'Get-UniFiAccessWebhookEvents'
    )
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport = @()
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            Tags = @('UniFi', 'Access', 'API', 'Security', 'AccessControl')
            LicenseUri = ''
            ProjectUri = ''
            ReleaseNotes = 'Initial release of UniFi Access API PowerShell module'
        }
    }
}

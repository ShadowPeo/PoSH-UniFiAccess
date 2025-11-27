#Requires -Version 7.0

#region Module-level variables
$script:UniFiAccessConnection = @{
    BaseUri = $null
    Token = $null
    Headers = $null
    Connected = $false
}

$errorMessage = @{
    "CODE_PARAMS_INVALID" = "The provided parameters are invalid."
    "CODE_SYSTEM_ERROR" = "An error occurred on the server's end."
    "CODE_RESOURCE_NOT_FOUND" = "The requested resource was not found."
    "CODE_OPERATION_FORBIDDEN" = "The requested operation is not allowed."
    "CODE_AUTH_FAILED" = "Authentication failed."
    "CODE_ACCESS_TOKEN_INVALID" = "The provided access token is invalid."
    "CODE_UNAUTHORIZED" = "You not are allowed to perform this action."
    "CODE_NOT_EXISTS" = "The requested item does not exist."
    "CODE_USER_EMAIL_ERROR" = "The provided email format is invalid."
    "CODE_USER_ACCOUNT_NOT_EXIST" = "The requested user account does not exist."
    "CODE_USER_WORKER_NOT_EXISTS" = "The requested user does not exist."
    "CODE_USER_NAME_DUPLICATED" = "The provided name already exists."
    "CODE_USER_CSV_IMPORT_INCOMPLETE_PROP" = "Please provide both first name and last name."
    "CODE_ACCESS_POLICY_USER_TIMEZONE_NOT_FOUND" = "The requested workday schedule could not be found."
    "CODE_ACCESS_POLICY_HOLIDAY_TIMEZONE_NOT_FOUND" = "The requested holiday schedule could not be found."
    "CODE_ACCESS_POLICY_HOLIDAY_GROUP_NOT_FOUND" = "The requested holiday group could not be found."
    "CODE_ACCESS_POLICY_HOLIDAY_NOT_FOUND" = "The requested holiday could not be found."
    "CODE_ACCESS_POLICY_SCHEDULE_NOT_FOUND" = "The requested schedule could not be found."
    "CODE_ACCESS_POLICY_HOLIDAY_NAME_EXIST" = "The provided holiday name already exists."
    "CODE_ACCESS_POLICY_HOLIDAY_GROUP_NAME_EXIST" = "The provided holiday group name already exists."
    "CODE_ACCESS_POLICY_SCHEDULE_NAME_EXIST" = "The provided schedule name already exists."
    "CODE_ACCESS_POLICY_SCHEDULE_CAN_NOT_DELETE" = "The schedule could not be deleted."
    "CODE_ACCESS_POLICY_HOLIDAY_GROUP_CAN_NOT_DELETE" = "The holiday group could not be deleted."
    "CODE_CREDS_NFC_HAS_BIND_USER" = "The NFC card is already registered and assigned to another user."
    "CODE_CREDS_DISABLE_TRANSFER_UID_USER_NFC" = "The UniFi Identity Enterprise user's NFC card is not transferrable."
    "CODE_CREDS_NFC_READ_SESSION_NOT_FOUND" = "Failed to obtain the NFC read session."
    "CODE_CREDS_NFC_READ_POLL_TOKEN_EMPTY" = "The NFC token is empty."
    "CODE_CREDS_NFC_CARD_IS_PROVISION" = "The NFC card is already registered at another site."
    "CODE_CREDS_NFC_CARD_PROVISION_FAILED" = "Please hold the NFC card against the reader for more than 5 seconds."
    "CODE_CREDS_NFC_CARD_INVALID" = "The card type is not supported. Please use a UA Card."
    "CODE_CREDS_NFC_CARD_CANNOT_BE_DELETE" = "The NFC card could not be deleted."
    "CODE_CREDS_PIN_CODE_CREDS_ALREADY_EXIST" = "The PIN code already exists."
    "CODE_CREDS_PIN_CODE_CREDS_LENGTH_INVALID" = "The PIN code length does not meet the preset requirements."
    "CODE_SPACE_DEVICE_BOUND_LOCATION_NOT_FOUND" = "The device's location was not found."
    "CODE_DEVICE_DEVICE_VERSION_NOT_FOUND" = "The firmware version is up to date."
    "CODE_DEVICE_DEVICE_VERSION_TOO_OLD" = "The firmware version is too old. Please update to the latest version."
    "CODE_DEVICE_DEVICE_BUSY" = "The camera is currently in use."
    "CODE_DEVICE_DEVICE_NOT_FOUND" = "The device was not found."
    "CODE_DEVICE_DEVICE_OFFLINE" = "The device is currently offline."
    "CODE_OTHERS_UID_ADOPTED_NOT_SUPPORTED" = "The API is not available after upgrading to Identity Enterprise."
    "CODE_HOLIDAY_GROUP_CAN_NOT_DELETE" = "The holiday group could not be deleted."
    "CODE_HOLIDAY_GROUP_CAN_NOT_EDIT" = "The holiday group could not be edited."
    "CODE_DEVICE_WEBHOOK_ENDPOINT_DUPLICATED" = "The provided endpoint already exists."
    "CODE_DEVICE_API_NOT_SUPPORTED" = "The API is currently not available for this device."
}

#endregion Module-level variables

#region Helper Functions

<#
.SYNOPSIS
    Invokes a UniFi Access API request.
    
.DESCRIPTION
    Internal helper function to make API requests with proper error handling.
    
.PARAMETER Method
    HTTP method (GET, POST, PUT, DELETE, PATCH)
    
.PARAMETER Endpoint
    API endpoint path
    
.PARAMETER Body
    Request body (will be converted to JSON)
    
.PARAMETER ContentType
    Content type for the request (default: application/json)
#>
function Invoke-UniFiAccessRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('GET', 'POST', 'PUT', 'DELETE', 'PATCH')]
        [string]$Method,
        
        [Parameter(Mandatory)]
        [string]$Endpoint,
        
        [Parameter()]
        [object]$Body,
        
        [Parameter()]
        [string]$ContentType = 'application/json',
        
        [Parameter()]
        [hashtable]$AdditionalHeaders = @{},

        [Parameter()]
        [switch]$ConnectionTest
    )
    
    if (-not $script:UniFiAccessConnection.Connected -and -not $ConnectionTest) {
        throw "Not connected to UniFi Access. Please run Connect-UniFiAccess first."
    }
    
    $uri = "$($script:UniFiAccessConnection.BaseUri)$Endpoint"

    $requestParams = @{
        Uri = $uri
        Method = $Method
        Headers = $script:UniFiAccessConnection.Headers + $AdditionalHeaders
        ContentType = $ContentType
    }
    
    if ($script:UniFiAccessConnection.SkipCertificateCheck) {
        $requestParams.SkipCertificateCheck = $true
    }

    if ($Body) {
        if ($Body -is [string]) {
            $requestParams.Body = $Body
        } else {
            $requestParams.Body = $Body | ConvertTo-Json -Depth 10
        }
    }
    
    try {
        Write-Verbose "Making $Method request to: $uri"
        $response = Invoke-RestMethod @requestParams
        
        # Check for API-level errors
        if ($response.code -and $response.code -eq 'SUCCESS') {
        
            $response = [PSCustomObject]@{
            api_status = "SUCCESS"
#            api_result = 'SUCCESS'
            api_returnCode = if ($response.code) { $response.code } else { 'SUCCESS' }
            api_returnData = if ($response.data) { $response.data } else { $null }
            api_returnMessage = if ($response.message) { $response.message } else { $null }
        }  
        }
        elseif ($response.code -and $response.code -ne 'SUCCESS') {
            $response = [PSCustomObject]@{
                api_status = 'SUCCESS'
 #               api_result = 'ERROR'
                api_returnCode = $response.code
                api_returnData = ""
                api_returnMessage = if ($errorMessage.ContainsKey($response.code)) { $errorMessage[$response.code] } else { $response.msg }
            }
        }
        
    }
    catch {
        $response = [PSCustomObject]@{
            api_status = 'ERROR'
 #           api_result = $null
            api_returnCode = $null
            api_returnData = $null
            api_returnMessage = $null
        }
    }

    return $response
}

<#
.SYNOPSIS
    Formats query parameters for URL.
    
.DESCRIPTION
    Internal helper to build query strings from hashtables.
#>
function Get-QueryString {
    [CmdletBinding()]
    param(
        [Parameter()]
        [hashtable]$Parameters
    )
    
    if (-not $Parameters -or $Parameters.Count -eq 0) {
        return ''
    }
    
    $queryParts = @()
    foreach ($key in $Parameters.Keys) {
        if ($null -ne $Parameters[$key]) {
            $value = [System.Web.HttpUtility]::UrlEncode($Parameters[$key].ToString())
            $queryParts += "$key=$value"
        }
    }
    
    if ($queryParts.Count -gt 0) {
        return '?' + ($queryParts -join '&')
    }
    
    return ''
}

#endregion

#region Connection Management

<#
.SYNOPSIS
    Connects to a UniFi Access instance.
    
.DESCRIPTION
    Establishes a connection to the UniFi Access API using an API token.
    
.PARAMETER Hostname
    The hostname or IP address of the UniFi Access instance
    
.PARAMETER Token
    API token for authentication
    
.PARAMETER Port
    API port (default: 12445)
    
.PARAMETER UseHTTPS
    Use HTTPS for connections (default: true)
    
.PARAMETER SkipCertificateCheck
    Skip SSL certificate validation (useful for self-signed certificates)
    
.EXAMPLE
    Connect-UniFiAccess -Hostname "access.example.com" -Token "your-api-token"
    
.EXAMPLE
    Connect-UniFiAccess -Hostname "192.168.1.100" -Token "your-token" -SkipCertificateCheck
#>

function Connect-UniFiAccess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Hostname,
        
        [Parameter(Mandatory)]
        [string]$Token,
        
        [Parameter()]
        [int]$Port = 12445,
        
        [Parameter()]
        [bool]$UseHTTPS = $true,
        
        [Parameter()]
        [switch]$SkipCertificateCheck
    )
    
    $protocol = if ($UseHTTPS) { 'https' } else { 'http' }
    $script:UniFiAccessConnection.BaseUri = "${protocol}://${Hostname}:${Port}/api/v1/developer"
    $script:UniFiAccessConnection.Token = $Token
    $script:UniFiAccessConnection.Headers = @{
        'Authorization' = "Bearer $Token"
        'Accept' = 'application/json'
    }
    
    # Configure certificate validation if needed
    if ($SkipCertificateCheck) {
        if ($PSVersionTable.PSVersion.Major -ge 7) {
            # PowerShell 7+ uses SkipCertificateCheck parameter
            $script:UniFiAccessConnection.SkipCertificateCheck = $true
        }
    }
    
    # Test the connection
    try {
        Write-Verbose "Testing connection to $($script:UniFiAccessConnection.BaseUri)"
        $tempReturn = Invoke-UniFiAccessRequest -Method GET -Endpoint '/users' -ConnectionTest
        $script:UniFiAccessConnection.Connected = $true
        Write-Output "Successfully connected to UniFi Access at $Hostname"
    }
    catch {
        $script:UniFiAccessConnection.Connected = $false
        throw "Failed to connect to UniFi Access: $_"
    }
}

<#
.SYNOPSIS
    Disconnects from the UniFi Access instance.
    
.DESCRIPTION
    Clears the current connection information.
    
.EXAMPLE
    Disconnect-UniFiAccess
#>
function Disconnect-UniFiAccess {
    [CmdletBinding()]
    param()
    
    $script:UniFiAccessConnection = @{
        BaseUri = $null
        Token = $null
        Headers = $null
        Connected = $false
    }
    
    Write-Host "Disconnected from UniFi Access" -ForegroundColor Yellow
}

<#
.SYNOPSIS
    Gets the current connection status.
    
.DESCRIPTION
    Returns information about the current UniFi Access connection.
    
.EXAMPLE
    Get-UniFiAccessConnection
#>
function Get-UniFiAccessConnection {
    [CmdletBinding()]
    param()
    
    return [PSCustomObject]@{
        Connected = $script:UniFiAccessConnection.Connected
        BaseUri = $script:UniFiAccessConnection.BaseUri
        HasToken = -not [string]::IsNullOrEmpty($script:UniFiAccessConnection.Token)
    }
}

#endregion

#region User Management

<#
.SYNOPSIS
    Creates a new UniFi Access user.
    
.DESCRIPTION
    Registers a new user in the UniFi Access system.
    
.PARAMETER FirstName
    User's first name
    
.PARAMETER LastName
    User's last name
    
.PARAMETER Email
    User's email address

.PARAMETER OnboardTime
    The time the user was onboarded/start date (datetime).

.PARAMETER EmployeeNumber
    Optional employee number

.PARAMETER AdditionalProperties
    Hashtable of additional properties to include in the user creation request. - This is here for future use cases where new properties may be added to the API.
    
.EXAMPLE
    New-UniFiAccessUser -FirstName "John" -LastName "Doe" -Email "john.doe@example.com"
#>
function New-UniFiAccessUser {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FirstName,
        
        [Parameter(Mandatory)]
        [string]$LastName,
        
        [Parameter()]
        [string]$Email,
        
        [Parameter()]
        [datetime]$onboardTime,

        [Parameter()]
        [string]$EmployeeNumber,
        
        [Parameter()]
        [hashtable]$AdditionalProperties
    )
    
    $body = @{
        first_name = $FirstName
        last_name = $LastName
    }
    
    if ($Email) { $body.email = $Email }
    if ($EmployeeNumber) { $body.employee_number = $EmployeeNumber }
    if ($onboardTime) { $body.onboard_time = [int][double]::Parse((Get-Date ($onboardTime).ToUniversalTime() -UFormat %s)) }
    
    if ($AdditionalProperties) {
        foreach ($key in $AdditionalProperties.Keys) {
            $body[$key] = $AdditionalProperties[$key]
        }
    }
    
    $response = Invoke-UniFiAccessRequest -Method POST -Endpoint '/users' -Body $body
    return $response
}

<#
.SYNOPSIS
    Gets a specific UniFi Access user.
    
.DESCRIPTION
    Retrieves details for a specific user by ID.
    
.PARAMETER UserId
    The unique identifier of the user

.PARAMETER Expand
    Include expanded user details in the response (curently access policies)
    
.EXAMPLE
    Get-UniFiAccessUser -UserId "user-123"
    Gets the full details of the specified user

.EXAMPLE
    Get-UniFiAccessUser  -UserId "user-123" -Expand
    Gets the full details of the specified user including expanded details (curently access policies)
#>
function Get-UniFiAccessUser {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Id')]
        [string]$UserId,
        
        [switch]$Expand
    )
    
    $queryParams = @{}
    if ($Expand) {
        $queryParams.'expand[]' = 'access_policy'
    }

    $queryString = Get-QueryString -Parameters $queryParams
    $response = Invoke-UniFiAccessRequest -Method GET -Endpoint "/users/$UserId$queryString"
    return $response
}

<#
.SYNOPSIS
    Gets all UniFi Access users.
    
.DESCRIPTION
    Retrieves a list of all users with optional pagination and expanded details.
    
.PARAMETER PageNum
    Page number to retrieve (1-based). Must be used with PageSize. Default is 1.
    
.PARAMETER PageSize
    Number of results per page. Must be used with PageNum. Default is 25.
    
.PARAMETER Expand
    Include expanded user details in the response (curently access policies)
    
.EXAMPLE
    Get-UniFiAccessUsers
    Gets first page of users (25 results)
    
.EXAMPLE
    Get-UniFiAccessUsers -PageNum 2 -PageSize 50
    Gets the second page with 50 results per page
    
.EXAMPLE
    Get-UniFiAccessUsers -PageNum 1 -PageSize 100 -Expand
    Gets first page with 100 results including expanded details
    
.EXAMPLE
    Get-UniFiAccessUsers -Expand
    Gets first page with default size (25) including expanded details
#>
function Get-UniFiAccessUsers {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param(
        [Parameter(ParameterSetName = 'Paging', Mandatory = $false)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$PageNum = 1,
        
        [Parameter(ParameterSetName = 'Paging', Mandatory = $false)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$PageSize = 25,
        
        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'Paging')]
        [switch]$Expand
    )
    
    $queryParams = @{}
    
    # Calculate offset from page number if using pagination
    if ($PSCmdlet.ParameterSetName -eq 'Paging') {
        $queryParams.page_size = $PageSize
        $queryParams.page_num = $PageNum
    }
    
    # Add expand parameter if specified
    if ($Expand) {
        $queryParams.'expand[]' = 'access_policy'
    }

    $queryString = Get-QueryString -Parameters $queryParams
    $response = Invoke-UniFiAccessRequest -Method GET -Endpoint "/users$queryString"
    return $response
}

<#
.SYNOPSIS
    Updates a UniFi Access user.
    
.DESCRIPTION
    Updates properties of an existing user.
    
.PARAMETER UserId
    The unique identifier of the user
    
.PARAMETER FirstName
    User's first name
    
.PARAMETER LastName
    User's last name
    
.PARAMETER Email
    User's email address

.PARAMETER OnboardTime
    The time the user was onboarded/start date (datetime).
    
.PARAMETER Status
    User status
    
.EXAMPLE
    Set-UniFiAccessUser -UserId "user-123" -Email "newemail@example.com"
#>
function Set-UniFiAccessUser {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Id')]
        [string]$UserId,
        
        [Parameter()]
        [string]$FirstName,
        
        [Parameter()]
        [string]$LastName,
        
        [Parameter()]
        [string]$Email,

        [Parameter()]
        [datetime]$onboardTime,
        
        [Parameter()]
        [string]$EmployeeNumber,
        
        [Parameter()]
        [ValidateSet('ACTIVE', 'DEACTIVATED')]
        [string]$Status
    )
    
    process {
        $body = @{}
        
        if ($FirstName) { $body.first_name = $FirstName }
        if ($LastName) { $body.last_name = $LastName }
        if ($Email) { $body.email = $Email }
        if ($onboardTime) { $body.onboard_time = [int][double]::Parse((Get-Date ($onboardTime).ToUniversalTime() -UFormat %s)) }
        if ($EmployeeNumber) { $body.employee_number = $EmployeeNumber }
        if ($Status) { $body.status = $Status }
        
        $response = Invoke-UniFiAccessRequest -Method PUT -Endpoint "/users/$UserId" -Body $body
        return $response
    }
}

<#
.SYNOPSIS
    Removes a UniFi Access user.
    
.DESCRIPTION
    Deletes a user from the system.
    
.PARAMETER UserId
    The unique identifier of the user
    
.PARAMETER Force
    Skip confirmation prompt
    
.EXAMPLE
    Remove-UniFiAccessUser -UserId "user-123"
#>
function Remove-UniFiAccessUser {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Id')]
        [string]$UserId,
        
        [Parameter()]
        [switch]$Force
    )
    
    process {
        if ($Force -or $PSCmdlet.ShouldProcess($UserId, 'Delete user')) {
            $response = Invoke-UniFiAccessRequest -Method DELETE -Endpoint "/users/$UserId"
            return $response
        }
    }
}

<#
.SYNOPSIS
    Searches for UniFi Access users.
    
.DESCRIPTION
    Searches for users based on various criteria.
    
.PARAMETER Query
    Search query string
    
.PARAMETER Limit
    Maximum number of results
    
.EXAMPLE
    Search-UniFiAccessUser -Query "john"
#>
function Search-UniFiAccessUser {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Query,
        
        [Parameter()]
        [int]$Limit
    )
    
    $queryParams = @{
        query = $Query
    }
    if ($PSBoundParameters.ContainsKey('Limit')) { $queryParams.limit = $Limit }
    
    $queryString = Get-QueryString -Parameters $queryParams
    $response = Invoke-UniFiAccessRequest -Method GET -Endpoint "/users/search$queryString"
    return $response
}

<#
.SYNOPSIS
    Sets a user's profile picture.
    
.DESCRIPTION
    Uploads a profile picture for a user.
    
.PARAMETER UserId
    The unique identifier of the user
    
.PARAMETER ImagePath
    Path to the image file
    
.EXAMPLE
    Set-UniFiAccessUserProfilePicture -UserId "user-123" -ImagePath "C:\pictures\profile.jpg"
#>
function Set-UniFiAccessUserProfilePicture {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$UserId,
        
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ })]
        [string]$ImagePath
    )
    
    # Note: This would require multipart/form-data handling
    # Implementation depends on specific API requirements
    throw "Profile picture upload requires multipart/form-data implementation"
}

#endregion

#region User Group Management

<#
.SYNOPSIS
    Creates a new user group.
    
.DESCRIPTION
    Creates a new user group in UniFi Access.
    
.PARAMETER Name
    Name of the user group
    
.PARAMETER Type
    Type of user group (default: CUSTOM)
    
.EXAMPLE
    New-UniFiAccessUserGroup -Name "IT Department"
#>
function New-UniFiAccessUserGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        
        [Parameter()]
        [string]$Type = 'CUSTOM'
    )
    
    $body = @{
        name = $Name
        type = $Type
    }
    
    $response = Invoke-UniFiAccessRequest -Method POST -Endpoint '/user_group' -Body $body
    return $response
}

<#
.SYNOPSIS
    Gets a specific user group.
    
.PARAMETER GroupId
    The unique identifier of the user group
    
.EXAMPLE
    Get-UniFiAccessUserGroup -GroupId "group-123"
#>
function Get-UniFiAccessUserGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Id')]
        [string]$GroupId
    )
    
    process {
        $response = Invoke-UniFiAccessRequest -Method GET -Endpoint "/user_group/$GroupId"
        return $response
    }
}

<#
.SYNOPSIS
    Gets all user groups.
    
.EXAMPLE
    Get-UniFiAccessUserGroups
#>
function Get-UniFiAccessUserGroups {
    [CmdletBinding()]
    param()
    
    $response = Invoke-UniFiAccessRequest -Method GET -Endpoint '/user_group'
    return $response
}

<#
.SYNOPSIS
    Updates a user group.
    
.PARAMETER GroupId
    The unique identifier of the user group
    
.PARAMETER Name
    New name for the group
    
.EXAMPLE
    Set-UniFiAccessUserGroup -GroupId "group-123" -Name "New Name"
#>
function Set-UniFiAccessUserGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$GroupId,
        
        [Parameter(Mandatory)]
        [string]$Name
    )
    
    $body = @{
        name = $Name
    }
    
    $response = Invoke-UniFiAccessRequest -Method PUT -Endpoint "/user_group/$GroupId" -Body $body
    return $response
}

<#
.SYNOPSIS
    Removes a user group.
    
.PARAMETER GroupId
    The unique identifier of the user group
    
.EXAMPLE
    Remove-UniFiAccessUserGroup -GroupId "group-123"
#>
function Remove-UniFiAccessUserGroup {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory)]
        [string]$GroupId,
        
        [Parameter()]
        [switch]$Force
    )
    
    if ($Force -or $PSCmdlet.ShouldProcess($GroupId, 'Delete user group')) {
        $response = Invoke-UniFiAccessRequest -Method DELETE -Endpoint "/user_group/$GroupId"
        return $response
    }
}

<#
.SYNOPSIS
    Adds a user to a user group.
    
.PARAMETER GroupId
    The unique identifier of the user group
    
.PARAMETER UserId
    The unique identifier of the user
    
.EXAMPLE
    Add-UniFiAccessUserToGroup -GroupId "group-123" -UserId "user-456"
#>
function Add-UniFiAccessUserToGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$GroupId,
        
        [Parameter(Mandatory)]
        [string]$UserId
    )
    
    $body = @{
        user_id = $UserId
    }
    
    $response = Invoke-UniFiAccessRequest -Method POST -Endpoint "/user_group/$GroupId/user" -Body $body
    return $response
}

<#
.SYNOPSIS
    Removes a user from a user group.
    
.PARAMETER GroupId
    The unique identifier of the user group
    
.PARAMETER UserId
    The unique identifier of the user
    
.EXAMPLE
    Remove-UniFiAccessUserFromGroup -GroupId "group-123" -UserId "user-456"
#>
function Remove-UniFiAccessUserFromGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$GroupId,
        
        [Parameter(Mandatory)]
        [string]$UserId
    )
    
    $response = Invoke-UniFiAccessRequest -Method DELETE -Endpoint "/user_group/$GroupId/users/$UserId"
    return $response
}

<#
.SYNOPSIS
    Gets users in a user group.
    
.PARAMETER GroupId
    The unique identifier of the user group
    
.PARAMETER Limit
    Maximum number of results
    
.PARAMETER Offset
    Number of results to skip
    
.EXAMPLE
    Get-UniFiAccessUserGroupMembers -GroupId "group-123"
#>
function Get-UniFiAccessUserGroupMembers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$GroupId,
        
        [Parameter()]
        [int]$Limit,
        
        [Parameter()]
        [int]$Offset
    )
    
    $queryParams = @{}
    if ($PSBoundParameters.ContainsKey('Limit')) { $queryParams.limit = $Limit }
    if ($PSBoundParameters.ContainsKey('Offset')) { $queryParams.offset = $Offset }
    
    $queryString = Get-QueryString -Parameters $queryParams
    $response = Invoke-UniFiAccessRequest -Method GET -Endpoint "/user_group/$GroupId/user$queryString"
    return $response
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    'Connect-UniFiAccess',
    'Disconnect-UniFiAccess',
    'Get-UniFiAccessConnection',
    'New-UniFiAccessUser',
    'Get-UniFiAccessUser',
    'Get-UniFiAccessUsers',
    'Set-UniFiAccessUser',
    'Remove-UniFiAccessUser',
    'Search-UniFiAccessUser',
    'Set-UniFiAccessUserProfilePicture',
    'New-UniFiAccessUserGroup',
    'Get-UniFiAccessUserGroup',
    'Get-UniFiAccessUserGroups',
    'Set-UniFiAccessUserGroup',
    'Remove-UniFiAccessUserGroup',
    'Add-UniFiAccessUserToGroup',
    'Remove-UniFiAccessUserFromGroup',
    'Get-UniFiAccessUserGroupMembers'
)
#region Visitor Management

<#
.SYNOPSIS
    Creates a new visitor.
    
.DESCRIPTION
    Creates a new visitor in the UniFi Access system.
    
.PARAMETER FirstName
    Visitor's first name
    
.PARAMETER LastName
    Visitor's last name
    
.PARAMETER StartTime
    Start time for visitor access (Unix timestamp)
    
.PARAMETER EndTime
    End time for visitor access (Unix timestamp)
    
.EXAMPLE
    New-UniFiAccessVisitor -FirstName "Jane" -LastName "Smith" -StartTime 1640995200 -EndTime 1641081600
#>
function New-UniFiAccessVisitor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FirstName,
        
        [Parameter(Mandatory)]
        [string]$LastName,
        
        [Parameter()]
        [long]$StartTime,
        
        [Parameter()]
        [long]$EndTime,
        
        [Parameter()]
        [string]$Email,
        
        [Parameter()]
        [string]$PhoneNumber,
        
        [Parameter()]
        [ValidateSet('ACTIVE', 'INACTIVE')]
        [string]$Status = 'ACTIVE'
    )
    
    $body = @{
        first_name = $FirstName
        last_name = $LastName
        status = $Status
    }
    
    if ($StartTime) { $body.start_time = $StartTime }
    if ($EndTime) { $body.end_time = $EndTime }
    if ($Email) { $body.email = $Email }
    if ($PhoneNumber) { $body.phone = $PhoneNumber }
    
    $response = Invoke-UniFiAccessRequest -Method POST -Endpoint '/visitor' -Body $body
    return $response
}

<#
.SYNOPSIS
    Gets a specific visitor.
    
.PARAMETER VisitorId
    The unique identifier of the visitor
    
.EXAMPLE
    Get-UniFiAccessVisitor -VisitorId "visitor-123"
#>
function Get-UniFiAccessVisitor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Id')]
        [string]$VisitorId
    )
    
    process {
        $response = Invoke-UniFiAccessRequest -Method GET -Endpoint "/visitor/$VisitorId"
        return $response
    }
}

<#
.SYNOPSIS
    Gets all visitors.
    
.PARAMETER Limit
    Maximum number of results to return
    
.PARAMETER Offset
    Number of results to skip
    
.EXAMPLE
    Get-UniFiAccessVisitors
#>
function Get-UniFiAccessVisitors {
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$Limit,
        
        [Parameter()]
        [int]$Offset
    )
    
    $queryParams = @{}
    if ($PSBoundParameters.ContainsKey('Limit')) { $queryParams.limit = $Limit }
    if ($PSBoundParameters.ContainsKey('Offset')) { $queryParams.offset = $Offset }
    
    $queryString = Get-QueryString -Parameters $queryParams
    $response = Invoke-UniFiAccessRequest -Method GET -Endpoint "/visitor$queryString"
    return $response
}

<#
.SYNOPSIS
    Updates a visitor.
    
.PARAMETER VisitorId
    The unique identifier of the visitor
    
.EXAMPLE
    Set-UniFiAccessVisitor -VisitorId "visitor-123" -Status "INACTIVE"
#>
function Set-UniFiAccessVisitor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Id')]
        [string]$VisitorId,
        
        [Parameter()]
        [string]$FirstName,
        
        [Parameter()]
        [string]$LastName,
        
        [Parameter()]
        [long]$StartTime,
        
        [Parameter()]
        [long]$EndTime,
        
        [Parameter()]
        [ValidateSet('ACTIVE', 'INACTIVE')]
        [string]$Status
    )
    
    process {
        $body = @{}
        
        if ($FirstName) { $body.first_name = $FirstName }
        if ($LastName) { $body.last_name = $LastName }
        if ($StartTime) { $body.start_time = $StartTime }
        if ($EndTime) { $body.end_time = $EndTime }
        if ($Status) { $body.status = $Status }
        
        $response = Invoke-UniFiAccessRequest -Method PUT -Endpoint "/visitor/$VisitorId" -Body $body
        return $response
    }
}

<#
.SYNOPSIS
    Removes a visitor.
    
.PARAMETER VisitorId
    The unique identifier of the visitor
    
.EXAMPLE
    Remove-UniFiAccessVisitor -VisitorId "visitor-123"
#>
function Remove-UniFiAccessVisitor {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Id')]
        [string]$VisitorId,
        
        [Parameter()]
        [switch]$Force
    )
    
    process {
        if ($Force -or $PSCmdlet.ShouldProcess($VisitorId, 'Delete visitor')) {
            $response = Invoke-UniFiAccessRequest -Method DELETE -Endpoint "/visitor/$VisitorId"
            return $response
        }
    }
}

#endregion
#region Access Policy Management

<#
.SYNOPSIS
    Creates a new access policy.
    
.DESCRIPTION
    Creates a new access policy in UniFi Access.
    
.PARAMETER Name
    Name of the access policy
    
.PARAMETER DoorGroupIds
    Array of door group IDs
    
.PARAMETER ScheduleId
    Schedule ID for the policy
    
.EXAMPLE
    New-UniFiAccessPolicy -Name "IT Access" -DoorGroupIds @("dg-123") -ScheduleId "sched-456"
#>
function New-UniFiAccessPolicy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        
        [Parameter()]
        [string[]]$DoorGroupIds,
        
        [Parameter()]
        [string]$ScheduleId
    )
    
    $body = @{
        name = $Name
    }
    
    if ($DoorGroupIds) { $body.door_group_ids = $DoorGroupIds }
    if ($ScheduleId) { $body.schedule_id = $ScheduleId }
    
    $response = Invoke-UniFiAccessRequest -Method POST -Endpoint '/access_policy' -Body $body
    return $response
}

<#
.SYNOPSIS
    Gets a specific access policy.
    
.PARAMETER PolicyId
    The unique identifier of the access policy
    
.EXAMPLE
    Get-UniFiAccessPolicy -PolicyId "policy-123"
#>
function Get-UniFiAccessPolicy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Id')]
        [string]$PolicyId
    )
    
    process {
        $response = Invoke-UniFiAccessRequest -Method GET -Endpoint "/access_policy/$PolicyId"
        return $response
    }
}

<#
.SYNOPSIS
    Gets all access policies.
    
.EXAMPLE
    Get-UniFiAccessPolicies
#>
function Get-UniFiAccessPolicies {
    [CmdletBinding()]
    param()
    
    $response = Invoke-UniFiAccessRequest -Method GET -Endpoint '/access_policy'
    return $response
}

<#
.SYNOPSIS
    Updates an access policy.
    
.PARAMETER PolicyId
    The unique identifier of the access policy
    
.PARAMETER Name
    New name for the policy
    
.EXAMPLE
    Set-UniFiAccessPolicy -PolicyId "policy-123" -Name "Updated Name"
#>
function Set-UniFiAccessPolicy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PolicyId,
        
        [Parameter()]
        [string]$Name,
        
        [Parameter()]
        [string[]]$DoorGroupIds,
        
        [Parameter()]
        [string]$ScheduleId
    )
    
    $body = @{}
    
    if ($Name) { $body.name = $Name }
    if ($DoorGroupIds) { $body.door_group_ids = $DoorGroupIds }
    if ($ScheduleId) { $body.schedule_id = $ScheduleId }
    
    $response = Invoke-UniFiAccessRequest -Method PUT -Endpoint "/access_policy/$PolicyId" -Body $body
    return $response
}

<#
.SYNOPSIS
    Removes an access policy.
    
.PARAMETER PolicyId
    The unique identifier of the access policy
    
.EXAMPLE
    Remove-UniFiAccessPolicy -PolicyId "policy-123"
#>
function Remove-UniFiAccessPolicy {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory)]
        [string]$PolicyId,
        
        [Parameter()]
        [switch]$Force
    )
    
    if ($Force -or $PSCmdlet.ShouldProcess($PolicyId, 'Delete access policy')) {
        $response = Invoke-UniFiAccessRequest -Method DELETE -Endpoint "/access_policy/$PolicyId"
        return $response
    }
}

<#
.SYNOPSIS
    Assigns an access policy to a user.
    
.PARAMETER UserId
    The unique identifier of the user
    
.PARAMETER PolicyId
    The unique identifier of the access policy
    
.EXAMPLE
    Add-UniFiAccessPolicyToUser -UserId "user-123" -PolicyId "policy-456"
#>
function Add-UniFiAccessPolicyToUser {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$UserId,
        
        [Parameter(Mandatory)]
        [string]$PolicyId
    )
    
    $body = @{
        access_policy_id = $PolicyId
    }
    
    $response = Invoke-UniFiAccessRequest -Method POST -Endpoint "/users/$UserId/access_policy" -Body $body
    return $response
}

<#
.SYNOPSIS
    Assigns an access policy to a user group.
    
.PARAMETER GroupId
    The unique identifier of the user group
    
.PARAMETER PolicyId
    The unique identifier of the access policy
    
.EXAMPLE
    Add-UniFiAccessPolicyToUserGroup -GroupId "group-123" -PolicyId "policy-456"
#>
function Add-UniFiAccessPolicyToUserGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$GroupId,
        
        [Parameter(Mandatory)]
        [string]$PolicyId
    )
    
    $body = @{
        access_policy_id = $PolicyId
    }
    
    $response = Invoke-UniFiAccessRequest -Method POST -Endpoint "/user_group/$GroupId/access_policy" -Body $body
    return $response
}

<#
.SYNOPSIS
    Gets access policies assigned to a user.
    
.PARAMETER UserId
    The unique identifier of the user
    
.EXAMPLE
    Get-UniFiAccessUserPolicies -UserId "user-123"
#>
function Get-UniFiAccessUserPolicies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$UserId
    )
    
    $response = Invoke-UniFiAccessRequest -Method GET -Endpoint "/users/$UserId/access_policy"
    return $response
}

<#
.SYNOPSIS
    Gets access policies assigned to a user group.
    
.PARAMETER GroupId
    The unique identifier of the user group
    
.EXAMPLE
    Get-UniFiAccessUserGroupPolicies -GroupId "group-123"
#>
function Get-UniFiAccessUserGroupPolicies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$GroupId
    )
    
    $response = Invoke-UniFiAccessRequest -Method GET -Endpoint "/user_group/$GroupId/access_policy"
    return $response
}

#endregion

#region Schedule Management

<#
.SYNOPSIS
    Creates a new schedule.
    
.PARAMETER Name
    Name of the schedule
    
.PARAMETER Type
    Schedule type (e.g., ALWAYS, CUSTOM)
    
.EXAMPLE
    New-UniFiAccessSchedule -Name "Business Hours" -Type "CUSTOM"
#>
function New-UniFiAccessSchedule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        
        [Parameter()]
        [string]$Type = 'CUSTOM',
        
        [Parameter()]
        [hashtable]$TimeRanges
    )
    
    $body = @{
        name = $Name
        type = $Type
    }
    
    if ($TimeRanges) { $body.time_ranges = $TimeRanges }
    
    $response = Invoke-UniFiAccessRequest -Method POST -Endpoint '/schedule' -Body $body
    return $response
}

<#
.SYNOPSIS
    Gets a specific schedule.
    
.PARAMETER ScheduleId
    The unique identifier of the schedule
    
.EXAMPLE
    Get-UniFiAccessSchedule -ScheduleId "sched-123"
#>
function Get-UniFiAccessSchedule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Id')]
        [string]$ScheduleId
    )
    
    process {
        $response = Invoke-UniFiAccessRequest -Method GET -Endpoint "/schedule/$ScheduleId"
        return $response
    }
}

<#
.SYNOPSIS
    Gets all schedules.
    
.EXAMPLE
    Get-UniFiAccessSchedules
#>
function Get-UniFiAccessSchedules {
    [CmdletBinding()]
    param()
    
    $response = Invoke-UniFiAccessRequest -Method GET -Endpoint '/schedule'
    return $response
}

<#
.SYNOPSIS
    Updates a schedule.
    
.PARAMETER ScheduleId
    The unique identifier of the schedule
    
.PARAMETER Name
    New name for the schedule
    
.EXAMPLE
    Set-UniFiAccessSchedule -ScheduleId "sched-123" -Name "Updated Hours"
#>
function Set-UniFiAccessSchedule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ScheduleId,
        
        [Parameter()]
        [string]$Name,
        
        [Parameter()]
        [hashtable]$TimeRanges
    )
    
    $body = @{}
    
    if ($Name) { $body.name = $Name }
    if ($TimeRanges) { $body.time_ranges = $TimeRanges }
    
    $response = Invoke-UniFiAccessRequest -Method PUT -Endpoint "/schedule/$ScheduleId" -Body $body
    return $response
}

<#
.SYNOPSIS
    Removes a schedule.
    
.PARAMETER ScheduleId
    The unique identifier of the schedule
    
.EXAMPLE
    Remove-UniFiAccessSchedule -ScheduleId "sched-123"
#>
function Remove-UniFiAccessSchedule {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory)]
        [string]$ScheduleId,
        
        [Parameter()]
        [switch]$Force
    )
    
    if ($Force -or $PSCmdlet.ShouldProcess($ScheduleId, 'Delete schedule')) {
        $response = Invoke-UniFiAccessRequest -Method DELETE -Endpoint "/schedule/$ScheduleId"
        return $response
    }
}

#endregion

#region Holiday Group Management

<#
.SYNOPSIS
    Creates a new holiday group.
    
.PARAMETER Name
    Name of the holiday group
    
.PARAMETER Holidays
    Array of holiday definitions
    
.EXAMPLE
    New-UniFiAccessHolidayGroup -Name "Company Holidays"
#>
function New-UniFiAccessHolidayGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        
        [Parameter()]
        [array]$Holidays
    )
    
    $body = @{
        name = $Name
    }
    
    if ($Holidays) { $body.holidays = $Holidays }
    
    $response = Invoke-UniFiAccessRequest -Method POST -Endpoint '/holiday_group' -Body $body
    return $response
}

<#
.SYNOPSIS
    Gets a specific holiday group.
    
.PARAMETER GroupId
    The unique identifier of the holiday group
    
.EXAMPLE
    Get-UniFiAccessHolidayGroup -GroupId "hg-123"
#>
function Get-UniFiAccessHolidayGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Id')]
        [string]$GroupId
    )
    
    process {
        $response = Invoke-UniFiAccessRequest -Method GET -Endpoint "/holiday_group/$GroupId"
        return $response
    }
}

<#
.SYNOPSIS
    Gets all holiday groups.
    
.EXAMPLE
    Get-UniFiAccessHolidayGroups
#>
function Get-UniFiAccessHolidayGroups {
    [CmdletBinding()]
    param()
    
    $response = Invoke-UniFiAccessRequest -Method GET -Endpoint '/holiday_group'
    return $response
}

<#
.SYNOPSIS
    Updates a holiday group.
    
.PARAMETER GroupId
    The unique identifier of the holiday group
    
.PARAMETER Name
    New name for the holiday group
    
.EXAMPLE
    Set-UniFiAccessHolidayGroup -GroupId "hg-123" -Name "Updated Holidays"
#>
function Set-UniFiAccessHolidayGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$GroupId,
        
        [Parameter()]
        [string]$Name,
        
        [Parameter()]
        [array]$Holidays
    )
    
    $body = @{}
    
    if ($Name) { $body.name = $Name }
    if ($Holidays) { $body.holidays = $Holidays }
    
    $response = Invoke-UniFiAccessRequest -Method PUT -Endpoint "/holiday_group/$GroupId" -Body $body
    return $response
}

<#
.SYNOPSIS
    Removes a holiday group.
    
.PARAMETER GroupId
    The unique identifier of the holiday group
    
.EXAMPLE
    Remove-UniFiAccessHolidayGroup -GroupId "hg-123"
#>
function Remove-UniFiAccessHolidayGroup {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory)]
        [string]$GroupId,
        
        [Parameter()]
        [switch]$Force
    )
    
    if ($Force -or $PSCmdlet.ShouldProcess($GroupId, 'Delete holiday group')) {
        $response = Invoke-UniFiAccessRequest -Method DELETE -Endpoint "/holiday_group/$GroupId"
        return $response
    }
}

#endregion
#region Credential Management

#region PIN Codes

<#
.SYNOPSIS
    Generates a new PIN code.
    
.DESCRIPTION
    Generates a random PIN code for use in the system.
    
.EXAMPLE
    New-UniFiAccessPINCode
#>
function New-UniFiAccessPINCode {
    [CmdletBinding()]
    param()
    
    $response = Invoke-UniFiAccessRequest -Method POST -Endpoint '/credential/pin/generate'
    return $response
}

<#
.SYNOPSIS
    Assigns a PIN code to a user.
    
.PARAMETER UserId
    The unique identifier of the user
    
.PARAMETER PINCode
    The PIN code to assign
    
.EXAMPLE
    Add-UniFiAccessPINToUser -UserId "user-123" -PINCode "1234"
#>
function Add-UniFiAccessPINToUser {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$UserId,
        
        [Parameter(Mandatory)]
        [string]$PINCode
    )
    
    $body = @{
        pin_code = $PINCode
    }
    
    $response = Invoke-UniFiAccessRequest -Method POST -Endpoint "/users/$UserId/credential/pin" -Body $body
    return $response
}

<#
.SYNOPSIS
    Removes a PIN code from a user.
    
.PARAMETER UserId
    The unique identifier of the user
    
.EXAMPLE
    Remove-UniFiAccessPINFromUser -UserId "user-123"
#>
function Remove-UniFiAccessPINFromUser {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$UserId
    )
    
    $response = Invoke-UniFiAccessRequest -Method DELETE -Endpoint "/users/$UserId/credential/pin"
    return $response
}

<#
.SYNOPSIS
    Assigns a PIN code to a visitor.
    
.PARAMETER VisitorId
    The unique identifier of the visitor
    
.PARAMETER PINCode
    The PIN code to assign
    
.EXAMPLE
    Add-UniFiAccessPINToVisitor -VisitorId "visitor-123" -PINCode "5678"
#>
function Add-UniFiAccessPINToVisitor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$VisitorId,
        
        [Parameter(Mandatory)]
        [string]$PINCode
    )
    
    $body = @{
        pin_code = $PINCode
    }
    
    $response = Invoke-UniFiAccessRequest -Method POST -Endpoint "/visitor/$VisitorId/credential/pin" -Body $body
    return $response
}

<#
.SYNOPSIS
    Removes a PIN code from a visitor.
    
.PARAMETER VisitorId
    The unique identifier of the visitor
    
.EXAMPLE
    Remove-UniFiAccessPINFromVisitor -VisitorId "visitor-123"
#>
function Remove-UniFiAccessPINFromVisitor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$VisitorId
    )
    
    $response = Invoke-UniFiAccessRequest -Method DELETE -Endpoint "/visitor/$VisitorId/credential/pin"
    return $response
}

#endregion

#region NFC Cards

<#
.SYNOPSIS
    Starts NFC card enrollment.
    
.DESCRIPTION
    Creates a session for enrolling a new NFC card.
    
.PARAMETER DeviceId
    The unique identifier of the device to use for enrollment
    
.EXAMPLE
    New-UniFiAccessNFCEnrollment -DeviceId "device-123"
#>
function New-UniFiAccessNFCEnrollment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DeviceId
    )
    
    $body = @{
        device_id = $DeviceId
    }
    
    $response = Invoke-UniFiAccessRequest -Method POST -Endpoint '/credential/nfc_card/enroll' -Body $body
    return $response
}

<#
.SYNOPSIS
    Gets NFC card enrollment status.
    
.PARAMETER SessionId
    The enrollment session ID
    
.EXAMPLE
    Get-UniFiAccessNFCEnrollmentStatus -SessionId "session-123"
#>
function Get-UniFiAccessNFCEnrollmentStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SessionId
    )
    
    $response = Invoke-UniFiAccessRequest -Method GET -Endpoint "/credential/nfc_card/enroll/$SessionId"
    return $response
}

<#
.SYNOPSIS
    Removes an NFC enrollment session.
    
.PARAMETER SessionId
    The enrollment session ID
    
.EXAMPLE
    Remove-UniFiAccessNFCEnrollmentSession -SessionId "session-123"
#>
function Remove-UniFiAccessNFCEnrollmentSession {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SessionId
    )
    
    $response = Invoke-UniFiAccessRequest -Method DELETE -Endpoint "/credential/nfc_card/enroll/$SessionId"
    return $response
}

<#
.SYNOPSIS
    Gets a specific NFC card.
    
.PARAMETER CardId
    The unique identifier of the NFC card
    
.EXAMPLE
    Get-UniFiAccessNFCCard -CardId "card-123"
#>
function Get-UniFiAccessNFCCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Id')]
        [string]$CardId
    )
    
    process {
        $response = Invoke-UniFiAccessRequest -Method GET -Endpoint "/credential/nfc_card/$CardId"
        return $response
    }
}

<#
.SYNOPSIS
    Gets all NFC cards.
    
.PARAMETER Limit
    Maximum number of results
    
.PARAMETER Offset
    Number of results to skip
    
.EXAMPLE
    Get-UniFiAccessNFCCards
#>
function Get-UniFiAccessNFCCards {
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$Limit,
        
        [Parameter()]
        [int]$Offset
    )
    
    $queryParams = @{}
    if ($PSBoundParameters.ContainsKey('Limit')) { $queryParams.limit = $Limit }
    if ($PSBoundParameters.ContainsKey('Offset')) { $queryParams.offset = $Offset }
    
    $queryString = Get-QueryString -Parameters $queryParams
    $response = Invoke-UniFiAccessRequest -Method GET -Endpoint "/credential/nfc_card$queryString"
    return $response
}

<#
.SYNOPSIS
    Updates an NFC card.
    
.PARAMETER CardId
    The unique identifier of the NFC card
    
.PARAMETER Name
    New name for the card
    
.EXAMPLE
    Set-UniFiAccessNFCCard -CardId "card-123" -Name "Employee Badge"
#>
function Set-UniFiAccessNFCCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$CardId,
        
        [Parameter()]
        [string]$Name
    )
    
    $body = @{}
    if ($Name) { $body.name = $Name }
    
    $response = Invoke-UniFiAccessRequest -Method PUT -Endpoint "/credential/nfc_card/$CardId" -Body $body
    return $response
}

<#
.SYNOPSIS
    Removes an NFC card.
    
.PARAMETER CardId
    The unique identifier of the NFC card
    
.EXAMPLE
    Remove-UniFiAccessNFCCard -CardId "card-123"
#>
function Remove-UniFiAccessNFCCard {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory)]
        [string]$CardId,
        
        [Parameter()]
        [switch]$Force
    )
    
    if ($Force -or $PSCmdlet.ShouldProcess($CardId, 'Delete NFC card')) {
        $response = Invoke-UniFiAccessRequest -Method DELETE -Endpoint "/credential/nfc_card/$CardId"
        return $response
    }
}

<#
.SYNOPSIS
    Assigns an NFC card to a user.
    
.PARAMETER UserId
    The unique identifier of the user
    
.PARAMETER CardId
    The unique identifier of the NFC card
    
.EXAMPLE
    Add-UniFiAccessNFCCardToUser -UserId "user-123" -CardId "card-456"
#>
function Add-UniFiAccessNFCCardToUser {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$UserId,
        
        [Parameter(Mandatory)]
        [string]$CardId
    )
    
    $body = @{
        nfc_card_id = $CardId
    }
    
    $response = Invoke-UniFiAccessRequest -Method POST -Endpoint "/users/$UserId/credential/nfc_card" -Body $body
    return $response
}

<#
.SYNOPSIS
    Removes an NFC card from a user.
    
.PARAMETER UserId
    The unique identifier of the user
    
.EXAMPLE
    Remove-UniFiAccessNFCCardFromUser -UserId "user-123"
#>
function Remove-UniFiAccessNFCCardFromUser {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$UserId
    )
    
    $response = Invoke-UniFiAccessRequest -Method DELETE -Endpoint "/users/$UserId/credential/nfc_card"
    return $response
}

<#
.SYNOPSIS
    Assigns an NFC card to a visitor.
    
.PARAMETER VisitorId
    The unique identifier of the visitor
    
.PARAMETER CardId
    The unique identifier of the NFC card
    
.EXAMPLE
    Add-UniFiAccessNFCCardToVisitor -VisitorId "visitor-123" -CardId "card-456"
#>
function Add-UniFiAccessNFCCardToVisitor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$VisitorId,
        
        [Parameter(Mandatory)]
        [string]$CardId
    )
    
    $body = @{
        nfc_card_id = $CardId
    }
    
    $response = Invoke-UniFiAccessRequest -Method POST -Endpoint "/visitor/$VisitorId/credential/nfc_card" -Body $body
    return $response
}

<#
.SYNOPSIS
    Removes an NFC card from a visitor.
    
.PARAMETER VisitorId
    The unique identifier of the visitor
    
.EXAMPLE
    Remove-UniFiAccessNFCCardFromVisitor -VisitorId "visitor-123"
#>
function Remove-UniFiAccessNFCCardFromVisitor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$VisitorId
    )
    
    $response = Invoke-UniFiAccessRequest -Method DELETE -Endpoint "/visitor/$VisitorId/credential/nfc_card"
    return $response
}

<#
.SYNOPSIS
    Imports third-party NFC cards.
    
.PARAMETER Cards
    Array of card objects to import
    
.EXAMPLE
    Import-UniFiAccessThirdPartyNFCCard -Cards @(@{card_number="123456"; name="Card 1"})
#>
function Import-UniFiAccessThirdPartyNFCCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$Cards
    )
    
    $body = @{
        cards = $Cards
    }
    
    $response = Invoke-UniFiAccessRequest -Method POST -Endpoint '/credential/nfc_card/import' -Body $body
    return $response
}

#endregion

#region Touch Pass

<#
.SYNOPSIS
    Gets the Touch Pass list.
    
.EXAMPLE
    Get-UniFiAccessTouchPass
#>
function Get-UniFiAccessTouchPass {
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$Limit,
        
        [Parameter()]
        [int]$Offset
    )
    
    $queryParams = @{}
    if ($PSBoundParameters.ContainsKey('Limit')) { $queryParams.limit = $Limit }
    if ($PSBoundParameters.ContainsKey('Offset')) { $queryParams.offset = $Offset }
    
    $queryString = Get-QueryString -Parameters $queryParams
    $response = Invoke-UniFiAccessRequest -Method GET -Endpoint "/credential/touchpass$queryString"
    return $response
}

<#
.SYNOPSIS
    Gets all Touch Passes.
    
.EXAMPLE
    Get-UniFiAccessTouchPasses
#>
function Get-UniFiAccessTouchPasses {
    [CmdletBinding()]
    param()
    
    $response = Invoke-UniFiAccessRequest -Method GET -Endpoint '/credential/touchpass'
    return $response
}

<#
.SYNOPSIS
    Searches for Touch Passes.
    
.PARAMETER Query
    Search query
    
.EXAMPLE
    Search-UniFiAccessTouchPass -Query "employee"
#>
function Search-UniFiAccessTouchPass {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Query
    )
    
    $queryParams = @{ query = $Query }
    $queryString = Get-QueryString -Parameters $queryParams
    $response = Invoke-UniFiAccessRequest -Method GET -Endpoint "/credential/touchpass/search$queryString"
    return $response
}

<#
.SYNOPSIS
    Gets assignable Touch Passes.
    
.EXAMPLE
    Get-UniFiAccessAssignableTouchPasses
#>
function Get-UniFiAccessAssignableTouchPasses {
    [CmdletBinding()]
    param()
    
    $response = Invoke-UniFiAccessRequest -Method GET -Endpoint '/credential/touchpass/assignable'
    return $response
}

<#
.SYNOPSIS
    Updates a Touch Pass.
    
.PARAMETER TouchPassId
    The unique identifier of the Touch Pass
    
.PARAMETER Name
    New name for the Touch Pass
    
.EXAMPLE
    Set-UniFiAccessTouchPass -TouchPassId "tp-123" -Name "Updated Pass"
#>
function Set-UniFiAccessTouchPass {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TouchPassId,
        
        [Parameter()]
        [string]$Name
    )
    
    $body = @{}
    if ($Name) { $body.name = $Name }
    
    $response = Invoke-UniFiAccessRequest -Method PUT -Endpoint "/credential/touchpass/$TouchPassId" -Body $body
    return $response
}

<#
.SYNOPSIS
    Gets Touch Pass details.
    
.PARAMETER TouchPassId
    The unique identifier of the Touch Pass
    
.EXAMPLE
    Get-UniFiAccessTouchPassDetails -TouchPassId "tp-123"
#>
function Get-UniFiAccessTouchPassDetails {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TouchPassId
    )
    
    $response = Invoke-UniFiAccessRequest -Method GET -Endpoint "/credential/touchpass/$TouchPassId"
    return $response
}

<#
.SYNOPSIS
    Purchases Touch Passes.
    
.PARAMETER Quantity
    Number of Touch Passes to purchase
    
.EXAMPLE
    New-UniFiAccessTouchPassPurchase -Quantity 10
#>
function New-UniFiAccessTouchPassPurchase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$Quantity
    )
    
    $body = @{
        quantity = $Quantity
    }
    
    $response = Invoke-UniFiAccessRequest -Method POST -Endpoint '/credential/touchpass/purchase' -Body $body
    return $response
}

<#
.SYNOPSIS
    Assigns a Touch Pass to a user.
    
.PARAMETER UserId
    The unique identifier of the user
    
.PARAMETER TouchPassId
    The unique identifier of the Touch Pass
    
.EXAMPLE
    Add-UniFiAccessTouchPassToUser -UserId "user-123" -TouchPassId "tp-456"
#>
function Add-UniFiAccessTouchPassToUser {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$UserId,
        
        [Parameter(Mandatory)]
        [string]$TouchPassId
    )
    
    $body = @{
        touchpass_id = $TouchPassId
    }
    
    $response = Invoke-UniFiAccessRequest -Method POST -Endpoint "/users/$UserId/credential/touchpass" -Body $body
    return $response
}

<#
.SYNOPSIS
    Removes a Touch Pass from a user.
    
.PARAMETER UserId
    The unique identifier of the user
    
.EXAMPLE
    Remove-UniFiAccessTouchPassFromUser -UserId "user-123"
#>
function Remove-UniFiAccessTouchPassFromUser {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$UserId
    )
    
    $response = Invoke-UniFiAccessRequest -Method DELETE -Endpoint "/users/$UserId/credential/touchpass"
    return $response
}

<#
.SYNOPSIS
    Batch assigns Touch Passes to users.
    
.PARAMETER Assignments
    Array of user ID and Touch Pass ID pairs
    
.EXAMPLE
    Add-UniFiAccessTouchPassesToUsers -Assignments @(@{user_id="user-1"; touchpass_id="tp-1"})
#>
function Add-UniFiAccessTouchPassesToUsers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$Assignments
    )
    
    $body = @{
        assignments = $Assignments
    }
    
    $response = Invoke-UniFiAccessRequest -Method POST -Endpoint '/users/credential/touchpass/batch' -Body $body
    return $response
}

#endregion

#region License Plates

<#
.SYNOPSIS
    Assigns license plate numbers to a user.
    
.PARAMETER UserId
    The unique identifier of the user
    
.PARAMETER LicensePlates
    Array of license plate numbers
    
.EXAMPLE
    Add-UniFiAccessLicensePlateToUser -UserId "user-123" -LicensePlates @("ABC123", "XYZ789")
#>
function Add-UniFiAccessLicensePlateToUser {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$UserId,
        
        [Parameter(Mandatory)]
        [string[]]$LicensePlates
    )
    
    $body = @{
        license_plates = $LicensePlates
    }
    
    $response = Invoke-UniFiAccessRequest -Method POST -Endpoint "/users/$UserId/credential/license_plate" -Body $body
    return $response
}

<#
.SYNOPSIS
    Removes license plate numbers from a user.
    
.PARAMETER UserId
    The unique identifier of the user
    
.PARAMETER LicensePlates
    Array of license plate numbers to remove
    
.EXAMPLE
    Remove-UniFiAccessLicensePlateFromUser -UserId "user-123" -LicensePlates @("ABC123")
#>
function Remove-UniFiAccessLicensePlateFromUser {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$UserId,
        
        [Parameter(Mandatory)]
        [string[]]$LicensePlates
    )
    
    $body = @{
        license_plates = $LicensePlates
    }
    
    $response = Invoke-UniFiAccessRequest -Method DELETE -Endpoint "/users/$UserId/credential/license_plate" -Body $body
    return $response
}

<#
.SYNOPSIS
    Assigns license plate numbers to a visitor.
    
.PARAMETER VisitorId
    The unique identifier of the visitor
    
.PARAMETER LicensePlates
    Array of license plate numbers
    
.EXAMPLE
    Add-UniFiAccessLicensePlateToVisitor -VisitorId "visitor-123" -LicensePlates @("ABC123")
#>
function Add-UniFiAccessLicensePlateToVisitor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$VisitorId,
        
        [Parameter(Mandatory)]
        [string[]]$LicensePlates
    )
    
    $body = @{
        license_plates = $LicensePlates
    }
    
    $response = Invoke-UniFiAccessRequest -Method POST -Endpoint "/visitor/$VisitorId/credential/license_plate" -Body $body
    return $response
}

<#
.SYNOPSIS
    Removes license plate numbers from a visitor.
    
.PARAMETER VisitorId
    The unique identifier of the visitor
    
.PARAMETER LicensePlates
    Array of license plate numbers to remove
    
.EXAMPLE
    Remove-UniFiAccessLicensePlateFromVisitor -VisitorId "visitor-123" -LicensePlates @("ABC123")
#>
function Remove-UniFiAccessLicensePlateFromVisitor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$VisitorId,
        
        [Parameter(Mandatory)]
        [string[]]$LicensePlates
    )
    
    $body = @{
        license_plates = $LicensePlates
    }
    
    $response = Invoke-UniFiAccessRequest -Method DELETE -Endpoint "/visitor/$VisitorId/credential/license_plate" -Body $body
    return $response
}

#endregion

#region QR Codes

<#
.SYNOPSIS
    Assigns a QR code to a visitor.
    
.PARAMETER VisitorId
    The unique identifier of the visitor
    
.EXAMPLE
    Add-UniFiAccessQRCodeToVisitor -VisitorId "visitor-123"
#>
function Add-UniFiAccessQRCodeToVisitor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$VisitorId
    )
    
    $response = Invoke-UniFiAccessRequest -Method POST -Endpoint "/visitor/$VisitorId/credential/qr_code"
    return $response
}

<#
.SYNOPSIS
    Removes a QR code from a visitor.
    
.PARAMETER VisitorId
    The unique identifier of the visitor
    
.EXAMPLE
    Remove-UniFiAccessQRCodeFromVisitor -VisitorId "visitor-123"
#>
function Remove-UniFiAccessQRCodeFromVisitor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$VisitorId
    )
    
    $response = Invoke-UniFiAccessRequest -Method DELETE -Endpoint "/visitor/$VisitorId/credential/qr_code"
    return $response
}

<#
.SYNOPSIS
    Downloads a QR code image.
    
.PARAMETER UserId
    The unique identifier of the user
    
.PARAMETER OutputPath
    Path to save the QR code image
    
.EXAMPLE
    Get-UniFiAccessQRCodeImage -UserId "user-123" -OutputPath "C:\qrcode.png"
#>
function Get-UniFiAccessQRCodeImage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$UserId,
        
        [Parameter(Mandatory)]
        [string]$OutputPath
    )
    
    # Note: This would require binary file handling
    throw "QR code image download requires binary file handling implementation"
}

#endregion

#endregion
#region Door Management

<#
.SYNOPSIS
    Gets a specific door.
    
.PARAMETER DoorId
    The unique identifier of the door
    
.EXAMPLE
    Get-UniFiAccessDoor -DoorId "door-123"
#>
function Get-UniFiAccessDoor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Id')]
        [string]$DoorId
    )
    
    process {
        $response = Invoke-UniFiAccessRequest -Method GET -Endpoint "/door/$DoorId"
        return $response
    }
}

<#
.SYNOPSIS
    Gets all doors.
    
.PARAMETER Limit
    Maximum number of results
    
.PARAMETER Offset
    Number of results to skip
    
.EXAMPLE
    Get-UniFiAccessDoors
#>
function Get-UniFiAccessDoors {
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$Limit,
        
        [Parameter()]
        [int]$Offset
    )
    
    $queryParams = @{}
    if ($PSBoundParameters.ContainsKey('Limit')) { $queryParams.limit = $Limit }
    if ($PSBoundParameters.ContainsKey('Offset')) { $queryParams.offset = $Offset }
    
    $queryString = Get-QueryString -Parameters $queryParams
    $response = Invoke-UniFiAccessRequest -Method GET -Endpoint "/door$queryString"
    return $response
}

<#
.SYNOPSIS
    Unlocks a door remotely.
    
.DESCRIPTION
    Remotely unlocks a door with optional actor information for logging.
    
.PARAMETER DoorId
    The unique identifier of the door
    
.PARAMETER ActorId
    Optional actor ID for logging (defaults to token name)
    
.PARAMETER ActorName
    Optional actor name for logging
    
.PARAMETER Extra
    Optional extra data for webhook
    
.EXAMPLE
    Unlock-UniFiAccessDoor -DoorId "door-123"
    
.EXAMPLE
    Unlock-UniFiAccessDoor -DoorId "door-123" -ActorId "admin-001" -ActorName "System Admin"
#>
function Unlock-UniFiAccessDoor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Id')]
        [string]$DoorId,
        
        [Parameter()]
        [string]$ActorId,
        
        [Parameter()]
        [string]$ActorName,
        
        [Parameter()]
        [hashtable]$Extra
    )
    
    process {
        $body = @{}
        
        if ($ActorId) { $body.actor_id = $ActorId }
        if ($ActorName) { $body.actor_name = $ActorName }
        if ($Extra) { $body.extra = $Extra }
        
        $endpoint = "/door/$DoorId/unlock"
        
        if ($body.Count -eq 0) {
            $response = Invoke-UniFiAccessRequest -Method POST -Endpoint $endpoint
        } else {
            $response = Invoke-UniFiAccessRequest -Method POST -Endpoint $endpoint -Body $body
        }
        
        return $response
    }
}

<#
.SYNOPSIS
    Sets temporary unlock for a door.
    
.DESCRIPTION
    Configures temporary unlock mode for compatible devices (EAH8, UA-Hub-Door-Mini, UA-Ultra).
    
.PARAMETER DoorId
    The unique identifier of the door
    
.PARAMETER Duration
    Duration in seconds for the temporary unlock
    
.EXAMPLE
    Set-UniFiAccessDoorTemporaryUnlock -DoorId "door-123" -Duration 300
#>
function Set-UniFiAccessDoorTemporaryUnlock {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DoorId,
        
        [Parameter(Mandatory)]
        [int]$Duration
    )
    
    $body = @{
        duration = $Duration
    }
    
    $response = Invoke-UniFiAccessRequest -Method POST -Endpoint "/door/$DoorId/temporary_unlock" -Body $body
    return $response
}

<#
.SYNOPSIS
    Gets door lock status.
    
.PARAMETER DoorId
    The unique identifier of the door
    
.EXAMPLE
    Get-UniFiAccessDoorLockStatus -DoorId "door-123"
#>
function Get-UniFiAccessDoorLockStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Id')]
        [string]$DoorId
    )
    
    process {
        $response = Invoke-UniFiAccessRequest -Method GET -Endpoint "/door/$DoorId/lock_status"
        return $response
    }
}

#endregion

#region Door Group Management

<#
.SYNOPSIS
    Gets door group topology.
    
.DESCRIPTION
    Retrieves the hierarchical structure of door groups.
    
.EXAMPLE
    Get-UniFiAccessDoorGroupTopology
#>
function Get-UniFiAccessDoorGroupTopology {
    [CmdletBinding()]
    param()
    
    $response = Invoke-UniFiAccessRequest -Method GET -Endpoint '/door_group/topology'
    return $response
}

<#
.SYNOPSIS
    Creates a new door group.
    
.PARAMETER Name
    Name of the door group
    
.PARAMETER ParentId
    Optional parent door group ID
    
.PARAMETER DoorIds
    Array of door IDs to include in the group
    
.EXAMPLE
    New-UniFiAccessDoorGroup -Name "Main Building" -DoorIds @("door-1", "door-2")
#>
function New-UniFiAccessDoorGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        
        [Parameter()]
        [string]$ParentId,
        
        [Parameter()]
        [string[]]$DoorIds
    )
    
    $body = @{
        name = $Name
    }
    
    if ($ParentId) { $body.parent_id = $ParentId }
    if ($DoorIds) { $body.door_ids = $DoorIds }
    
    $response = Invoke-UniFiAccessRequest -Method POST -Endpoint '/door_group' -Body $body
    return $response
}

<#
.SYNOPSIS
    Gets a specific door group.
    
.PARAMETER GroupId
    The unique identifier of the door group
    
.EXAMPLE
    Get-UniFiAccessDoorGroup -GroupId "dg-123"
#>
function Get-UniFiAccessDoorGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Id')]
        [string]$GroupId
    )
    
    process {
        $response = Invoke-UniFiAccessRequest -Method GET -Endpoint "/door_group/$GroupId"
        return $response
    }
}

<#
.SYNOPSIS
    Gets all door groups.
    
.EXAMPLE
    Get-UniFiAccessDoorGroups
#>
function Get-UniFiAccessDoorGroups {
    [CmdletBinding()]
    param()
    
    $response = Invoke-UniFiAccessRequest -Method GET -Endpoint '/door_group'
    return $response
}

<#
.SYNOPSIS
    Updates a door group.
    
.PARAMETER GroupId
    The unique identifier of the door group
    
.PARAMETER Name
    New name for the door group
    
.PARAMETER DoorIds
    Updated array of door IDs
    
.EXAMPLE
    Set-UniFiAccessDoorGroup -GroupId "dg-123" -Name "Updated Name"
#>
function Set-UniFiAccessDoorGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$GroupId,
        
        [Parameter()]
        [string]$Name,
        
        [Parameter()]
        [string[]]$DoorIds
    )
    
    $body = @{}
    
    if ($Name) { $body.name = $Name }
    if ($DoorIds) { $body.door_ids = $DoorIds }
    
    $response = Invoke-UniFiAccessRequest -Method PUT -Endpoint "/door_group/$GroupId" -Body $body
    return $response
}

<#
.SYNOPSIS
    Removes a door group.
    
.PARAMETER GroupId
    The unique identifier of the door group
    
.EXAMPLE
    Remove-UniFiAccessDoorGroup -GroupId "dg-123"
#>
function Remove-UniFiAccessDoorGroup {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory)]
        [string]$GroupId,
        
        [Parameter()]
        [switch]$Force
    )
    
    if ($Force -or $PSCmdlet.ShouldProcess($GroupId, 'Delete door group')) {
        $response = Invoke-UniFiAccessRequest -Method DELETE -Endpoint "/door_group/$GroupId"
        return $response
    }
}

#endregion
#region Device Management

<#
.SYNOPSIS
    Gets a specific device.
    
.PARAMETER DeviceId
    The unique identifier of the device
    
.EXAMPLE
    Get-UniFiAccessDevice -DeviceId "device-123"
#>
function Get-UniFiAccessDevice {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Id')]
        [string]$DeviceId
    )
    
    process {
        $response = Invoke-UniFiAccessRequest -Method GET -Endpoint "/device/$DeviceId"
        return $response
    }
}

<#
.SYNOPSIS
    Gets all devices.
    
.PARAMETER Limit
    Maximum number of results
    
.PARAMETER Offset
    Number of results to skip
    
.EXAMPLE
    Get-UniFiAccessDevices
#>
function Get-UniFiAccessDevices {
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$Limit,
        
        [Parameter()]
        [int]$Offset
    )
    
    $queryParams = @{}
    if ($PSBoundParameters.ContainsKey('Limit')) { $queryParams.limit = $Limit }
    if ($PSBoundParameters.ContainsKey('Offset')) { $queryParams.offset = $Offset }
    
    $queryString = Get-QueryString -Parameters $queryParams
    $response = Invoke-UniFiAccessRequest -Method GET -Endpoint "/device$queryString"
    return $response
}

<#
.SYNOPSIS
    Gets device access method settings.
    
.PARAMETER DeviceId
    The unique identifier of the device
    
.EXAMPLE
    Get-UniFiAccessDeviceAccessMethod -DeviceId "device-123"
#>
function Get-UniFiAccessDeviceAccessMethod {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DeviceId
    )
    
    $response = Invoke-UniFiAccessRequest -Method GET -Endpoint "/device/$DeviceId/access_method"
    return $response
}

<#
.SYNOPSIS
    Updates device access method settings.
    
.PARAMETER DeviceId
    The unique identifier of the device
    
.PARAMETER AccessMethods
    Hashtable of access method settings
    
.EXAMPLE
    Set-UniFiAccessDeviceAccessMethod -DeviceId "device-123" -AccessMethods @{nfc=$true; pin=$true}
#>
function Set-UniFiAccessDeviceAccessMethod {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DeviceId,
        
        [Parameter(Mandatory)]
        [hashtable]$AccessMethods
    )
    
    $response = Invoke-UniFiAccessRequest -Method PUT -Endpoint "/device/$DeviceId/access_method" -Body $AccessMethods
    return $response
}

#endregion

#region Logs

<#
.SYNOPSIS
    Gets access logs.
    
.DESCRIPTION
    Retrieves access logs with optional filtering.
    
.PARAMETER StartTime
    Start time for log query (Unix timestamp)
    
.PARAMETER EndTime
    End time for log query (Unix timestamp)
    
.PARAMETER Limit
    Maximum number of results
    
.PARAMETER Offset
    Number of results to skip
    
.PARAMETER Type
    Log type filter
    
.EXAMPLE
    Get-UniFiAccessLogs -StartTime 1640995200 -EndTime 1641081600
    
.EXAMPLE
    Get-UniFiAccessLogs -Limit 100
#>
function Get-UniFiAccessLogs {
    [CmdletBinding()]
    param(
        [Parameter()]
        [long]$StartTime,
        
        [Parameter()]
        [long]$EndTime,
        
        [Parameter()]
        [int]$Limit,
        
        [Parameter()]
        [int]$Offset,
        
        [Parameter()]
        [string]$Type,
        
        [Parameter()]
        [string]$UserId,
        
        [Parameter()]
        [string]$DoorId
    )
    
    $queryParams = @{}
    
    if ($PSBoundParameters.ContainsKey('StartTime')) { $queryParams.start_time = $StartTime }
    if ($PSBoundParameters.ContainsKey('EndTime')) { $queryParams.end_time = $EndTime }
    if ($PSBoundParameters.ContainsKey('Limit')) { $queryParams.limit = $Limit }
    if ($PSBoundParameters.ContainsKey('Offset')) { $queryParams.offset = $Offset }
    if ($Type) { $queryParams.type = $Type }
    if ($UserId) { $queryParams.user_id = $UserId }
    if ($DoorId) { $queryParams.door_id = $DoorId }
    
    $queryString = Get-QueryString -Parameters $queryParams
    $response = Invoke-UniFiAccessRequest -Method GET -Endpoint "/log$queryString"
    return $response
}

#endregion

#region Webhook Management

<#
.SYNOPSIS
    Creates a new webhook.
    
.DESCRIPTION
    Creates a webhook subscription for UniFi Access events.
    
.PARAMETER Url
    The webhook URL endpoint
    
.PARAMETER Events
    Array of event types to subscribe to
    
.PARAMETER Name
    Optional name for the webhook
    
.PARAMETER Secret
    Optional secret for webhook signature verification
    
.PARAMETER CustomHeaders
    Optional custom headers to include in webhook requests
    
.EXAMPLE
    New-UniFiAccessWebhook -Url "https://example.com/webhook" -Events @("access.granted", "access.denied")
    
.EXAMPLE
    New-UniFiAccessWebhook -Url "https://example.com/webhook" -Name "My Webhook" -Events @("access.granted") -Secret "mysecret"
#>
function New-UniFiAccessWebhook {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Url,
        
        [Parameter(Mandatory)]
        [string[]]$Events,
        
        [Parameter()]
        [string]$Name,
        
        [Parameter()]
        [string]$Secret,
        
        [Parameter()]
        [hashtable]$CustomHeaders
    )
    
    $body = @{
        url = $Url
        events = $Events
    }
    
    if ($Name) { $body.name = $Name }
    if ($Secret) { $body.secret = $Secret }
    if ($CustomHeaders) { $body.custom_headers = $CustomHeaders }
    
    $response = Invoke-UniFiAccessRequest -Method POST -Endpoint '/webhook' -Body $body
    return $response
}

<#
.SYNOPSIS
    Gets a specific webhook.
    
.PARAMETER WebhookId
    The unique identifier of the webhook
    
.EXAMPLE
    Get-UniFiAccessWebhook -WebhookId "webhook-123"
#>
function Get-UniFiAccessWebhook {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Id')]
        [string]$WebhookId
    )
    
    process {
        $response = Invoke-UniFiAccessRequest -Method GET -Endpoint "/webhook/$WebhookId"
        return $response
    }
}

<#
.SYNOPSIS
    Gets all webhooks.
    
.EXAMPLE
    Get-UniFiAccessWebhooks
#>
function Get-UniFiAccessWebhooks {
    [CmdletBinding()]
    param()
    
    $response = Invoke-UniFiAccessRequest -Method GET -Endpoint '/webhook'
    return $response
}

<#
.SYNOPSIS
    Updates a webhook.
    
.PARAMETER WebhookId
    The unique identifier of the webhook
    
.PARAMETER Url
    New webhook URL
    
.PARAMETER Events
    Updated array of event types
    
.PARAMETER Name
    New name for the webhook
    
.PARAMETER Secret
    New secret for webhook verification
    
.PARAMETER CustomHeaders
    Updated custom headers
    
.EXAMPLE
    Set-UniFiAccessWebhook -WebhookId "webhook-123" -Url "https://newurl.com/webhook"
#>
function Set-UniFiAccessWebhook {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$WebhookId,
        
        [Parameter()]
        [string]$Url,
        
        [Parameter()]
        [string[]]$Events,
        
        [Parameter()]
        [string]$Name,
        
        [Parameter()]
        [string]$Secret,
        
        [Parameter()]
        [hashtable]$CustomHeaders
    )
    
    $body = @{}
    
    if ($Url) { $body.url = $Url }
    if ($Events) { $body.events = $Events }
    if ($Name) { $body.name = $Name }
    if ($Secret) { $body.secret = $Secret }
    if ($CustomHeaders) { $body.custom_headers = $CustomHeaders }
    
    $response = Invoke-UniFiAccessRequest -Method PUT -Endpoint "/webhook/$WebhookId" -Body $body
    return $response
}

<#
.SYNOPSIS
    Removes a webhook.
    
.PARAMETER WebhookId
    The unique identifier of the webhook
    
.EXAMPLE
    Remove-UniFiAccessWebhook -WebhookId "webhook-123"
#>
function Remove-UniFiAccessWebhook {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory)]
        [string]$WebhookId,
        
        [Parameter()]
        [switch]$Force
    )
    
    if ($Force -or $PSCmdlet.ShouldProcess($WebhookId, 'Delete webhook')) {
        $response = Invoke-UniFiAccessRequest -Method DELETE -Endpoint "/webhook/$WebhookId"
        return $response
    }
}

<#
.SYNOPSIS
    Tests a webhook.
    
.DESCRIPTION
    Sends a test event to a webhook endpoint.
    
.PARAMETER WebhookId
    The unique identifier of the webhook
    
.EXAMPLE
    Test-UniFiAccessWebhook -WebhookId "webhook-123"
#>
function Test-UniFiAccessWebhook {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$WebhookId
    )
    
    $response = Invoke-UniFiAccessRequest -Method POST -Endpoint "/webhook/$WebhookId/test"
    return $response
}

<#
.SYNOPSIS
    Gets available webhook event types.
    
.DESCRIPTION
    Returns a list of all event types that can be subscribed to via webhooks.
    
.EXAMPLE
    Get-UniFiAccessWebhookEvents
#>
function Get-UniFiAccessWebhookEvents {
    [CmdletBinding()]
    param()
    
    $response = Invoke-UniFiAccessRequest -Method GET -Endpoint '/webhook/events'
    return $response
}

#endregion

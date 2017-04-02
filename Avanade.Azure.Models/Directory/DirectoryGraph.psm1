using module .\Entities.psm1
using module .\Events.psm1

Class GraphDomain
{
    [string]$AuthenticationType
    [string]$AvailabilityStatus
    [string]$ForceDeleteState
    [bool]$IsAdminManaged
    [bool]$IsDefault
    [bool]$IsInitial
    [bool]$IsRoot
    [bool]$IsVerified
    [string]$Name
    [string]$State
    [string[]]$SupportedServices
}

Class GraphTenantBase
{
    [string]$TenantId

    hidden [bool]IsVerbose()
    {
        return $PSCmdlet.MyInvocation -and $PSCmdlet.MyInvocation.BoundParameters['Verbose'] -and $PSCmdlet.MyInvocation.BoundParameters['Verbose']
    }

    [GraphDomain[]]Domains([string]$AccessToken)
    {
        throw "This must be overloaded in an implementing class"
    }
    [GraphSigninEvent[]]SigninEvents([string]$AccessToken,[datetime]$Start,[datetime]$End)
    {
        throw "This must be overloaded in an implementing class"
    }
    [GraphAuditEvent[]]AuditEvents([string]$AccessToken,[datetime]$Start,[datetime]$End)
    {
        throw "This must be overloaded in an implementing class"
    }
    [GraphDirectoryGroup[]]Groups([string]$AccessToken)
    {
        throw "This must be overloaded in an implementing class"
    }
    [GraphDirectoryUser[]]Users([string]$AccessToken)
    {
        throw "This must be overloaded in an implementing class"
    }
    [GraphDirectoryRole[]]Roles([string]$AccessToken)
    {
        throw "This must be overloaded in an implementing class"
    }
    [GraphDirectoryRoleTemplate[]]RoleTemplates([string]$AccessToken)
    {
        throw "This must be overloaded in an implementing class"
    }
    [GraphOauth2PermissionGrant[]]OauthPermissionGrants([string]$AccessToken)
    {
        throw "This must be overloaded in an implementing class"
    }
    [GraphDirectoryServicePrincipal[]]ServicePrincipals([string]$AccessToken)
    {
        throw "This must be overloaded in an implementing class"
    }

    [GraphDirectoryApplication[]]Applications([string]$AccessToken)
    {
        throw "This must be overloaded in an implementing class"
    }
}

Class GraphDirectoryUser:GraphDirectoryObject
{
    [bool]$AccountEnabled
    [Object[]]$AlternativeSignInNamesInfo
    [GraphUserLicense[]]$AssignedLicenses
    [GraphUserPlan[]]$AssignedPlans
    [object]$City
    [object]$CompanyName
    [object]$Country
    [object]$CreationType
    [object]$Department
    [object]$FacsimileTelephoneNumber
    [string]$GivenName
    [string]$ImmutableId
    [object]$IsCompromised
    [object]$JobTitle
    [object]$Mobile
    [string[]]$OtherMails
    [string]$PasswordPolicies
    [GraphPasswordProfile]$PasswordProfile
    [string]$PhysicalDeliveryOfficeName
    [string]$PostalCode
    [string]$PreferredLanguage
    [GraphProvisionedPlan[]]$ProvisionedPlans
    [string]$SipProxyAddress
    [string]$State
    [string]$StreetAddress
    [string]$Surname
    [string]$TelephoneNumber
    [string]${ThumbnailPhoto@odata.mediaEditLink}
    [string]$UsageLocation
    [string]$UserPrincipalName
    [string]$UserType
}

Class GraphDirectoryGroup:GraphDirectoryObject
{
    [bool]$MailEnabled
    [bool]$SecurityEnabled
}

Class GraphDirectoryPrinicipal:GraphDirectoryItem
{
    [object[]]$AddIns
    [string]$AppId
    [object[]]$AppRoles
    [Uri]$ErrorUrl
    [object[]]$KeyCredentials
    [Uri]$HomePage
    [Uri]$LogoutUrl
    [object[]]$Oauth2Permissions
    [object[]]$PasswordCredentials
    [Uri[]]$ReplyUrls
    [Uri]$SamlMetadataUrl
    [object[]]$RequiredResourceAccess    
}

Class GraphDirectoryApplication:GraphDirectoryPrinicipal
{
    [object[]]$AddIns
    [string]$AppId
    [object[]]$AppRoles
    [bool]$AvailableToOtherTenants
    [object[]]$GroupMembershipClaims
    [Uri[]]$IdentifierUris
    [object[]]$KnownClientApplications
    [bool]$Oauth2AllowImplicitFlow
    [bool]$Oauth2AllowUrlPathMatching
    [bool]$Oauth2RequirePostResponse
    [bool]$PublicClient
    [string]${MainLogo@odata.mediaContentType}
}

Class GraphDirectoryServicePrincipal:GraphDirectoryPrinicipal
{
    [bool]$AccountEnabled
    [object[]]$AlternativeNames
    [string]$AppDisplayName
    [string]$AppOwnerTenantId
    [bool]$AppRoleAssignmentRequired
    [string]$PreferredTokenSigningKeyThumbprint
    [string]$PublisherName
    [string[]]$ServicePrincipalNames
    [string]$ServicePrincipalType
    [string[]]$Tags    
}

Class GraphAuditEvent
{
    [string]$Activity
    [System.DateTimeOffset]$ActivityDate
    [long]$ActivityDateInMillis
    [string]$ActivityOperationType
    [string]$ActivityResultDescription
    [string]$ActivityResultStatus
    [string]$ActivityType
    [GraphAuditEventActor]$Actor
    [string]$ActorType
    [string[]]$AdditionalDetails
    [string]$Category
    [string]$ComponentOrSource
    [string]$CorrelationId
    [string]$DomainName
    [string]$Id
    [string]$InternalCorrelationId
    [string]$Source
    [GraphAuditEventTarget[]]$Targets
    [object]$TenantGeolocation
    [string]$TenantId
    [string]$TenantName
}

Class GraphOauth2PermissionGrant
{
    [string]$ClientId
    [string]$ConsentType
    [string]$ExpiryTime
    [string]$ObjectId
    [string]$PrincipalId
    [string]$ResourceId
    [string]$Scope
    [string]$StartTime
}

Class GraphDirectoryRoleTemplate
{
    [string]$DeletionTimestamp
    [string]$Description
    [string]$DisplayName
    [string]$ObjectId
    [string]$ObjectType
    [string]${Odata.type}
}

Class GraphDirectoryRole:GraphDirectoryRoleTemplate
{
    [bool]$IsSystem
    [bool]$RoleDisabled
    [string]$RoleTemplateId
}

Class GraphSigninEvent
{
    [string]$Id
    [string]$SigninDateTime
    [long]$SigninDateTimeInMillis
    [string]$UserDisplayName
    [string]$UserPrincipalName
    [string]$UserId
    [string]$AppId
    [string]$AppDisplayName
    [string]$IpAddress
    [string]$DeviceInformation
    [GraphGeoCoordinate]$GeoCoordinates
    [GraphEventLocation]$Location
    [string]$LoginStatus
    [int]$SigninErrorCode
    [string]$FailureReason
}
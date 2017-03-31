Class GraphDirectoryObject
{
    [string]$DeletionTimestamp
    [string]$Description
    [bool]$DirSyncEnabled
    [string]$DisplayName
    [string]$LastDirSyncTime
    [string]$Mail
    [string]$ObjectId
    [string]$ObjectType
    [string]${Odata.type}
    [string]$OnPremisesSecurityIdentifier
    [string]$MailNickname
    [Object[]]$ProvisioningErrors
    [string[]]$ProxyAddresses
}

#region Users and Groups

Class GraphUserLicense
{
    [GraphUserPlan[]]$DisabledPlans
    [string]$SkuId
}

Class GraphPlanBase
{
    [string]$CapabilityStatus
    [string]$Service
}

Class GraphUserPlan:GraphPlanBase
{
    [System.DateTimeOffset]$AssignedTimestamp
    [string]$ServicePlanId
}

Class GraphProvisionedPlan:GraphPlanBase
{
    [String]$ProvisioningStatus
}

Class GraphPasswordProfile
{
    [string]$Password
    [bool]$ForceChangePasswordNextLogin
}

#endregion
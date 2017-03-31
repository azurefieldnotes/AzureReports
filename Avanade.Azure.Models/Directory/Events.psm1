

Class GraphEventLocation
{
    [string]$City
    [string]$Country
    [string]$State
}

Class GraphGeoCoordinate
{
    [decimal]$Latitude
    [decimal]$Longitude
}

Class GraphAuditEventActor
{
    [string]${@odata.type}
    [string]$IpAddress
    [string]$Name
    [string]$ObjectId
    [string]$Puid
    [string]$ServicePrincipalName
    [string]$UserPrincipalName
}

Class GraphAuditModifiedProperty
{
    [string]$Name
    [string]$NewValue
    [string]$OldValue
}

Class GraphAuditEventTarget
{
    [string]${@odata.type}
    [object]$AdditionalDetails
    [string]$IpAddress
    [string]$IsPrivileged
    [GraphAuditModifiedProperty[]]$ModifiedProperties
    [string]$Name
    [string]$ObjectId
    [string]$Puid
    [string]$TargetResourceType
    [string]$UserPrincipalName
    [string]$ServicePrincipalName
    [string]$UserSource
}
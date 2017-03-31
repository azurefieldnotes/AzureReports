
Class Oauth2PermissionGrant
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

Class DirectoryRoleTemplate
{
    [string]$DeletionTimestamp
    [string]$Description
    [string]$DisplayName
    [string]$ObjectId
    [string]$ObjectType
    [string]${Odata.type}
}

Class DirectoryRole:DirectoryRoleTemplate
{
    [bool]$IsSystem
    [bool]$RoleDisabled
    [string]$RoleTemplateId
}
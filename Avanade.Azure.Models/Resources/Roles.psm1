using module .\BaseItems.psm1

Class ArmRolePropertyBase
{
    [System.DateTimeOffset]$CreatedOn
    [string]$CreatedBy
    [string]$UpdatedBy
    [System.DateTimeOffset]$UpdatedOn
}

Class ArmRolePermission
{
    [string[]]$Actions
    [string[]]$NotActions
}

Class ArmRoleProperties:ArmRolePropertyBase
{
    [string]$AssignableScopes
    [string]$Description
    [ArmRolePermission[]]$Permissions
    [string]$RoleName
    [string]$Type
}

Class ArmRoleAssignmentProperties:ArmRolePropertyBase
{
    [string]$RoleDefinitionId
    [string]$PrincipalId
    [string]$Scope
}


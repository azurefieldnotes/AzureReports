using module .\BaseItems.psm1

Class ArmPolicyAssignmentProperties
{
    [string]$PolicyDefinitionId
    [string]$Scope
}

Class ArmPolicyRule
{
    [PSObject]$If
    [PSObject]$Then
}

Class ArmPolicyDefinitionProperties
{
    [string]$DisplayName
    [string]$PolicyType
    [string]$Description
    [ArmPolicyRule]$PolicyRule
    [PSObject]$Parameters
}
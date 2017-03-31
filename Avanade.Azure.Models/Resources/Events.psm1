using module .\BaseItems.psm1

Class ArmEventAuthorization
{
    [string]$Action
    [string]$Scope
}

Class ArmEventHttpRequest
{
    [string]$ClientRequestId
    [string]$ClientIpAddress
    [string]$Method
}

Class ArmEventProperties:ArmItem
{
    [string]$StatusCode
    [string]$SubStatusCode
    [string]$ServiceRequestId
    [string]$IncidentId
    [string]$IncidentType
    [string]$Title
    [string]$Service
    [string]$ServiceName
    [string]$Region
    [string]${Transcript Of Communication}
    [string]${Entity Name}
    [string]${Job Id}
    [System.DateTimeOffset]${Start Time}
    [string]$RequestBody
    [string]$ResponseBody
    [string]$StatusMessage
    [string]$PrincipalId
    [string]$RoleDefinitionId
    [string]$Scope
}

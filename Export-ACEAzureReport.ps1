<#PSScriptInfo

.VERSION 0.0.1

.GUID 9b00cd5d-dd12-4edc-a2a8-8f2e8de2d6ee

.AUTHOR Chris Speers

.COMPANYNAME Avanade / ACE

.COPYRIGHT 2017 Avanade, Inc. "Imagine!"

.TAGS Report Azure Arm

.DESCRIPTION 
 Exports a large set of Azure data in flat data sets

.LICENSEURI 

.PROJECTURI https://github.com/azurefieldnotes/AzureReports

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES
    Not even close to ready

#>

#REQUIRES -Version 5 -Modules @{ModuleName='Avanade.AzureReports';ModuleVersion="1.0.3"}
using module Avanade.AzureReports

[CmdletBinding(ConfirmImpact='None')]
param
(
    [Parameter(Mandatory=$true)]
    [String]
    $ArmAccessToken,    
    [Parameter(Mandatory=$true)]
    [String]
    $GraphAccessToken,
    [Parameter(Mandatory=$false)]
    [String[]]
    $GraphTenants='myOrganization',
    [Parameter(Mandatory=$false)]
    [System.Uri]
    $ArmFrontDoorUri='https://management.azure.com',
    [Parameter(Mandatory=$false)]
    [System.Uri]
    $GraphResourceUri="https://graph.windows.net",
    [Parameter(Mandatory=$false)]
    [datetime]
    $End=([DateTime]::UtcNow.AddDays(-1).Date),
    [Parameter(Mandatory=$false)]
    [datetime]
    $Start=[DateTime]::UtcNow.Date.AddDays(-7),
    [Parameter(Mandatory=$false)]
    [String]
    $OfferId="0003P",
    [Parameter(Mandatory=$false)]
    [String]
    $Region="US",
    [Parameter(Mandatory=$false)]
    [String]
    $Locale="en-US",
    [Parameter(Mandatory=$false)]
    [String]
    $MetricAggregationType="Average",
    [Parameter(Mandatory=$false)]
    [String]
    $MetricGranularity='PT1H',
    [Parameter(Mandatory=$false)]
    [String]
    $UsageGranularity='Daily',
    [Parameter(Mandatory=$false)]
    [Switch]
    $Usage,
    [Parameter(Mandatory=$false)]
    [Switch]
    $Metrics,
    [Parameter(Mandatory=$false)]
    [Switch]
    $InstanceData,
    [Parameter(Mandatory=$false)]
    [ScriptBlock]
    $SubscriptionFilter={$_.DisplayName -notin 'Access To Azure Active Directory','Free Trial'},
    [Parameter(Mandatory=$false)]
    [Switch]
    $TenantEvents,
    [Parameter(Mandatory=$false)]
    [Switch]
    $OAuthPermissionGrants,
    [Parameter(Mandatory=$false)]
    [Switch]
    $Applications,
    [Parameter(Mandatory=$false)]
    [Switch]
    $ServicePrincipals,
    [Parameter(Mandatory=$false)]
    [Switch]
    $ResourcesOnly,
    [Parameter(Mandatory=$false)]
    [Switch]
    $TenantOnly    
)

if($TenantEvents.IsPresent -and $GraphTenants -eq 'myOrganization')
{
    throw "I apologize. You must specify a tenant id to gather usage"
}

[DetailReport]$DetailReport=Get-AzureDetailReport -ArmFrontDoorUri $ArmFrontDoorUri `
    -ArmAccessToken $ArmAccessToken `
    -Start $Start -End $End `
    -OfferId $OfferId -Region $Region -Locale $Locale `
    -TenantId $GraphTenants -GraphAccessToken $GraphAccessToken `
    -Usage:$Usage.IsPresent -TenantEvents:$TenantEvents.IsPresent -Metrics:$Metrics.IsPresent `
    -InstanceData:$InstanceData.IsPresent -OauthPermissionGrants:$OAuthPermissionGrants.IsPresent `
    -ServicePrincipals:$ServicePrincipals.IsPresent -Applications:$Applications.IsPresent `
    -MetricAggregationType $MetricAggregationType -MetricGranularity $MetricGranularity -UsageGranularity $UsageGranularity `
    -SubscriptionFilter $SubscriptionFilter -ResourcesOnly:$ResourcesOnly -TenantOnly:$TenantOnly -Verbose:$VerbosePreference
Write-Output $DetailReport

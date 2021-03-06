<#PSScriptInfo

.VERSION 1.1

.GUID 9b00cd5d-dd12-4edc-a2a7-8f2e8de2d6de

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

#>

#REQUIRES -Version 5 -Modules @{ModuleName='Avanade.AzureAD';ModuleVersion="1.2.3"},@{ModuleName='Avanade.AzureReports';ModuleVersion="1.0.5"}
using module Avanade.AzureReports

[CmdletBinding(ConfirmImpact='None',DefaultParameterSetName='Credential')]
param
(
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [String]
    $ClientId='1950a258-227b-4e31-a9cf-717495945fc2',
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [String]
    $TenantId='common',
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [String[]]
    $GraphTenants='myOrganization',
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [System.Uri]
    $ArmFrontDoorUri='https://management.azure.com',
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [System.Uri]
    $ArmResourceUri='https://management.core.windows.net',
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [System.Uri]
    $GraphResourceUri="https://graph.windows.net",
    [Parameter(Mandatory=$true,ParameterSetName='Credential')]
    [PSCredential]
    $Credential,
    [Parameter(Mandatory=$true,ParameterSetName='Username')]
    [String]
    $Username,
    [Parameter(Mandatory=$true,ParameterSetName='Username')]
    [SecureString]
    $Password,
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [datetime]
    $End=([DateTime]::UtcNow.AddDays(-1).Date),
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [datetime]
    $Start=[DateTime]::UtcNow.Date.AddDays(-7),
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [String]
    $OfferId="0003P",
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [String]
    $Region="US",
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [String]
    $Locale="en-US",
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [String]
    $MetricAggregationType="Average",
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [String]
    $MetricGranularity='PT1H',
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [String]
    $UsageGranularity='Daily',
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [Switch]
    $Usage,
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [Switch]
    $Metrics,
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [Switch]
    $InstanceData,
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [ScriptBlock]
    $SubscriptionFilter={$_.DisplayName -notin 'Access To Azure Active Directory','Free Trial'},
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [Switch]
    $TenantEvents,
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [Switch]
    $OAuthPermissionGrants,
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [Switch]
    $Applications,
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [Switch]
    $ServicePrincipals,
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [Switch]
    $ResourcesOnly,
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [Switch]
    $TenantOnly,
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [Switch]
    $FlattenRecords       
)

if($TenantEvents.IsPresent -and $GraphTenants -eq 'myOrganization')
{
    throw "I apologize. You must specify a tenant id to gather usage"
}

if($PSCmdlet.ParameterSetName -ne 'Credential')
{
    $Credential=New-Object PSCredential($UserName,$Password)
}

#Azure Resource Manager
$ArmConnection=New-Object PSObject -Property @{
    ClientId=$ClientId;
    TenantId=$TenantId;
    Resource=$ArmResourceUri.AbsoluteUri;
    Credential=$Credential;
}
$ArmToken=Get-AzureADUserToken -ConnectionDetails $ArmConnection

#AD Graph
$GraphConnection=New-Object PSObject -Property @{
    ClientId=$ClientId;
    TenantId=$TenantId;
    Resource=$GraphResourceUri.AbsoluteUri;
    Credential=$Credential;
}
$GraphToken=Get-AzureADUserToken -ConnectionDetails $GraphConnection

[DetailReport]$DetailReport=Get-AzureDetailReport -ArmFrontDoorUri $ArmFrontDoorUri `
    -ArmAccessToken $ArmToken.access_token `
    -Start $Start -End $End `
    -OfferId $OfferId -Region $Region -Locale $Locale `
    -TenantId $GraphTenants -GraphAccessToken $GraphToken.access_token `
    -Usage:$Usage.IsPresent -TenantEvents:$TenantEvents.IsPresent -Metrics:$Metrics.IsPresent `
    -InstanceData:$InstanceData.IsPresent -OauthPermissionGrants:$OAuthPermissionGrants.IsPresent `
    -ServicePrincipals:$ServicePrincipals.IsPresent -Applications:$Applications.IsPresent `
    -MetricAggregationType $MetricAggregationType -MetricGranularity $MetricGranularity -UsageGranularity $UsageGranularity `
    -SubscriptionFilter $SubscriptionFilter -ResourcesOnly:$ResourcesOnly -TenantOnly:$TenantOnly -Verbose:$VerbosePreference

if($FlattenRecords.IsPresent)
{
    foreach ($Report in $DetailReport.Summaries)
    {
        Write-Output $Report.Export()
    }
}
else
{
    Write-Output $DetailReport.Summaries
}

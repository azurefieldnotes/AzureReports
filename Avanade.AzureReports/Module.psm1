#REQUIRES -Version 5 -Modules @{ModuleName='Avanade.Azure.Models';ModuleVersion='1.0.3'},@{ModuleName='Avanade.ArmTools';ModuleVersion="1.6.1"}
using module Avanade.Azure.Models

#region concrete classes

Class ResourceBase:ArmResourceBase
{

    [System.Management.Automation.ActionPreference] $VerbosePreference='SilentlyContinue'

    static [string] $ARMFrontDoorUri='https://management.azure.com'

    static [int] $ActivityId=80001

    [bool]SupportsMetrics()
    {
        if([String]::IsNullOrEmpty($this.Id))
        {
            throw "the resource id is null"
        }
        $Detail=$this.Id|ConvertFrom-ArmResourceId
        return $Detail.FullResourceType -in @(
            "Microsoft.Compute/virtualMachines","Microsoft.ClassicCompute/virtualMachines",
            "Microsoft.Sql/servers/databases","Microsoft.Web/sites",
            "Microsoft.Web/serverFarms",
            "Microsoft.StreamAnalytics/streamingjobs","Microsoft.Devices/IotHubs",
            "Microsoft.ServiceBus/namespaces","Microsoft.Compute/virtualMachineScaleSets" #,"microsoft.insights/components"
        )
    }

    [bool]IsClassic()
    {
        if([String]::IsNullOrEmpty($this.Id))
        {
            throw "the resource id is null"
        }
        $Detail=$this.Id|ConvertFrom-ArmResourceId
        return $Detail.Namespace -like "*.Classic*"
    }

    [ArmMetricDefinition[]]MetricDefinitions([string]$AccessToken)
    {
        if($this.SupportsMetrics())
        {
            return Get-ArmResourceMetricDefinition -ResourceId $this.Id -AccessToken $AccessToken -ApiEndpoint ([ResourceBase]::ARMFrontDoorUri) -Verbose:$this.VerbosePreference
        }
        else
        {
            Write-Warning "$($this.Type) does not support metrics"
            return $null
        }
    }

    [ArmNormalizedMetricValue[]]Metrics([string]$AccessToken,[DateTime]$Start,[DateTime]$End,[string]$AggregationType,[string]$Granularity)
    {
        [ArmNormalizedMetricValue[]]$Metrics=@()
        $MetricDefinitions=$this.MetricDefinitions($AccessToken)
        for ($i = 0; $i -lt $MetricDefinitions.Count; $i++)
        {
            Write-Progress -Id ([ResourceBase]::ActivityId) -Activity "Gathering Normalized Metrics" `
                -PercentComplete (($i/$MetricDefinitions.Count) * 100) `
                -Status "Retrieving $($MetricDefinitions[$i].Name.LocalizedValue) metrics for $($MetricDefinitions[$i].ResourceId)"
            Write-Verbose "Retrieving $($MetricDefinitions[$i].Name.LocalizedValue) metrics for $($MetricDefinitions[$i].ResourceId)"
            $MetricValues=$this.MetricValues($AccessToken,$MetricDefinitions[$i],$Start,$End,$AggregationType,$Granularity)
            $Metrics+=$MetricValues
        }
        Write-Progress -Id ([ResourceBase]::ActivityId) -Activity "Gathering Normalized Metrics" -Completed
        return $Metrics
    }

    [ArmNormalizedMetricValue[]]MetricValues([string]$AccessToken,[ArmMetricDefinition]$MetricDefinition,[DateTime]$Start,[DateTime]$End,[string]$AggregationType,[string]$Granularity)
    {
        [ArmNormalizedMetricValue[]]$Metrics=@()
        $IsClassic=$this.IsClassic()
        $StartTime=(New-Object System.DateTimeOffset($Start)).ToString('o')
        $EndTime=(New-Object System.DateTimeOffset($End)).ToString('o')
        if($IsClassic)
        {
            $Filter="(name.value eq '$($MetricDefinition.Name.Value)') and startTime eq $($StartTime) " +
                "and endTime eq $($EndTime) and timeGrain eq duration'$Granularity'"
            [ArmClassicMetricEntry]$MetricResult=Get-ArmResourceMetric -ResourceId $MetricDefinition.ResourceId -Filter $Filter -AccessToken $AccessToken -ApiEndpoint ([ResourceBase]::ARMFrontDoorUri) -Verbose:$this.VerbosePreference
            foreach ($ItemData in $MetricResult.MetricValues) {
                if($ItemData.PSobject.Properties.name -match $AggregationType)
                {
                    $MetricValue=$ItemData|Select-Object -ExpandProperty $AggregationType
                }
                else
                {
                    $MetricValue=0.0
                }
                $NormalEntry=[ArmNormalizedMetricValue]::new()
                $NormalEntry.AggregationType=$AggregationType
                $NormalEntry.Name=$MetricDefinition.Name
                $NormalEntry.PrimaryAggregationType=$MetricDefinition.PrimaryAggregationType
                $NormalEntry.ResourceId=$MetricDefinition.ResourceId
                $NormalEntry.Unit=$MetricDefinition.Unit
                $NormalEntry.TimeStamp=$ItemData.TimeStamp
                $NormalEntry.MetricValue=$MetricValue
                $NormalEntry.ResourceType=$this.Type
                $Metrics+=$NormalEntry
            }
        }
        else
        {
            $Filter="(name.value eq '$($MetricDefinition.Name.Value)') and aggregationType eq '$AggregationType' and startTime eq $($StartTime) " +
                "and endTime eq $($EndTime) and timeGrain eq duration'$Granularity'"
            switch ($AggregationType)
            {
                'Average' {
                    [ArmAverageMetricEntry]$MetricResult=Get-ArmResourceMetric -ResourceId $MetricDefinition.ResourceId -Filter $Filter -AccessToken $AccessToken -ApiEndpoint ([ResourceBase]::ARMFrontDoorUri) -Verbose:$this.VerbosePreference
                    break
                }
                'Maximum' {
                    [ArmMaximumMetricEntry]$MetricResult=Get-ArmResourceMetric -ResourceId $MetricDefinition.ResourceId -Filter $Filter -AccessToken $AccessToken -ApiEndpoint ([ResourceBase]::ARMFrontDoorUri) -Verbose:$this.VerbosePreference
                    break
                }
                'Minimum' {
                    [ArmMinimumMetricEntry]$MetricResult=Get-ArmResourceMetric -ResourceId $MetricDefinition.ResourceId -Filter $Filter -AccessToken $AccessToken -ApiEndpoint ([ResourceBase]::ARMFrontDoorUri) -Verbose:$this.VerbosePreference
                    break
                }
                'Total' {
                        $MetricResult=Get-ArmResourceMetric -ResourceId $MetricDefinition.ResourceId -Filter $Filter -AccessToken $AccessToken -ApiEndpoint ([ResourceBase]::ARMFrontDoorUri) -Verbose:$this.VerbosePreference
                        break
                    }
                Default {
                    [ArmMetricEntry]$MetricResult=Get-ArmResourceMetric -ResourceId $MetricDefinition.ResourceId -Filter $Filter -AccessToken $AccessToken -ApiEndpoint ([ResourceBase]::ARMFrontDoorUri) -Verbose:$this.VerbosePreference
                    break
                }
            }
            if($MetricResult -ne $null)
            {
                foreach ($ItemData in $MetricResult.Data) {
                    if($ItemData.PSobject.Properties.name -match $AggregationType)
                    {
                        $MetricValue=$ItemData|Select-Object -ExpandProperty $AggregationType
                    }
                    else
                    {
                        $MetricValue=0.0
                    }
                    $NormalEntry=[ArmNormalizedMetricValue]::new()
                    $NormalEntry.AggregationType=$AggregationType
                    $NormalEntry.Name=$MetricDefinition.Name
                    $NormalEntry.PrimaryAggregationType=$MetricDefinition.PrimaryAggregationType
                    $NormalEntry.ResourceId=$MetricDefinition.ResourceId
                    $NormalEntry.Unit=$MetricDefinition.Unit
                    $NormalEntry.TimeStamp=$ItemData.TimeStamp
                    $NormalEntry.MetricValue=$MetricValue
                    $NormalEntry.ResourceType=$this.Type
                    $Metrics+=$NormalEntry
                }
            }
        }
        return $Metrics
    }
}

Class ResourceInstance:ResourceBase
{
    [System.Object]$Properties
    [ArmResourceBase[]]$Resources
}

class SubscriptionInstance:ArmSubscriptionBase
{
    static [int] $ActivityId=8001

    static [string] $ARMFrontDoorUri='https://management.azure.com'

    [ResourceBase[]]Resources([string]$AccessToken)
    {
        $this.TestId()
        return $this.Resources($AccessToken,$true)
    }

    [ResourceBase[]]Resources([string]$AccessToken,[bool]$InstanceView)
    {
        $this.TestId()
        $Activity="Retrieving Resources for $($this.DisplayName) Subscription"
        [ResourceBase[]]$BaseResources=Get-ArmResource -SubscriptionId $this.SubscriptionId -AccessToken $AccessToken -ApiEndpoint ([SubscriptionInstance]::ARMFrontDoorUri) -Verbose:$this.VerbosePreference
        if ($InstanceView)
        {
            $RequestLength=0
            [ResourceInstance[]]$Instances=@()
            for ($i = 0; $i -lt $BaseResources.Count; $i++)
            {
                $BaseResource=$BaseResources[$i]
                $BaseResource.VerbosePreference=$this.VerbosePreference
                $CurrentProgress=(($i/$BaseResources.Count) * 100)
                $CurrentStatus="Retrieving $($BaseResource.id)"
                Write-Verbose "[$($this.SubscriptionId)] $CurrentStatus - %($CurrentProgress)"
                Write-Progress -Id ([SubscriptionInstance]::ActivityId) -Activity $Activity -Status $CurrentStatus -PercentComplete $CurrentProgress
                $Instances+=(Get-ArmResourceInstance -AccessToken $AccessToken -Id $BaseResource.Id -ApiEndpoint ([SubscriptionInstance]::ARMFrontDoorUri) -Verbose:$this.VerbosePreference)
            }
            Write-Progress -Id ([SubscriptionInstance]::ActivityId) -Activity $Activity -Completed
            return $Instances
        }
        else
        {
            return $BaseResources
        }
    }

    [ArmUsageAggregate[]]UsageAggregates([string]$AccessToken,[DateTime]$Start,[DateTime]$End,[bool]$ShowDetails,[string]$Granularity)
    {
        $this.TestId()
        [ArmUsageAggregate[]]$Usages=Get-ArmUsageAggregate -AccessToken $AccessToken `
            -SubscriptionId $this.SubscriptionId `
            -StartTime $Start -EndTime $End `
            -Granularity $Granularity -ShowDetails:$ShowDetails `
            -ApiEndpoint ([SubscriptionInstance]::ARMFrontDoorUri) -Verbose:$this.VerbosePreference
        return $Usages
    }

    [ArmRateCard]RateCard([string]$AccessToken,[string]$OfferCode,[string]$Region,[string]$Locale)
    {
        $this.TestId()
        return Get-ArmRateCard -SubscriptionId $this.SubscriptionId -AccessToken $AccessToken `
            -OfferCode $OfferCode -RegionInfo $Region -Locale $Locale `
            -ApiEndpoint ([SubscriptionInstance]::ARMFrontDoorUri) -Verbose:$this.VerbosePreference
    }

    [ArmEventLogEntry[]]EventLog([string]$AccessToken)
    {
        $this.TestId()
        return Get-ArmEventLog -SubscriptionId $this.SubscriptionId -AccessToken $AccessToken -ApiEndpoint ([SubscriptionInstance]::ARMFrontDoorUri) -Verbose:$this.VerbosePreference
    }

    [ArmNormalizedMetricValue[]]ResourceMetrics([string]$AccessToken,[DateTime]$Start,[DateTime]$End,[string]$AggregationType,[string]$Granularity)
    {
        $this.TestId()
        [ArmNormalizedMetricValue[]]$ResourceMetrics=@()
        [ResourceBase[]]$SubscriptionResources=$this.Resources($AccessToken,$false)
        $Activity="Retrieving Resource Metrics for $($this.DisplayName) Subscription"
        for ($i = 0; $i -lt $SubscriptionResources.Count; $i++)
        {
            $CurrentProgress=(($i/$SubscriptionResources.Count) * 100)
            $CurrentStatus="Retrieving Metrics for $($SubscriptionResources[$i].Id)"
            Write-Verbose "[$($this.SubscriptionId)] $CurrentStatus - %($CurrentProgress)"
            Write-Progress -Id ([SubscriptionInstance]::ActivityId) -Activity $Activity -Status $CurrentStatus -PercentComplete $CurrentProgress
            $Metrics=$SubscriptionResources[$i].Metrics($AccessToken,$Start,$End,$AggregationType,$Granularity)
            $ResourceMetrics+=$Metrics
        }
        Write-Progress -Id ([SubscriptionInstance]::ActivityId) -Activity $Activity -Completed
        return $ResourceMetrics
    }

    [ArmAdvisorRecommendation[]]AdvisorRecommendations([string]$AccessToken)
    {
        $this.TestId()
        return Get-ArmAdvisorRecommendation -Subscription $this -AccessToken $AccessToken -ApiEndpoint ([SubscriptionInstance]::ARMFrontDoorUri) -Verbose:$this.VerbosePreference
    }

    [ArmPreviewFeature[]]PreviewFeatures([string]$AccessToken)
    {
        $this.TestId()
        return Get-ArmFeature -Subscription $this -AccessToken $AccessToken -ApiEndpoint ([SubscriptionInstance]::ARMFrontDoorUri) -Verbose:$this.VerbosePreference
    }

    [ArmResourceProvider[]]ResourceProviders([string]$AccessToken)
    {
        $this.TestId()
        return Get-ArmProvider -Subscription $this -AccessToken $AccessToken -ApiEndpoint ([SubscriptionInstance]::ARMFrontDoorUri)
    }

    [ArmRoleDefinition[]]RoleDefinitions([string]$AccessToken)
    {
        $this.TestId()
        return Get-ArmRoleDefinition -Subscription $this -AccessToken $AccessToken -ApiEndpoint ([SubscriptionInstance]::ARMFrontDoorUri) -Verbose:$this.VerbosePreference
    }

    [ArmRoleAssignment[]]RoleAssignments([string]$AccessToken)
    {
        $this.TestId()
        return Get-ArmRoleAssignment -Subscription $this -AccessToken $AccessToken -ApiEndpoint ([SubscriptionInstance]::ARMFrontDoorUri) -Verbose:$this.VerbosePreference
    }

    [ArmPolicyDefinition[]]PolicyDefinitions([string]$AccessToken)
    {
        $this.TestId()
        return Get-ArmPolicyDefinition -Subscription $this -AccessToken $AccessToken -ApiEndpoint ([SubscriptionInstance]::ARMFrontDoorUri) -Verbose:$this.VerbosePreference
    }

    [ArmPolicyAssignment[]]PolicyAssignments([string]$AccessToken)
    {
        $this.TestId()
        return Get-ArmPolicyAssignment -Subscription $this -AccessToken $AccessToken -ApiEndpoint ([SubscriptionInstance]::ARMFrontDoorUri) -Verbose:$this.VerbosePreference
    }

    [ArmResourceLock[]]ResourceLocks([string]$AccessToken)
    {
        $this.TestId()
        return Get-ArmResourceLock -Subscription $this -AccessToken $AccessToken -ApiEndpoint ([SubscriptionInstance]::ARMFrontDoorUri) -Verbose:$this.VerbosePreference
    }

    [ArmQuotaUsage[]]StorageQuotaUsage([string]$AccessToken)
    {
        $this.TestId()
        return Get-ArmStorageUsage -Subscription $this -AccessToken $AccessToken -ApiEndpoint ([SubscriptionInstance]::ARMFrontDoorUri)
    }

    [ComputeQuotaUsage[]]ComputeQuotaUsage([string]$AccessToken,[string]$Location)
    {
        $this.TestId()
        [ArmQuotaUsage[]]$UsageResult=Get-ArmComputeUsage -Subscription $this -AccessToken $AccessToken -Location $Location -ApiEndpoint ([SubscriptionInstance]::ARMFrontDoorUri) -Verbose:$this.VerbosePreference
        $Result=$UsageResult|Select-Object @{N="Usage";E={[ComputeQuotaUsage]::new($_,$Location)}}
        return $Result|Select-Object -ExpandProperty Usage
    }

    [ComputeQuotaUsage[]]ComputeQuotaUsage([string]$AccessToken)
    {
        $this.TestId()
        [ComputeQuotaUsage[]]$Usages=@()
        $Locations=Get-ArmResourceTypeLocation -Subscription $this -ResourceType 'Microsoft.Compute/virtualMachines' -AccessToken $AccessToken -ApiEndpoint ([SubscriptionInstance]::ARMFrontDoorUri) -Verbose:$this.VerbosePreference
        foreach ($Location in $Locations)
        {
            $Usages+=$this.ComputeQuotaUsage($AccessToken,$Location)
        }
        return $Usages
    }

    [ArmTagName[]]TagNameReport([string]$AccessToken)
    {
        $this.TestId()
        return Get-ArmTagName -Subscription $this -AccessToken $AccessToken -ExpandTagValues -ApiEndpoint ([SubscriptionInstance]::ARMFrontDoorUri) -Verbose:$this.VerbosePreference
    }

    [VmSize[]]AvailableVmSizes([string]$AccessToken)
    {
        [VmSize[]]$VmSizes=@()
        $Locations=Get-ArmResourceTypeLocation -Subscription $this -ResourceType 'Microsoft.Compute/virtualMachines' -AccessToken $AccessToken -ApiEndpoint ([SubscriptionInstance]::ARMFrontDoorUri) -Verbose:$this.VerbosePreference
        foreach ($Location in $Locations)
        {
            $VmSizes+=$this.AvailableVmSizes($AccessToken,$Location)
        }
        return $VmSizes
    }

    [VmSize[]]AvailableVmSizes([string]$AccessToken,[string]$Location)
    {
        $this.TestId()
        [ArmVmSize[]]$VmSizes=Get-ArmVmSize -Subscription $this -Location $Location -AccessToken $AccessToken -ApiEndpoint ([SubscriptionInstance]::ARMFrontDoorUri) -Verbose:$this.VerbosePreference
        $Result=$VmSizes|Select-Object @{N="Size";E={[VmSize]::new($_,$Location)}}
        return $Result|Select-Object -ExpandProperty "Size"
    }

}

Class TenantInstance:GraphTenantBase
{

    [GraphDomain[]]Domains([string]$AccessToken)
    {
        return Get-AzureADGraphDomain -AccessToken $AccessToken
    }

    [GraphSigninEvent[]]SigninEvents([string]$AccessToken,[datetime]$Start,[datetime]$End)
    {
        $StartTime="{0:s}" -f $Start + "Z"
        $EndTime="{0:s}" -f $End + "Z"
        return Get-AzureADGraphSigninEvent -TenantName $this.TenantId -AccessToken $AccessToken -Filter "signinDateTime gt $StartTime and signinDateTime lt $EndTime" -Verbose:$this.VerbosePreference
    }

    [GraphAuditEvent[]]AuditEvents([string]$AccessToken,[datetime]$Start,[datetime]$End)
    {
        $StartTime="{0:s}" -f $Start + "Z"
        $EndTime="{0:s}" -f $End + "Z"
        return Get-AzureADGraphAuditEvent -TenantName $this.TenantId -AccessToken $AccessToken -Filter "activityDate gt $StartTime and activityDate lt $EndTime" -Verbose:$this.VerbosePreference
    }

    [GraphDirectoryGroup[]]Groups([string]$AccessToken)
    {
        return Get-AzureADGraphGroup -AccessToken $AccessToken -Verbose:$this.VerbosePreference
    }

    [GraphDirectoryUser[]]Users([string]$AccessToken)
    {
        return Get-AzureADGraphUser -AccessToken $AccessToken -Verbose:$this.VerbosePreference
    }

    [GraphDirectoryRole[]]Roles([string]$AccessToken)
    {
        return Get-AzureADGraphRole -AccessToken $AccessToken -Verbose:$this.VerbosePreference
    }

    [GraphDirectoryRoleTemplate[]]RoleTemplates([string]$AccessToken)
    {
        return Get-AzureADGraphRoleTemplate -AccessToken $AccessToken
    }

    [GraphOauth2PermissionGrant[]]OauthPermissionGrants([string]$AccessToken)
    {
        return Get-AzureADGraphOauthPermissionGrant -AccessToken $AccessToken -Top 999 -Verbose:$this.VerbosePreference
    }

    [GraphDirectoryServicePrincipal[]]ServicePrincipals([string]$AccessToken)
    {
        return Get-AzureADGraphServicePrincipal -AccessToken $AccessToken -Verbose:$this.VerbosePreference
    }

    [GraphDirectoryApplication[]]Applications([string]$AccessToken)
    {
        return Get-AzureADGraphApplication -AccessToken $AccessToken -Verbose:$this.VerbosePreference
    }

    TenantInstance([string] $TenantId)
    {
        $this.TenantId=$TenantId
    }
}

Class SummaryReport
{
    [string]$ReportType

    [Object]Export()
    {
        throw "this must be implemented in a derived class"
    }
}

Class SummaryExport
{
    [string]$ReportType
}

Class SubscriptionSummaryExport:SummaryExport
{
    [String]$SubscriptionId
    [String]$SubscriptionDisplayName
    [Object[]]$RateCards
    [Object[]]$EventLogEntries
    [Object[]]$AdvisorRecommendations
    [Object[]]$Resources
    [Object[]]$ResourceLocks
    [Object[]]$PolicyDefinitions
    [Object[]]$RoleAssignments
    [Object[]]$RoleDefinitions
    [Object[]]$PolicyAssignments
    [Object[]]$StorageQuotaUsage
    [Object[]]$ComputeQuotaUsage
    [Object[]]$TagNameUsage
    [Object[]]$MetricValues
    [Object[]]$UsageAggregates
    [Object[]]$AvailableVmSizes
}

Class TenantSummaryExport:SummaryExport
{
    [String]$TenantId
    [Object[]]$Groups
    [Object[]]$Roles
    [Object[]]$RoleTemplates
    [Object[]]$Users
    [Object[]]$AuditEvents
    [Object[]]$SigninEvents
    [Object[]]$OauthPermissionGrants
    [Object[]]$Applications
    [Object[]]$ServicePrincipals
}

Class SubscriptionSummary:SummaryReport
{
    static [int] $ActivityId=9001

    [SubscriptionInstance]$Subscription
    [ResourceBase[]]$Resources
    [ArmRateCard]$RateCard
    [ArmUsageAggregate[]]$UsageAggregates
    [ArmAdvisorRecommendation[]]$AdvisorRecommendations
    [ArmEventLogEntry[]]$EventLogEntries
    [ArmNormalizedMetricValue[]]$MetricValues
    [ArmPreviewFeature[]]$PreviewFeatures
    [ArmResourceProvider[]]$ResourceProviders
    [ArmRoleDefinition[]]$RoleDefinitions
    [ArmRoleAssignment[]]$RoleAssignments
    [ArmPolicyDefinition[]]$PolicyDefinitions
    [ArmPolicyAssignment[]]$PolicyAssignments
    [ArmResourceLock[]]$ResourceLocks
    [ArmQuotaUsage[]]$StorageQuotaUsage
    [ComputeQuotaUsage[]]$ComputeQuotaUsage
    [ArmTagName[]]$TagNameReport
    [VmSize[]]$AvailableVmSizes

    [SubscriptionSummaryExport]Export()
    {
        $Result=[SubscriptionSummaryExport]::new()
        $Result.SubscriptionId=$this.Subscription.SubscriptionId
        $Result.SubscriptionDisplayName=$this.Subscription.DisplayName
        $Result.ReportType=$this.ReportType
        $Result.ResourceLocks=$this|Export-SubscriptionResourceLocks
        $Result.MetricValues=$this|Export-SubscriptionMetricSet
        $Result.UsageAggregates=$this|Export-SubscriptionUsageAggregates
        $Result.RateCards=$this|Export-SubscriptionRateCard
        #$Result.PreviewFeatures=$this.PreviewFeatures
        $Result.StorageQuotaUsage=$this|Export-SubscriptionStorageQuotaUsage
        $Result.ComputeQuotaUsage=$this|Export-SubscriptionComputeQuotaUsage
        $Result.AvailableVmSizes=$this|Export-SubscriptionVmSizes
        $Result.TagNameUsage=$this|Export-SubscriptionTagNameReport
        $Result.AdvisorRecommendations=$this|Export-SubscriptionRecommendations
        $Result.EventLogEntries=$this|Export-SubscriptionEventlog
        $Result.PolicyAssignments=$this|Export-SubscriptionPolicyAssignments
        $Result.PolicyDefinitions=$this|Export-SubscriptionPolicyDefinitions
        #$Result.ResourceProviders=$this.ResourceProviders
        $Result.RoleAssignments=$this|Export-SubscriptionRoleAssignments
        $Result.RoleDefinitions=$this|Export-SubscriptionRoleDefinitions
        $Result.Resources=$this|Export-SubscriptionResources
        return $Result
    }

    SubscriptionSummary([SubscriptionInstance]$subscription)
    {
        $this.ReportType='Resource'
        $this.Subscription=$subscription
    }
}

Class TenantSummary:SummaryReport
{
    static [int] $ActivityId=9002

    [TenantSummaryExport]Export()
    {
        $Result=[TenantSummaryExport]::new()
        $Result.TenantId=$this.Tenant.TenantId
        $Result.ReportType=$this.ReportType
        $Result.AuditEvents=$this.AuditEvents
        $Result.SigninEvents=$this.SigninEvents
        $Result.Groups=$this.Groups
        $Result.Roles=$this.Roles
        $Result.RoleTemplates=$this.RoleTemplates
        $Result.Users=$this.Users
        $Result.OauthPermissionGrants=$this.OauthPermissionGrants
        $Result.Applications=$this.Applications
        $Result.ServicePrincipals=$this.ServicePrincipals
        return $Result
    }

    [TenantInstance]$Tenant
    [GraphDomain[]]$Domains
    [GraphSigninEvent[]]$SigninEvents
    [GraphAuditEvent[]]$AuditEvents
    [GraphDirectoryGroup[]]$Groups
    [GraphDirectoryUser[]]$Users
    [GraphDirectoryRole[]]$Roles
    [GraphDirectoryRoleTemplate[]]$RoleTemplates
    [GraphOauth2PermissionGrant[]]$OauthPermissionGrants
    [GraphDirectoryApplication[]]$Applications
    [GraphDirectoryServicePrincipal[]]$ServicePrincipals

    TenantSummary([TenantInstance]$Tenant)
    {
        $this.ReportType='Tenant'
        $this.Tenant=$Tenant
    }
}

Class DetailReport
{
    [SummaryReport[]]$Summaries
}

Class VmSize:ArmVmSize
{
    [string]$Location

    VmSize([ArmVmSize]$VmSize,[string]$Location)
    {
        $this.Location=$Location
        $this.MaxDataDiskCount=$VmSize.MaxDataDiskCount
        $this.MemoryInMB=$VmSize.MemoryInMB
        $this.Name=$VmSize.Name
        $this.OsDiskSizeInMB=$VmSize.OsDiskSizeInMB
        $this.ResourceDiskSizeInMB=$VmSize.ResourceDiskSizeInMB
        $this.NumberOfCores=$VmSize.NumberOfCores
    }
}

Class ComputeQuotaUsage:ArmQuotaUsage
{
    [string]$Location

    ComputeQuotaUsage([ArmQuotaUsage]$ArmQuotaUsage,[string]$Location)
    {
        $this.Unit=$ArmQuotaUsage.Unit
        $this.CurrentValue=$ArmQuotaUsage.CurrentValue
        $this.Limit=$ArmQuotaUsage.Limit
        $this.Name=$ArmQuotaUsage.Name
        $this.Location=$Location
    }
}

#endregion

#region Functions

Function GetTenantSummary
{
    [CmdletBinding(ConfirmImpact='None')]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [TenantInstance[]]$Tenant,
        [Parameter(Mandatory=$true)]
        [String]
        $AccessToken,
        [Parameter(Mandatory=$true)]
        [datetime]
        $Start,
        [Parameter(Mandatory=$true)]
        [datetime]
        $End,
        [Parameter(Mandatory=$false)]
        [Switch]
        $Events,
        [Parameter(Mandatory=$false)]
        [Switch]
        $OauthPermissionGrants,
        [Parameter(Mandatory=$false)]
        [Switch]
        $ServicePrincipals,
        [Parameter(Mandatory=$false)]
        [Switch]
        $Applications
    )

    BEGIN
    {
        $ActivityId=[TenantSummary]::ActivityId
    }
    PROCESS
    {
        foreach ($item in $Tenant)
        {
            $item.VerbosePreference=$VerbosePreference
            $TenantSummary=[TenantSummary]::new($item)
            Write-Progress -Id $ActivityId -Activity "Summarizing Azure AD Tenant $($item.TenantId)" -Status "Retrieving Domains" -PercentComplete 10
            $TenantSummary.Domains=$item.Domains($AccessToken)

            Write-Progress -Id $ActivityId -Activity "Summarizing Azure AD Tenant $($item.TenantId)" -Status "Retrieving Groups" -PercentComplete 20
            $TenantSummary.Groups=$item.Groups($AccessToken)

            Write-Progress -Id $ActivityId -Activity "Summarizing Azure AD Tenant $($item.TenantId)" -Status "Retrieving Users" -PercentComplete 30
            $TenantSummary.Users=$item.Users($AccessToken)

            if ($OauthPermissionGrants.IsPresent)
            {
                Write-Progress -Activity "Summarizing Azure AD Tenant $($item.TenantId)" -Status "Retrieving OAuth2 Permission Grants" -PercentComplete 40
                $TenantSummary.OauthPermissionGrants=$item.OauthPermissionGrants($AccessToken)
            }

            Write-Progress -Id $ActivityId -Activity "Summarizing Azure AD Tenant $($item.TenantId)" -Status "Retrieving Role Templates" -PercentComplete 50
            $TenantSummary.RoleTemplates=$item.RoleTemplates($AccessToken)

            Write-Progress -Id $ActivityId -Activity "Summarizing Azure AD Tenant $($item.TenantId)" -Status "Retrieving Roles" -PercentComplete 55
            $TenantSummary.Roles=$item.Roles($AccessToken)

            if($Applications.IsPresent)
            {
                Write-Progress -Id $ActivityId -Activity "Summarizing Azure AD Tenant $($item.TenantId)" -Status "Retrieving Applications" -PercentComplete 65
                $TenantSummary.Applications=$item.Applications($AccessToken)
            }

            if($ServicePrincipals.IsPresent)
            {
                Write-Progress -Id $ActivityId -Activity "Summarizing Azure AD Tenant $($item.TenantId)" -Status "Retrieving ServicePrincipals" -PercentComplete 60
                $TenantSummary.ServicePrincipals=$item.ServicePrincipals($AccessToken)
            }

            if($Events.IsPresent)
            {
                Write-Progress -Id $ActivityId -Activity "Summarizing Azure AD Tenant $($item.TenantId)" -Status "Retrieving Audit Events $($Start) - $($End)" -PercentComplete 70
                $TenantSummary.AuditEvents=$item.AuditEvents($AccessToken,$Start,$End)
                Write-Progress -Id $ActivityId -Activity "Summarizing Azure AD Tenant $($item.TenantId)" -Status "Retrieving Signin Events $($Start) - $($End)" -PercentComplete 80
                $TenantSummary.SigninEvents=$item.SigninEvents($AccessToken,$Start,$End)
            }

            Write-Progress -Id $ActivityId -Activity "Summarizing Azure AD Tenant $($item.TenantId)" -Completed
            Write-Output $TenantSummary
        }
    }
    END
    {

    }
}

Function GetSubscriptionSummary
{
    [CmdletBinding(ConfirmImpact='None')]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [SubscriptionInstance[]]
        $Subscription,
        [Parameter(Mandatory=$false)]
        [System.Uri]
        $ArmFrontDoorUri='https://management.azure.com',
        [Parameter(Mandatory=$true)]
        [String]
        $AccessToken,
        [Parameter(Mandatory=$true)]
        [String]
        $OfferId,
        [Parameter(Mandatory=$true)]
        [datetime]
        $End,
        [Parameter(Mandatory=$true)]
        [datetime]
        $Start,
        [Parameter(Mandatory=$false)]
        [String]
        $Region="US",
        [Parameter(Mandatory=$false)]
        [String]
        $Locale="en-US",
        [ValidateSet('Average','Maximum','Minimum','Total')]
        [Parameter(Mandatory=$false)]
        [String]
        $AggregationType="Average",
        [Parameter(Mandatory=$false)]
        [String]
        $MetricGranularity="PT1H",
        [ValidateSet('Hourly','Daily')]
        [Parameter(Mandatory=$false)]
        [String]
        $UsageGranularity="Hourly",
        [Parameter(Mandatory=$false)]
        [Switch]
        $Usage,
        [Parameter(Mandatory=$false)]
        [Switch]
        $Metrics,
        [Parameter(Mandatory=$false)]
        [Switch]
        $InstanceData
    )
    BEGIN
    {
        $ActivityId=8008
    }
    PROCESS
    {
        foreach ($item in $Subscription)
        {
            $Result=[SubscriptionSummary]::new($item)

            Write-Progress -Id $ActivityId -Activity "Summarizing Subscription $($item.DisplayName)" -Status "Retrieving Resource Providers" -PercentComplete 5
            $Result.ResourceProviders=$item.ResourceProviders($AccessToken)

            Write-Progress -Id $ActivityId -Activity "Summarizing Subscription $($item.DisplayName)" -Status "Retrieving Preview Features" -PercentComplete 10
            $Result.PreviewFeatures=$item.PreviewFeatures($AccessToken)

            Write-Progress -Id $ActivityId -Activity "Summarizing Subscription $($item.DisplayName)" -Status "Retrieving Rate Card" -PercentComplete 15
            $Result.RateCard=$item.RateCard($AccessToken,$OfferId,$Region,$Locale);

            Write-Progress -Id $ActivityId -Activity "Summarizing Subscription $($item.DisplayName)" -Status "Retrieving Advisor Recommendations" -PercentComplete 20
            $Result.AdvisorRecommendations=$item.AdvisorRecommendations($AccessToken);

            Write-Progress -Id $ActivityId -Activity "Summarizing Subscription $($item.DisplayName)" -Status "Retrieving Event Log" -PercentComplete 25
            $Result.EventLogEntries=$item.EventLog($AccessToken);

            Write-Progress -Id $ActivityId -Activity "Summarizing Subscription $($item.DisplayName)" -Status "Retrieving Role Definitions" -PercentComplete 30
            $Result.RoleDefinitions=$item.RoleDefinitions($AccessToken);

            Write-Progress -Id $ActivityId -Activity "Summarizing Subscription $($item.DisplayName)" -Status "Retrieving Role Assignments" -PercentComplete 35
            $Result.RoleAssignments=$item.RoleAssignments($AccessToken);

            Write-Progress -Id $ActivityId -Activity "Summarizing Subscription $($item.DisplayName)" -Status "Retrieving Policy Definitions" -PercentComplete 40
            $Result.PolicyDefinitions=$item.PolicyDefinitions($AccessToken);

            Write-Progress -Id $ActivityId -Activity "Summarizing Subscription $($item.DisplayName)" -Status "Retrieving Policy Assignments" -PercentComplete 45
            $Result.PolicyAssignments=$item.PolicyAssignments($AccessToken);

            Write-Progress -Id $ActivityId -Activity "Summarizing Subscription $($item.DisplayName)" -Status "Retrieving Resource Locks" -PercentComplete 45
            $Result.ResourceLocks=$item.ResourceLocks($AccessToken);

            Write-Progress -Id $ActivityId -Activity "Summarizing Subscription $($item.DisplayName)" -Status "Retrieving Resource Tag Report" -PercentComplete 50
            $Result.TagNameReport=$item.TagNameReport($AccessToken);

            Write-Progress -Id $ActivityId -Activity "Summarizing Subscription $($item.DisplayName)" -Status "Retrieving Resources" -PercentComplete 55
            $Result.Resources=[ResourceBase[]]$item.Resources($AccessToken,$InstanceData.IsPresent);

            Write-Progress -Id $ActivityId -Activity "Summarizing Subscription $($item.DisplayName)" -Status "Retrieving Storage Quota Usage" -PercentComplete 60
            $Result.StorageQuotaUsage=[ArmQuotaUsage[]]$item.StorageQuotaUsage($AccessToken);

            Write-Progress -Id $ActivityId -Activity "Summarizing Subscription $($item.DisplayName)" -Status "Retrieving Compute Quota Usage" -PercentComplete 65
            $Result.ComputeQuotaUsage=[ComputeQuotaUsage[]]$item.ComputeQuotaUsage($AccessToken);

            Write-Progress -Id $ActivityId -Activity "Summarizing Subscription $($item.DisplayName)" -Status "Retrieving Available VM Sizes" -PercentComplete 65
            $Result.AvailableVmSizes=[VmSize[]]$item.AvailableVmSizes($AccessToken);

            if($Metrics.IsPresent)
            {
                Write-Progress -Id $ActivityId -Activity "Summarizing Subscription $($item.DisplayName)" -Status "Retrieving Metrics" -PercentComplete 75
                $Result.MetricValues=$item.ResourceMetrics($AccessToken,$Start.ToLocalTime(),$End.ToLocalTime(),$AggregationType,$MetricGranularity)
            }
            if($Usage.IsPresent)
            {
                Write-Progress -Id $ActivityId -Activity "Summarizing Subscription $($item.DisplayName)" -Status "Retrieving Usage Aggregates" -PercentComplete 85
                $Result.UsageAggregates=$item.UsageAggregates($AccessToken,$Start,$End,$true,$UsageGranularity)
            }

            Write-Progress -Id $ActivityId -Activity "Summarizing Subscription $($item.DisplayName)" -Completed
            Write-Output $Result
        }
    }
}

Function Get-SubscriptionSummary
{
    [CmdletBinding(ConfirmImpact='None')]
    param
    (
        [Parameter(Mandatory=$true)]
        [String]
        $AccessToken,
        [Parameter(Mandatory=$false)]
        [System.Uri]
        $ArmFrontDoorUri='https://management.azure.com',
        [Parameter(Mandatory=$true)]
        [String]
        $OfferId,
        [Parameter(Mandatory=$true)]
        [datetime]
        $End,
        [Parameter(Mandatory=$true)]
        [datetime]
        $Start,
        [Parameter(Mandatory=$false)]
        [String]
        $Region="US",
        [Parameter(Mandatory=$false)]
        [String]
        $Locale="en-US",
        [ValidateSet('Average','Maximum','Minimum','Total')]
        [Parameter(Mandatory=$false)]
        [String]
        $AggregationType="Average",
        [Parameter(Mandatory=$false)]
        [String]
        $MetricGranularity="PT1H",
        [ValidateSet('Hourly','Daily')]
        [Parameter(Mandatory=$false)]
        [String]
        $UsageGranularity="Hourly",
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
        $SubscriptionFilter={$_.DisplayName -ne 'Access To Azure Active Directory'}
    )
    Write-Verbose "Using ARM Front Door:$ArmFrontDoorUri"
    [SubscriptionInstance]::ARMFrontDoorUri=$ArmFrontDoorUri
    [ResourceBase]::ARMFrontDoorUri=$ArmFrontDoorUri
    [SubscriptionInstance[]]$Subscriptions=Get-ArmSubscription -AccessToken $AccessToken -ApiEndpoint $ArmFrontDoorUri|Where-Object -FilterScript $SubscriptionFilter
    for ($i = 0; $i -lt $Subscriptions.Count; $i++)
    {
        $Subscription=$Subscriptions[$i]
        $Subscription.VerbosePreference=$VerbosePreference
        Write-Progress -Activity "Gathering Subscription Summaries" -Status "Gathering summary of $($Subscription.DisplayName) subscription" -PercentComplete ((($i+1)/$Subscriptions.Count) * 100)
        Write-Output $Subscription|GetSubscriptionSummary -AccessToken $AccessToken -OfferId $OfferId `
            -Start $Start -End $End -Region $Region -Locale $Locale `
            -AggregationType $AggregationType -MetricGranularity $MetricGranularity -UsageGranularity $UsageGranularity `
            -InstanceData:$InstanceData.IsPresent `
            -Usage:$Usage.IsPresent -Metrics:$Metrics.IsPresent -ArmFrontDoorUri $ArmFrontDoorUri
    }
    Write-Progress -Activity "Gathering Subscription Summaries" -Completed
}

Function Get-TenantSummary
{
    [CmdletBinding(ConfirmImpact='None')]
    param
    (
        [Parameter(Mandatory=$true)]
        [String[]]
        $TenantId,
        [Parameter(Mandatory=$true)]
        [String]
        $AccessToken,
        [Parameter(Mandatory=$true)]
        [datetime]
        $Start,
        [Parameter(Mandatory=$true)]
        [datetime]
        $End,
        [Parameter(Mandatory=$false)]
        [Switch]
        $Events,
        [Parameter(Mandatory=$false)]
        [Switch]
        $OauthPermissionGrants,
        [Parameter(Mandatory=$false)]
        [Switch]
        $ServicePrincipals,
        [Parameter(Mandatory=$false)]
        [Switch]
        $Applications
    )
    [TenantInstance[]]$Tenants=$TenantId|Select-Object -Property @{N='Value';E={[TenantInstance]::new($_)}}|Select-Object -ExpandProperty Value
    Write-Output $Tenants|GetTenantSummary -AccessToken $AccessToken `
    -Events:$TenantEvents.IsPresent -OAuthPermissionGrants:$OAuthPermissionGrants.IsPresent `
    -Applications:$Applications.IsPresent -ServicePrincipals:$ServicePrincipals.IsPresent `
    -Start $Start -End $End
}

#region Graph Export

Function Export-TenantUsers
{
    [CmdletBinding(ConfirmImpact='None')]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [TenantSummary[]]$Summary
    )
    BEGIN
    {

    }
    PROCESS
    {
        foreach ($item in $Summary)
        {
            $SelectScope=@('AccountEnabled','AlternativeSignInNamesInfo','City','CompanyName','Country','CreationType',
            'DeletionTimestamp','Department','Description','DirSyncEnabled','DisplayName','FacsimileTelephoneNumber',
            @{N='AssignedLicensesSku';E={$_.AssignedLicenses|Select-Object -ExpandProperty SkuId}},
            @{N='AssignedPlansAssignedTimestamp';E={$_.AssignedPlans|Select-Object -ExpandProperty AssignedTimestamp}},
            @{N='AssignedPlansServicePlanId';E={$_.AssignedPlans|Select-Object -ExpandProperty ServicePlanId}},
            @{N='AssignedPlansCapabilityStatus';E={$_.AssignedPlans|Select-Object -ExpandProperty CapabilityStatus}},
            @{N='AssignedPlansService';E={$_.AssignedPlans|Select-Object -ExpandProperty Service}},
            @{N='ThumbnailEditLink';E={$_|Select-Object -ExpandProperty 'ThumbnailPhoto@odata.mediaEditLink'}}
            'PasswordPolicies',
            @{N='ForceChangePasswordNextLogin';E={$_.PasswordProfile|Select-Object -ExpandProperty ForceChangePasswordNextLogin}}
            'GivenName','ImmutableId','IsCompromised','JobTitle','LastDirSyncTime','Mail','MailNickname','Mobile','ObjectId','ObjectType',
            'OnPremisesSecurityIdentifier','OtherMails','PasswordProfile','PhysicalDeliveryOfficeName','PostalCode',
            'PreferredLanguage','ProvisioningErrors','ProxyAddresses','SipProxyAddress','State','StreetAddress',
            'Surname','TelephoneNumber','UsageLocation','UserPrincipalName','UserType')
            Write-Output $item.Users|Select-Object -Property $SelectScope
        }
    }
    END
    {

    }
}

Function Export-TenantGroups
{
    [CmdletBinding(ConfirmImpact='None')]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [TenantSummary[]]$Summary
    )
    BEGIN
    {

    }
    PROCESS
    {
        foreach ($item in $Summary)
        {
            $SelectScope=@('DeletionTimestamp','Description','DirSyncEnabled','DisplayName','LastDirSyncTime',
                                'Mail','MailEnabled','MailNickname','ObjectId','ObjectType',
                                'OnPremisesSecurityIdentifier','ProvisioningErrors','ProxyAddresses','SecurityEnabled'
                            )
            Write-Output $item.Groups|Select-Object -Property $SelectScope
        }
    }
    END
    {

    }
}

Function Export-TenantRoles
{
    [CmdletBinding(ConfirmImpact='None')]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [TenantSummary[]]$Summary
    )
    BEGIN
    {

    }
    PROCESS
    {
        foreach ($item in $Summary)
        {
            $SelectScope=@('DeletionTimestamp','Description','DisplayName','IsSystem','ObjectId','ObjectType','RoleDisabled','RoleTemplateId')
            Write-Output $item.Roles|Select-Object -Property $SelectScope
        }
    }
    END
    {

    }
}

Function Export-TenantAuditEvents
{
    [CmdletBinding(ConfirmImpact='None')]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [TenantSummary[]]$Summary
    )
    BEGIN
    {

    }
    PROCESS
    {
        foreach ($item in $Summary)
        {
            $SelectScope=@('Activity','ActivityDate','ActivityDateInMillis','ActivityOperationType',
                'ActivityResultDescription','ActivityResultStatus','ActivityType','Actor','ActorType',
                'AdditionalDetails','Category','ComponentOrSource','CorrelationId','DomainName',
                'Id','InternalCorrelationId','Source','TenantGeolocation','TenantId','TenantName',
                @{N='ActorName';E={$_.Actor.Name}},
                @{N='ActorIpAddress';E={$_.Actor.IPAddress}},
                @{N='ActorObjectId';E={$_.Actor.ObjectId}},
                @{N='ActorServicePrincipalName';E={$_.Actor.ServicePrincipalName}}
            )
            Write-Output $item.AuditEvents|Select-Object -Property $SelectScope
        }
    }
    END
    {

    }
}

Function Export-TenantSigninEvents
{
    [CmdletBinding(ConfirmImpact='None')]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [TenantSummary[]]$Summary
    )
    BEGIN
    {

    }
    PROCESS
    {
        foreach ($item in $Summary)
        {
            $SelectScope=@('AppDisplayName','AppId','DeviceInformation',
                @{N='Latitude';E={$_.GeoCoordinates.Latitude}},
                @{N='Longitude';E={$_.GeoCoordinates.Longitude}},
                @{N='City';E={$_.GeoCoordinates.City}},
                @{N='Country';E={$_.GeoCoordinates.Country}},
                @{N='State';E={$_.GeoCoordinates.State}},
                'Id','IpAddress','LoginStatus',
                'SigninDateTime','SigninDateTimeInMillis','UserDisplayName','UserId','UserPrincipalName')
            Write-Output $item.SigninEvents|Select-Object -Property $SelectScope
        }
    }
    END
    {

    }
}

Function Export-TenantRoleTemplates
{
    [CmdletBinding(ConfirmImpact='None')]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [TenantSummary[]]$Summary
    )
    PROCESS
    {
        foreach ($item in $Summary)
        {
            $SelectScope=@('DisplayName','Description','ObjectId','ObjectType','DeletionTimestamp')
            Write-Output $item.RoleTemplates|Select-Object -Property $SelectScope
        }
    }
}

Function Export-TenantOauthPermissionGrants
{
    [CmdletBinding(ConfirmImpact='None')]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [TenantSummary[]]$Summary
    )
    PROCESS
    {
        foreach ($item in $Summary)
        {
            $SelectScope=@('ClientId','ConsentType','ExpiryTime','ObjectId','PrincipalId','ResourceId','Scope','StartTime')
            Write-Output $item.OauthPermissionGrants|Select-Object -Property $SelectScope
        }
    }
}

Function Export-TenantApplications
{
    [CmdletBinding(ConfirmImpact='None')]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [TenantSummary[]]$Summary
    )
    PROCESS
    {
        foreach ($item in $Summary)
        {
            $SelectScope=@('AppId','ObjectType','DisplayName','ObjectId','Oauth2Permissions','HomePage','Oauth2AllowImplicitFlow',
                'Oauth2AllowUrlPathMatching','Oauth2RequirePostResponse','PublicClient','GroupMembershipClaims','AvailableToOtherTenants'
            )
            Write-Output $item.Applications|Select-Object -Property $SelectScope
        }
    }
}

Function Export-TenantServicePrincipals
{
    [CmdletBinding(ConfirmImpact='None')]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [TenantSummary[]]$Summary
    )
    PROCESS
    {
        foreach ($item in $Summary)
        {
            $SelectScope=@('AppId','ObjectType','DisplayName','ObjectId','AccountEnabled'
                ,'Oauth2Permissions','HomePage','AlternativeNames',
                'AppDisplayName','AppOwnerTenantId','PublisherName','ServicePrincipalNames','ServicePrincipalType',
                'AppRoleAssignmentRequired','Tags'
            )
            Write-Output $item.ServicePrincipals|Select-Object -Property $SelectScope
        }
    }
}

#endregion

#region ARM Export

Function Export-SubscriptionResources
{
    [CmdletBinding(ConfirmImpact='None')]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [SubscriptionSummary[]]
        $Summary
    )
    BEGIN
    {

    }
    PROCESS
    {
        foreach ($item in $Summary)
        {
            $SelectScope=@('Id','Kind','Name','Type','Location',
                @{N='SkuName';E={$_.Sku.Name}},
                @{N='SkuTier';E={$_.Sku.Tier}}
            )
            Write-Output $item.Resources|Select-Object -Property $SelectScope
        }
    }
    END
    {
    }
}

Function Export-SubscriptionStorageQuotaUsage
{
    [CmdletBinding(ConfirmImpact='None')]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [SubscriptionSummary[]]
        $Summary
    )
    BEGIN
    {

    }
    PROCESS
    {
        foreach ($item in $Summary)
        {
            if ($item.StorageQuotaUsage -ne $null) {
                $SelectScope=@()
                $SelectScope=@('Unit','CurrentValue','Limit',
                    @{N='Name';E={$_.Name.Value}}
                    @{N='LocalizedName';E={$_.Name.LocalizedValue}}
                )
                Write-Output $item.StorageQuotaUsage|Select-Object -Property $SelectScope
            }
        }
    }
    END
    {

    }
}

Function Export-SubscriptionComputeQuotaUsage
{
    [CmdletBinding(ConfirmImpact='None')]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [SubscriptionSummary[]]
        $Summary
    )
    BEGIN
    {

    }
    PROCESS
    {
        foreach ($item in $Summary)
        {
            if($item.ComputeQuotaUsage -ne $null)
            {
                $SelectScope=@('Unit','CurrentValue','Limit','Location'
                    @{N='Name';E={$_.Name.Value}}
                    @{N='LocalizedName';E={$_.Name.LocalizedValue}}
                )
                Write-Output $item.ComputeQuotaUsage|Select-Object -Property $SelectScope
            }
        }
    }
    END
    {

    }
}

Function Export-SubscriptionMetricSet
{
    [CmdletBinding(ConfirmImpact='None')]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [SubscriptionSummary[]]
        $Summary
    )
    BEGIN
    {

    }
    PROCESS
    {
        foreach ($item in $Summary)
        {
            #Group by resource
            $ResourceMetricGroups=$item.MetricValues|Sort-Object -Property TimeStamp -Descending|Group-Object -Property ResourceId
            foreach ($ResourceMetricGroup in $ResourceMetricGroups)
            {
                Write-Verbose "Resource $($ResourceMetricGroup.Name)"
                $MetricTypeGroups=$ResourceMetricGroup.Group|Group-Object {$_.Name.Value}
                foreach ($MetricTypeGroup in $MetricTypeGroups)
                {
                    Write-Verbose "Metric $($MetricTypeGroup.Name)"
                    $SelectScope=@('ResourceId','TimeStamp','ResourceType'
                        @{N='LocalizedMetricName';E={$_.Name.LocalizedValue}},
                        @{N='MetricName';E={$_.Name.Value}},
                        'MetricValue'
                    )
                    Write-Output $MetricTypeGroup.Group|Select-Object -Property $SelectScope
                }
            }
        }
    }
    END
    {

    }
}

Function Export-SubscriptionRecommendations
{
    [CmdletBinding(ConfirmImpact='None')]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [SubscriptionSummary[]]
        $Summary
    )
    BEGIN
    {

    }
    PROCESS
    {
        foreach ($item in $Summary)
        {
            $SelectScope=@('Name',
                @{'N'='Category';'E'={$_.Properties.Category}},
                @{'N'='Impact';'E'={$_.Properties.Impact}},
                @{'N'='ResourceType';'E'={$_.Properties.ImpactedField}},
                @{'N'='ResourceName';'E'={$_.Properties.ImpactedValue}},
                @{'N'='Risk';'E'={$_.Properties.Risk}},
                @{'N'='Problem';'E'={$_.Properties.ShortDescription.Problem}},
                @{'N'='Solution';'E'={$_.Properties.ShortDescription.Solution}}
            )
            Write-Output $item.AdvisorRecommendations|Select-Object -Property $SelectScope
        }
    }
    END
    {

    }
}

Function Export-SubscriptionEventlog
{
    [CmdletBinding(ConfirmImpact='None')]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [SubscriptionSummary[]]
        $Summary
    )
    BEGIN
    {

    }
    PROCESS
    {
        foreach ($item in $Summary)
        {
            if($item.EventLogEntries -ne $null)
            {
                $SelectScope=@('EventTimestamp','SubmissionTimestamp','SubscriptionId',
                    'Level','CorrelationId','EventDataId','OperationId','Caller'
                    'Id','ResourceUri','Channels','ResourceGroupName',
                    @{'N'='ResourceProviderName';'E'={$_.ResourceProviderName.Value}},
                    @{'N'='EventName';'E'={$_.EventName.Value}},
                    @{'N'='EventLocalizedName';'E'={$_.EventName.LocalizedValue}},
                    @{'N'='EventSource';'E'={$_.EventSource.Value}},
                    @{'N'='EventLocalizedSource';'E'={$_.EventSource.LocalizedValue}},
                    @{'N'='OperationName';'E'={$_.OperationName.Value}},
                    @{'N'='OperationLocalizedName';'E'={$_.OperationName.LocalizedValue}},
                    @{'N'='LocalizedStatus';'E'={$_.Status.LocalizedValue}},
                    @{'N'='Status';'E'={$_.Status.Value}},
                    @{'N'='LocalizedSubStatus';'E'={$_.SubStatus.LocalizedValue}},
                    @{'N'='SubStatus';'E'={$_.SubStatus.Value}},
                    @{'N'='HttpClientRequestId';'E'={$_.HttpRequest.ClientRequestId}},
                    @{'N'='HttpClientIpAddress';'E'={$_.HttpRequest.ClientIpAddress}},
                    @{'N'='HttpMethod';'E'={$_.HttpRequest.Method}}
                )
                Write-Output $item.EventLogEntries|Sort-Object -Property 'EventTimestamp'|Select-Object -Property $SelectScope
            }
        }
    }
    END
    {

    }
}

Function Export-SubscriptionUsageAggregates
{
    [CmdletBinding(ConfirmImpact='None')]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [SubscriptionSummary[]]
        $Summary
    )
    BEGIN
    {

    }
    PROCESS
    {
        foreach ($item in $Summary)
        {
            if ($item.UsageAggregates -ne $null)
            {
                $SelectScope=@('SubscriptionId','MeterId','MeterCategory',
                   'MeterName','MeterSubCategory','MeterRegion','Unit','Quantity',
                   @{N='Project';E={$_.InfoFields.Project}}
                )
                Write-Output $item.UsageAggregates|Select-Object -ExpandProperty 'Properties'|Select-Object -Property $SelectScope
            }
        }
    }
    END
    {

    }
}

Function Export-SubscriptionRateCard
{
    [CmdletBinding(ConfirmImpact='None')]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [SubscriptionSummary[]]
        $Summary
    )
    BEGIN
    {

    }
    PROCESS
    {
        foreach ($item in $Summary)
        {
            if($item.RateCard -ne $null)
            {
                $SelectScope=@('MeterId','MeterName','EffectiveDate',
                    'IncludedQuantity','MeterCategory','MeterRegion',
                    'MeterSubCategory','MeterTags','Unit',
                    @{
                        N='MeterRates';
                        E={$_.MeterRates|ForEach-Object{($_|Get-Member -MemberType NoteProperty|Select-Object -ExpandProperty Definition).Replace('decimal ','')}};
                    }
                )
                Write-Output $item.RateCard.Meters|Sort-Object -Property EffectiveDate|Select-Object -Property $SelectScope
            }
        }
    }
    END
    {

    }
}

Function Export-SubscriptionRoleDefinitions
{
    [CmdletBinding(ConfirmImpact='None')]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [SubscriptionSummary[]]
        $Summary
    )
    BEGIN
    {

    }
    PROCESS
    {
        foreach ($item in $Summary)
        {
            if ($item.RoleDefinitions -ne $null)
            {
                $SelectScope=@('Id','Name',
                    @{N="Description";E={$_.Properties.Description}},
                    @{N="RoleName";E={$_.Properties.RoleName}},
                    @{N="Type";E={$_.Properties.Type}},
                    @{N="CreatedOn";E={$_.Properties.CreatedOn}},
                    @{N="CreatedBy";E={$_.Properties.CreatedBy}},
                    @{N="UpdatedOn";E={$_.Properties.UpdatedOn}},
                    @{N="UpdatedBy";E={$_.Properties.UpdatedBy}},
                    @{N="AssignableScopes";E={$_.Properties.AssignableScopes}},
                    @{N="Actions";E={$_.Properties.Actions}},
                    @{N="NonActions";E={$_.Properties.NonActions}}
                )
                Write-Output $item.RoleDefinitions|Select-Object -Property $SelectScope
            }
        }
    }
    END
    {

    }
}

Function Export-SubscriptionRoleAssignments
{
    [CmdletBinding(ConfirmImpact='None')]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [SubscriptionSummary[]]
        $Summary
    )
    BEGIN
    {

    }
    PROCESS
    {
        foreach ($item in $Summary)
        {
            if ($item.RoleAssignments -ne $null -and $item.RoleDefinitions -ne $null)
            {
                $RoleDefinitionSet=$item.RoleDefinitions|Select-Object -Property @('Id',
                        @{N='Name';E={$_.Properties.RoleName}},
                        @{N='Description';E={$_.Properties.Description}},
                        @{N='Type';E={$_.Properties.Type}}
                )
                $SelectScope=@('Id','Name',
                    @{N="RoleDefinitionId";E={$_.Properties.RoleDefinitionId}},
                    @{N="PrincipalId";E={$_.Properties.PrincipalId}},
                    @{N="Scope";E={$_.Properties.Scope}},
                    @{N="CreatedOn";E={$_.Properties.CreatedOn}},
                    @{N="CreatedBy";E={$_.Properties.CreatedBy}},
                    @{N="UpdatedOn";E={$_.Properties.UpdatedOn}},
                    @{N="UpdatedBy";E={$_.Properties.UpdatedBy}},
                    @{N='RoleType';E={$RoleDefinitionSet|Where-Object Id -eq $_.Properties.RoleDefinitionId|Select-Object -ExpandProperty Type}},
                    @{N='RoleName';E={$RoleDefinitionSet|Where-Object Id -eq $_.Properties.RoleDefinitionId|Select-Object -ExpandProperty Name}},
                    @{N='RoleDescription';E={$RoleDefinitionSet|Where-Object Id -eq $_.Properties.RoleDefinitionId|Select-Object -ExpandProperty Description}}
                )
                Write-Output $item.RoleAssignments|Select-Object -Property $SelectScope
            }
        }
    }
    END
    {

    }
}

Function Export-SubscriptionPolicyDefinitions
{
    [CmdletBinding(ConfirmImpact='None')]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [SubscriptionSummary[]]
        $Summary
    )
    BEGIN
    {

    }
    PROCESS
    {
        foreach ($item in $Summary)
        {
            if ($item.PolicyDefinitions -ne $null)
            {
                $SelectScope=@('Id','Name',
                    @{N="DisplayName";E={$_.Properties.DisplayName}},
                    @{N="Description";E={$_.Properties.Description}},
                    @{N="PolicyType";E={$_.Properties.PolicyType}}
                )
                Write-Output $item.PolicyDefinitions|Select-Object -Property $SelectScope
            }
        }
    }
    END
    {

    }
}

Function Export-SubscriptionPolicyAssignments
{
    [CmdletBinding(ConfirmImpact='None')]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [SubscriptionSummary[]]
        $Summary
    )
    BEGIN
    {

    }
    PROCESS
    {
        foreach ($item in $Summary)
        {
            $PolicyDefinitions=$item.PolicyDefinitions|Select-Object -Property @('Id','Name',
                    @{N="DisplayName";E={$_.Properties.DisplayName}},
                    @{N="Description";E={$_.Properties.Description}},
                    @{N="PolicyType";E={$_.Properties.PolicyType}}
                )
            if($item.PolicyAssignments -ne $null -and $item.PolicyDefinitions -ne $null)
            {
                $SelectScope=@('Id','Name',
                    @{N="Scope";E={$_.Properties.Scope}},
                    @{N="PolicyDefinitionId";E={$_.Properties.PolicyDefinitionId}},
                    @{N="PolicyName";E={$PolicyDefinitions|Where-Object Id -eq $_.Properties.PolicyDefinitionId|Select-Object -ExpandProperty DisplayName}},
                    @{N="PolicyDescription";E={$PolicyDefinitions|Where-Object Id -eq $_.Properties.PolicyDefinitionId|Select-Object -ExpandProperty Description}},
                    @{N="PolicyType";E={$PolicyDefinitions|Where-Object Id -eq $_.Properties.PolicyDefinitionId|Select-Object -ExpandProperty PolicyType}}
                )
                Write-Output $item.PolicyAssignments|Select-Object -Property $SelectScope
            }
        }
    }
    END
    {

    }
}

Function Export-SubscriptionResourceLocks
{
    [CmdletBinding(ConfirmImpact='None')]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [SubscriptionSummary[]]
        $Summary
    )
    BEGIN
    {

    }
    PROCESS
    {
        foreach ($item in $Summary)
        {
            if($item.ResourceLocks -ne $null)
            {
                $SelectScope=@('Id','Name',
                    @{N="Level";E={$_.Properties.Level}},
                    @{N="Notes";E={$_.Properties.Notes}}
                )
                Write-Output $item.ResourceLocks|Select-Object -Property $SelectScope
            }
        }
    }
    END
    {

    }
}

Function Export-SubscriptionTagNameReport
{
    [CmdletBinding(ConfirmImpact='None')]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [SubscriptionSummary[]]
        $Summary
    )
    BEGIN
    {

    }
    PROCESS
    {
        foreach ($item in $Summary)
        {
            if($item.TagNameReport -ne $null)
            {
                foreach ($TagNameItem in $item.TagNameReport)
                {
                    foreach ($TagValue in $TagNameItem.Values)
                    {
                        $SelectScope=@(
                            'TagValue',
                            @{N="ValueCountType";E={$_.Count.Type}},
                            @{N="ValueCountValue";E={$_.Count.Value}},
                            @{N="TagNameId";E={$TagNameItem.Id}},
                            @{N="TagName";E={$TagNameItem.TagName}},
                            @{N="NameCountType";E={$TagNameItem.Count.Type}},
                            @{N="NameCountValue";E={$TagNameItem.Count.Value}}
                        )
                        Write-Output $TagValue|Select-Object -Property $SelectScope
                    }
                }
            }
        }
    }
    END
    {

    }
}

Function Export-SubscriptionVmSizes
{
    [CmdletBinding(ConfirmImpact='None')]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [SubscriptionSummary[]]
        $Summary
    )
    BEGIN
    {

    }
    PROCESS
    {
        foreach ($item in $Summary)
        {
            if($item.AvailableVmSizes -ne $null)
            {
                Write-Output $item.AvailableVmSizes
            }
        }
    }
    END
    {

    }
}

#endregion

#endregion

Function Get-AzureDetailReport
{
    [CmdletBinding(ConfirmImpact='None')]
    param
    (
        [Parameter(Mandatory=$true)]
        [String[]]
        $TenantId,
        [Parameter(Mandatory=$true)]
        [String]
        $GraphAccessToken,
        [Parameter(Mandatory=$true)]
        [String]
        $ArmAccessToken,
        [Parameter(Mandatory=$false)]
        [System.Uri]
        $ArmFrontDoorUri='https://management.azure.com',
        [Parameter(Mandatory=$true)]
        [String]
        $OfferId,
        [Parameter(Mandatory=$true)]
        [datetime]
        $End,
        [Parameter(Mandatory=$true)]
        [datetime]
        $Start,
        [Parameter(Mandatory=$false)]
        [String]
        $Region="US",
        [Parameter(Mandatory=$false)]
        [String]
        $Locale="en-US",
        [ValidateSet('Average','Maximum','Minimum','Total')]
        [Parameter(Mandatory=$false)]
        [String]
        $MetricAggregationType="Average",
        [Parameter(Mandatory=$false)]
        [String]
        $MetricGranularity="PT1H",
        [ValidateSet('Hourly','Daily')]
        [Parameter(Mandatory=$false)]
        [String]
        $UsageGranularity="Hourly",
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
        $SubscriptionFilter={$_.DisplayName -ne 'Access To Azure Active Directory'},
        [Parameter(Mandatory=$false)]
        [Switch]
        $TenantEvents,
        [Parameter(Mandatory=$false)]
        [Switch]
        $OauthPermissionGrants,
        [Parameter(Mandatory=$false)]
        [Switch]
        $ServicePrincipals,
        [Parameter(Mandatory=$false)]
        [Switch]
        $Applications,
        [Parameter(Mandatory=$false)]
        [Switch]
        $ResourcesOnly,
        [Parameter(Mandatory=$false)]
        [Switch]
        $TenantOnly
    )

    $Report=[DetailReport]::new()

    if ($TenantOnly.IsPresent -or $ResourcesOnly.IsPresent -eq $false) {
        #Get the Tenant Summaries
        [TenantSummary[]]$TenantSummaries=@(Get-TenantSummary -TenantId $TenantId -AccessToken $GraphAccessToken `
            -Start $Start -End $End `
            -Events:$TenantEvents.IsPresent `
            -OAuthPermissionGrants:$OAuthPermissionGrants.IsPresent `
            -Applications:$Applications.IsPresent `
            -ServicePrincipals:$ServicePrincipals.IsPresent
        )
        $Report.Summaries+=$TenantSummaries
    }

    #Get the Subscription Summaries
    [SubscriptionSummary[]]$SubscriptionSummaries=@(Get-SubscriptionSummary -AccessToken $ArmAccessToken `
        -OfferId $OfferId -End $End -Start $Start `
        -Region $Region -Locale $Locale `
        -AggregationType $MetricAggregationType -MetricGranularity $MetricGranularity `
        -UsageGranularity $UsageGranularity -InstanceData:$InstanceData.IsPresent `
        -Usage:$Usage.IsPresent -Metrics:$Metrics.IsPresent `
        -ArmFrontDoorUri $ArmFrontDoorUri -SubscriptionFilter $SubscriptionFilter
    )
    $Report.Summaries+=$SubscriptionSummaries
    Write-Output $Report
}
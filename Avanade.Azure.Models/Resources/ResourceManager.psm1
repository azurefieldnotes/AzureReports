using module .\BaseItems.psm1
using module .\Commerce.psm1
using module .\Events.psm1
using module .\Metrics.psm1
using module .\Policies.psm1
using module .\Roles.psm1

#region Advisor

Class ArmSuggestionSubscription
{
    [String]$Problem
    [String]$Solution
}

Class ArmSuggestionProperties
{
    [String]$Category
    [String]$Impact
    [String]$ImpactedField
    [String]$ImpactedValue
    [System.DateTimeOffset]$LastUpdated
    [String]$Risk
    [ArmSuggestionSubscription]$ShortDescription
}

Class ArmAdvisorRecommendation:ArmResource
{
    [ArmSuggestionProperties]$Properties
}

#endregion

#region Subscription

Class ArmSubscriptionPolicies
{
    [string]$LocationPlacementId
    [string]$QuotaId
    [String]$SpendingLimit
}

Class ArmSubscriptionBase:ArmItem
{
    [string]$SubscriptionId
    [string]$State
    [string]$DisplayName
    [ArmSubscriptionPolicies]$SubscriptionPolicies
    [string]$AuthorizationSource

    hidden [void] TestId(){
        if([string]::IsNullOrEmpty($this.SubscriptionId)){
            throw "A subscription Id must be present"
        }
    }

    [ArmResourceBase[]]Resources([string]$AccessToken)
    {
        throw "This must be overloaded in an implementing class"
    }

    [ArmResourceBase[]]Resources([string]$AccessToken,[bool]$InstanceView)
    {
        throw "This must be overloaded in an implementing class"
    }

    [ArmUsageAggregate[]]UsageAggregates([string]$AccessToken,[DateTime]$Start,[DateTime]$End,[bool]$ShowDetails,[string]$Granularity)
    {
        throw "This must be overloaded in an implementing class"
    }

    [ArmRateCard]RateCard([string]$AccessToken,[string]$OfferCode,[string]$Region,[string]$Locale)
    {
        throw "This must be overloaded in an implementing class"
    }

    [ArmEventLogEntry[]]EventLog([string]$AccessToken)
    {
        throw "This must be overloaded in an implementing class"
    }

    [ArmNormalizedMetricValue[]]ResourceMetrics([string]$AccessToken,[DateTime]$Start,[DateTime]$End,[string]$AggregationType,[string]$Granularity)
    {
        throw "This must be overloaded in an implementing class"
    }

    [ArmAdvisorRecommendation[]]AdvisorRecommendations([string]$AccessToken)
    {
        throw "This must be overloaded in an implementing class"
    }

    [ArmPreviewFeature[]]PreviewFeatures([string]$AccessToken)
    {
        throw "This must be overloaded in an implementing class"
    }

    [ArmResourceProvider[]]ResourceProviders([string]$AccessToken)
    {
        throw "This must be overloaded in an implementing class"
    }

    [ArmRoleDefinition[]]RoleDefinitions([string]$AccessToken)
    {
        throw "This must be overloaded in an implementing class"
    }

    [ArmRoleAssignment[]]RoleAssignments([string]$AccessToken)
    {
        throw "This must be overloaded in an implementing class"
    }

    [ArmPolicyDefinition[]]PolicyDefinitions([string]$AccessToken)
    {
        throw "This must be overloaded in an implementing class"
    }

    [ArmPolicyAssignment[]]PolicyAssignments([string]$AccessToken)
    {
        throw "This must be overloaded in an implementing class"
    }

    [ArmResourceLock[]]ResourceLocks([string]$AccessToken)
    {
        throw "This must be overloaded in an implementing class"
    }

    [ArmQuotaUsage[]]StorageQuotaUsage([string]$AccessToken)
    {
        throw "This must be overloaded in an implementing class"
    }

    [ArmQuotaUsage[]]ComputeQuotaUsage([string]$AccessToken,[string]$Location)
    {
        throw "This must be overloaded in an implementing class"
    }

    [ArmQuotaUsage[]]ComputeQuotaUsage([string]$AccessToken)
    {
        throw "This must be overloaded in an implementing class"
    }

    [ArmVmSize[]]AvailableVmSizes([string]$AccessToken,[string]$Location)
    {
        throw "This must be overloaded in an implementing class"
    }

    [ArmVmSize[]]AvailableVmSizes([string]$AccessToken)
    {
        throw "This must be overloaded in an implementing class"
    }

    [ArmTagName[]]TagNameReport([string]$AccessToken)
    {
        throw "This must be overloaded in an implementing class"
    }

}

#endregion

#region Resources

Class ArmQuotaUsage
{
    [string]$Unit
    [int]$CurrentValue
    [int]$Limit
    [ArmLocalizedName]$Name
}

Class ArmPreviewFeature:ArmResource
{
    [ArmFeatureProperties]$Properties
}

Class ArmResourceType
{
    [string]$ResourceType
    [string[]]$Locations
    [string[]]$ApiVersions
    [string]$Capabilities
}

Class ArmResourceProvider:ArmItem
{
    [String]$Namespace
    [ArmResourceType[]]$ResourceTypes
    [Object[]]$Authorization
    [Object[]]$Authorizations
    [String]$RegistrationState
}

Class ArmResourceLockProperties
{
    [string]$Level
    [string]$Notes
}

Class ArmResourceLock:ArmResource
{
    [ArmResourceLockProperties]$Properties
}

Class ProductSku
{
    [string]$Name
    [string]$Tier
    [string]$Size
    [string]$Family
    [int]$Capacity
}

Class ArmResourcePlan
{
    [string]$ManagedBy
    [string]$Name
    [string]$PromotionCode
    [string]$Product
    [string]$Publisher
}

Class ArmResourceBase:ArmResource
{
    [string]$ManagedBy
    [string]$Location
    [ProductSku]$Sku
    [string]$Kind
    [string]$Tags
    [ArmResourcePlan]$Plan
    [System.Object]$Properties
    [ArmResourceBase[]]$Resources
    [string]$Etag
    [string]$SubscriptionId
    [string]$ResourceGroup
    [string]$Identity

    [bool]SupportsMetrics()
    {
        throw "This must be overloaded in an implementing class"
    }

    [bool]IsClassic()
    {
        throw "This must be overloaded in an implementing class"
    }

    [ArmMetricDefinition[]]MetricDefinitions([string]$AccessToken)
    {
        throw "This must be overloaded in an implementing class"
    }

    [ArmNormalizedMetricValue[]]Metrics([string]$AccessToken,[DateTime]$Start,[DateTime]$End,[string]$AggregationType,[string]$Granularity)
    {
        throw "This must be overloaded in an implementing class"
    }

    [ArmNormalizedMetricValue[]]MetricValues([string]$AccessToken,[ArmMetricDefinition]$MetricDefinition,[DateTime]$Start,[DateTime]$End,[string]$AggregationType,[string]$Granularity)
    {
        throw "This must be overloaded in an implementing class"
    }
}

#endregion

#region Metrics

Class ArmMetricEntry:ArmMetric
{
    [string]$Type
    [ArmMetricValue[]]$Data
}

Class ArmMetricDefinition:ArmItem
{
    [string]$ResourceUri
    [string]$ResourceId
    [ArmLocalizedName]$Name
    [System.DateTimeOffset]$StartTime
    [System.DateTimeOffset]$EndTime
    [string]$PrimaryAggregationType
    [ArmMetricAvailability[]]$MetricAvailabilities
    [object]$Properties
    [string]$Unit
}

Class ArmNormalizedMetricValue
{
    [string]$ResourceId
    [string]$ResourceType
    [ArmLocalizedName]$Name
    [string]$AggregationType
    [string]$PrimaryAggregationType
    [string]$Unit
    [System.DateTimeOffset]$TimeStamp
    [double]$MetricValue
}

Class ArmAverageMetricEntry:ArmMetricEntry
{
    [ArmAverageMetricValue[]]$Data
}

Class ArmMaximumMetricEntry:ArmMetricEntry
{
    [ArmMaximumMetricValue[]]$Data
}

Class ArmMinimumMetricEntry:ArmMetricEntry
{
    [ArmMinimumMetricValue[]]$Data
}

Class ArmTotalMetricEntry:ArmMetricEntry
{
    [ArmTotalMetricValue[]]$Data
}

Class ArmClassicMetricEntry:ArmMetric
{
    [string]$TimeGrain
    [System.DateTimeOffset]$StartTime
    [System.DateTimeOffset]$EndTime
    [ArmClassicMetricValue[]]$MetricValues
    [string]$ResourceId
    [object[]]$Properties
}

#endregion

#region Commerce

Class ArmUsageAggregate:ArmResource
{
    [ArmUsageProperties]$Properties
}

Class ArmRateCard
{
    [ArmResourceMeter[]]$Meters
    [System.Object]$OfferTerms
    [string]$Currency
    [cultureinfo]$Locale
    [bool]$IsTaxIncluded
}

#endregion

Class ArmRoleAssignment:ArmResource
{
    [ArmRoleAssignmentProperties]$Properties
}

Class ArmRoleDefinition:ArmResource
{
    [ArmRoleProperties]$Properties
}

Class ArmEventLogEntry
{
    [ArmEventAuthorization]$Authorization
    [string]$Channels
    [object]$Claims
    [string]$Caller
    [string]$CorrelationId
    [string]$Description
    [string]$EventDataId
    [ArmLocalizedName]$EventName
    [ArmLocalizedName]$EventSource
    [System.DateTimeOffset]$EventTimestamp
    [ArmEventHttpRequest]$HttpRequest
    [string]$Id
    [string]$Level
    [string]$OperationId
    [ArmLocalizedName]$OperationName
    [System.Object]$Properties
    [string]$ResourceGroupName
    [ArmLocalizedName]$ResourceProviderName
    [string]$ResourceUri
    [ArmLocalizedName]$Status
    [System.DateTimeOffset]$SubmissionTimestamp
    [string]$SubscriptionId
    [ArmLocalizedName]$SubStatus
}

Class ArmPolicyDefinition:ArmResource
{
    [ArmPolicyDefinitionProperties]$Properties
}

Class ArmPolicyAssignment:ArmResource
{
    [ArmPolicyAssignmentProperties]$Properties
}

Class ArmTagCount
{
    [string]$Type
    [int]$Value
}

Class ArmTagValue:ArmItem
{
    [string]$TagValue
    [ArmTagCount]$Count
}

Class ArmTagName:ArmItem
{
    [ArmTagCount]$Count
    [string]$TagName
    [ArmTagValue[]]$Values
}

Class ArmVmSize
{
    [string]$Name
    [int]$NumberOfCores
    [int]$OsDiskSizeInMB
    [int]$ResourceDiskSizeInMB
    [int]$MemoryInMB
    [int]$MaxDataDiskCount
}
using module .\BaseItems.psm1

Class ArmResourceMeter
{
    [System.DateTimeOffset]$EffectiveDate
    [decimal]$IncludedQuantity
    [string]$MeterCategory
    [string]$MeterId
    [string]$MeterName
    [object]$MeterRates
    [string]$MeterRegion
    [string]$MeterSubCategory
    [object[]]$MeterTags
    [string]$Unit
}

Class ArmUsageInfoFields
{
    [String]$MeteredRegion
    [String]$MeteredService
    [String]$MeteredServiceType
    [String]$Project
    [string]$ServiceInfo
    [string]$ServiceInfo2
}

Class ArmUsageProperties
{
    [ArmUsageInfoFields]$InfoFields
    [System.Object]$InstanceData
    [string]$MeterCategory
    [string]$MeterId
    [string]$MeterName
    [string]$MeterRegion
    [string]$MeterSubCategory
    [double]$Quantity
    [string]$SubscriptionId
    [string]$Unit
    [DateTimeOffset]$UsageEndTime
    [DateTimeOffset]$UsageStartTime
}
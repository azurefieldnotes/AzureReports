using module .\BaseItems.psm1

Class ArmMetricAvailability
{
    [string]$TimeGrain
    [string]$Retention
}

Class ArmMetricValue
{
    [System.DateTimeOffset]$TimeStamp
}

Class ArmClassicMetricValue:ArmMetricValue
{
    [double]$Average
    [double]$Minimum
    [double]$Maximum
    [double]$Total
    [int]$Count
    [Object[]]$Properties
}

Class ArmAverageMetricValue:ArmMetricValue
{
    [double]$Average
}

Class ArmMaximumMetricValue:ArmMetricValue
{
    [double]$Maximum
}

Class ArmMinimumMetricValue:ArmMetricValue
{
    [double]$Minimum
}

Class ArmTotalMetricValue:ArmMetricValue
{
    [double]$Minimum
}

Class ArmMetric
{
    [string]$Id
    [string]$Unit
    [ArmLocalizedName]$Name
}
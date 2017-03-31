using module .\Resources\ResourceManager.psm1
using module .\Directory\DirectoryGraph.psm1

Class ArmSubscriptionSummaryBase
{
    [ArmSubscriptionBase]$Subscription
}

Class GraphTenantSummaryBase
{
    [GraphTenantBase]$Tenant
}
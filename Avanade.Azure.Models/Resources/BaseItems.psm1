
Class ArmLocalizedName
{
    [string]$Value
    [string]$LocalizedValue
}

Class ArmItem
{
    [string]$Id
}

Class ArmResource:ArmItem
{
    [string]$Name
    [string]$Type
}

Class ArmFeatureProperties
{
    [string]$State
}

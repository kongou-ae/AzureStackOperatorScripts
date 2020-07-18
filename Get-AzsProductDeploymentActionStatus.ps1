param (
    [ValidateSet("microsoft.eventhub" , "microsoft.databoxedge", "microsoft.iothub")]$ProductId
)

$ErrorActionPreference = "stop"

$deployment = Get-AzsProductDeployment -ProductId $ProductId
$deploymentStatus = $deployment.properties.status
$packageId = "$ProductId.$($deployment.properties.deployment.version)"
$deployment.properties.deployment.actionPlanInstanceResourceId -match "actionplans/(.*)" | Out-Null
$actionPlanId = $Matches[1]

$actionPlan = Get-AzsActionPlan -PlanId $actionPlanId

$action = [ordered]@{
    "startTime" = $actionPlan.properties.startTime
    "endTime" = $actionPlan.properties.endTime
    "provisioningState" = $actionPlan.properties.provisioningState
}

$result = [ordered]@{
    "ProductId" = $ProductId
    "PackageId" = $packageId
    "lastAction" = $deploymentStatus
    "lastActionStatus" = $action
}

$result | ConvertTo-Json | convertfrom-json 
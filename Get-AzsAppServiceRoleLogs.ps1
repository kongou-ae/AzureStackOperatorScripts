$ErrorActionPreference = "stop"

function detectRole($roleNumber){

    Switch($roleNumber){
        "1" {$roleName = "Controller";break;}
        "2" {$roleName = "Management";break;}
        "4" {$roleName = "FrontEnd";break;}
        "8" {$roleName = "Worker";break;}
        "16" {$roleName = "Publisher";break;}
    }
    return $roleName
}

$contexts = Get-AzureRmContext
$context = $contexts.TokenCache.ReadItems() | Where-Object {$_.Resource -like "*adminmanagement*"} | Select-Object -First 1

$azsEnv = Get-AzureRmEnvironment | Where-Object {$_.ResourceManagerUrl -like "*adminmanagement*"} 
$fqdn = $azsEnv.ResourceManagerUrl

$azsSub = Get-AzureRmSubscription -SubscriptionName "Default Provider Subscription"
$subId = $azsSub.Id

$authHeader = "Bearer " + $context.AccessToken
$requestHeader = @{
    "Authorization" = $authHeader
    "Accept" = "application/json"
}
$contentType = "application/json;charset=utf-8"


$saveDir = $env:SystemDrive + "\Get-AzsAppServiceRoleLogs-"  + (Get-Date -Format yyyyMMdd-hhmmss)
mkdir $saveDir | Out-Null

$logFilename = $saveDir + "\" + (detectRole($_.properties.role)) + "servers.json"   
$Url = $fqdn + "/subscriptions/" + $subId + "/providers/Microsoft.Web.Admin/locations/local/servers?api-version=2018-02-01"
$res = Invoke-RestMethod -Uri $Url -Method GET -Headers $requestHeader -ContentType $contentType
$res | ConvertTo-Json -Depth 100 | Out-File $logFilename
Write-Output "Created $logFilename"

$logFilename = $saveDir + "\" + (detectRole($_.properties.role)) + "workerTiers.json"   
$Url = $fqdn + "/subscriptions/" + $subId + "/providers/Microsoft.Web.Admin/locations/local/workerTiers?api-version=2018-02-01"
$res = Invoke-RestMethod -Uri $Url -Method GET -Headers $requestHeader -ContentType $contentType
$res | ConvertTo-Json -Depth 100 | Out-File $logFilename
Write-Output "Created $logFilename"

$serverUrl = $fqdn + "/subscriptions/" + $subId + "/providers/Microsoft.Web.Admin/locations/local/servers?api-version=2018-02-01"
$serverRes = Invoke-RestMethod -Uri $serverUrl -Method GET -Headers $requestHeader -ContentType $contentType
$serverRes | foreach {
    $logUrl = $fqdn + "/subscriptions/" + $subId + "/providers/Microsoft.Web.Admin/locations/local/servers/" + $_.name  + "/log?api-version=2018-02-01"
    $logRes = Invoke-RestMethod -Uri $logUrl -Method GET -Headers $requestHeader -ContentType $contentType
 
    $logFilename = $saveDir + "\" + (detectRole($_.properties.role)) + "-" + $_.name + ".json"   
    $logRes.properties | ConvertTo-Json -Depth 100 | Out-File $logFilename
    Write-Output "Created $logFilename"
}



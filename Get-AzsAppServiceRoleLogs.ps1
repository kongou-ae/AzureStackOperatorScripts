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

$azContext = Get-AzureRMContext
$azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
$profileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azProfile)
$token = $profileClient.AcquireAccessToken($azContext.Tenant.TenantId)

$authHeader = "Bearer " + $token.AccessToken
$requestHeader = @{
    "Authorization" = $authHeader
    "Accept" = "application/json"
}

$subId = (Get-AzureRmSubscription).Id
$region = (Get-AzsRegionHealth).Name
$adminManagementUrl = (Get-AzureRmEnvironment -Name AzureStackAdmin).ResourceManagerUrl

$saveDir = $env:SystemDrive + "\Get-AzsAppServiceRoleLogs-"  + (Get-Date -Format yyyyMMdd-hhmmss)
mkdir $saveDir | Out-Null

$logFilename = $saveDir + "\" + (detectRole($_.properties.role)) + "servers.json"   
$Url = $adminManagementUrl + "/subscriptions/" + $subId + "/providers/Microsoft.Web.Admin/locations/$region/servers?api-version=2018-02-01"
$res = Invoke-RestMethod -Uri $Url -Method GET -Headers $requestHeader -ContentType $contentType
$res | ConvertTo-Json -Depth 100 | Out-File $logFilename
Write-Output "Created $logFilename"

$logFilename = $saveDir + "\" + (detectRole($_.properties.role)) + "workerTiers.json"   
$Url = $adminManagementUrl + "/subscriptions/" + $subId + "/providers/Microsoft.Web.Admin/locations/$region/workerTiers?api-version=2018-02-01"
$res = Invoke-RestMethod -Uri $Url -Method GET -Headers $requestHeader -ContentType $contentType
$res | ConvertTo-Json -Depth 100 | Out-File $logFilename
Write-Output "Created $logFilename"

$serverUrl = $adminManagementUrl + "/subscriptions/" + $subId + "/providers/Microsoft.Web.Admin/locations/$region/servers?api-version=2018-02-01"
$serverRes = Invoke-RestMethod -Uri $serverUrl -Method GET -Headers $requestHeader -ContentType $contentType
$serverRes | foreach {
    $logUrl = $adminManagementUrl + "/subscriptions/" + $subId + "/providers/Microsoft.Web.Admin/locations/$region/servers/" + $_.name  + "/log?api-version=2018-02-01"
    $logRes = Invoke-RestMethod -Uri $logUrl -Method GET -Headers $requestHeader -ContentType $contentType
 
    $logFilename = $saveDir + "\" + (detectRole($_.properties.role)) + "-" + $_.name + ".json"   
    $logRes.properties | ConvertTo-Json -Depth 100 | Out-File $logFilename
    Write-Output "Created $logFilename"
}

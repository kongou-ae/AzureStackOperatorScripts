$ErrorActionPreference = "stop"

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

$Url = $adminManagementUrl + "/subscriptions/" + $subId + "/providers/Microsoft.Web.Admin/locations/$region/secrets?api-version=2018-02-01"

$res = Invoke-RestMethod -Uri $Url -Method GET -Headers $requestHeader -ContentType $contentType

$res | format-table category,name,@{
    Label="lifeRemaining"
    Expression= {
        switch ($_.lifeRemaining) {
            { $_ -lt 60 } {$color = "91"; break}
            default {$color = "27"}
        }
        $e = [char]27
        "$e[${color}m$($_.lifeRemaining)${e}[0m"
    }
}

$flag = $true
$res | foreach-Object {
    if ($_.lifeRemaining -lt 60){
        $flag = $false
    }
}

if ($flag -eq $true){
    Write-Host "PASS" -foregroundcolor Greem
} else {
    Write-Host "FAIL" -foregroundcolor Red
    Write-Host "You need a secret rotation in App Sercive Blade" 
}

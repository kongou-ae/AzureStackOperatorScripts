$ErrorActionPreference = "stop"

$azContext = Get-AzContext

if ($azContext.environment.Name -ne "AzureStackAdmin"){
    throw "The your environment name on your context is $($azContext.environment.Name). You need to set AzureStackAdmin to environment name"
}

$azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
$profileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azProfile)
$token = $profileClient.AcquireAccessToken($azContext.Tenant.TenantId)

$authHeader = "Bearer " + $token.AccessToken
$requestHeader = @{
    "Authorization" = $authHeader
    "Accept" = "application/json"
}

$subId = (Get-AzSubscription).Id
$adminManagementUrl = (Get-AzEnvironment -Name AzureStackAdmin).ResourceManagerUrl

$updates = Get-AzsUpdate
$update = $updates | Select-Object Name, Publisher, State | Out-GridView -PassThru -Title "Please select the update which you want to confirm"
$updateRun = Get-AzsUpdateRun -UpdateName $update.Name | Out-GridView -PassThru -Title "Please select the updateRun which you want to confirm"

$updateLocation = ($updateRun.Name -split "/")[0]
$updateName = ($updateRun.Name -split "/")[1]
$updateRunName = ($updateRun.Name -split "/")[2]

$Url = $adminManagementUrl + "/subscriptions/" + $subId + "/resourceGroups/" + "system.$updateLocation" + "/providers/Microsoft.Update.Admin/updateLocations/" + $updateLocation + "/updates/" + $updateName + "/updateRuns/" + $updateRunName + "?api-version=2016-05-01"
$res = Invoke-RestMethod -Uri $Url -Method GET -Headers $requestHeader -ContentType $contentType

$root = @()
$1stCounter = 0
$2ndCounter = 0
$3rdCounter = 0
$4thCounter = 0
$5thCounter = 0

$res.properties.progress.steps | foreach{
    $1stStep = $_ 
    if($1stStep){
        $1stCounter++
        $2ndCounter = 0
        $3rdCounter = 0
        $4thCounter = 0
        $5thCounter = 0

        $root += $1stStep | Select-Object `
                            @{Label="Seq"; Expression={$1stCounter.ToString()}}, `
                            Name,Description,Status,` 
                            @{Label="StartTime"; Expression={Get-Date $_.StartTimeUtc -Format "yyyy-MM-dd HH:mm:ss"}}, `
                            @{Label="EndTime"; Expression={Get-Date $_.EndTimeUtc -Format "yyyy-MM-dd HH:mm:ss"}}
    }

    $1stStep.steps| foreach {
        $2ndStep = $_
        if ($2ndStep){
            $2ndCounter++
            $3rdCounter = 0
            $4thCounter = 0
            $5thCounter = 0
            $root += $2ndStep | Select-Object `
                            @{Label="Seq"; Expression={"$1stCounter.$2ndCounter"}}, `
                            Name,Description,Status,` 
                            @{Label="StartTime"; Expression={Get-Date $_.StartTimeUtc -Format "yyyy-MM-dd HH:mm:ss"}}, `
                            @{Label="EndTime"; Expression={Get-Date $_.EndTimeUtc -Format "yyyy-MM-dd HH:mm:ss"}}
        }

        $2ndStep.steps | foreach {
            $3rdStep = $_
            if ($3rdStep){
                $3rdCounter++
                $4thCounter = 0
                $5thCounter = 0
                $root += $3rdStep | Select-Object `
                            @{Label="Seq"; Expression={"$1stCounter.$2ndCounter.$3rdCounter"}}, `
                            Name,Description,Status,` 
                            @{Label="StartTime"; Expression={Get-Date $_.StartTimeUtc -Format "yyyy-MM-dd HH:mm:ss"}}, `
                            @{Label="EndTime"; Expression={Get-Date $_.EndTimeUtc -Format "yyyy-MM-dd HH:mm:ss"}}
            }
        
            $3rdStep.steps | foreach {
                $4thStep = $_
                if ($4thStep){
                    $4thCounter++
                    $5thCounter = 0
                    $root += $4thStep | Select-Object `
                            @{Label="Seq"; Expression={"$1stCounter.$2ndCounter.$3rdCounter.$4thCounter"}}, `
                            Name,Description,Status,` 
                            @{Label="StartTime"; Expression={Get-Date $_.StartTimeUtc -Format "yyyy-MM-dd HH:mm:ss"}}, `
                            @{Label="EndTime"; Expression={Get-Date $_.EndTimeUtc -Format "yyyy-MM-dd HH:mm:ss"}}
                }

                $4thStep.steps | foreach {
                    $5thStep = $_
                    if ($5thStep){
                        $5thCounter++
                        $root += $5thStep | Select-Object `
                            @{Label="Seq"; Expression={"$1stCounter.$2ndCounter.$3rdCounter.$4thCounter.$5thCounter"}}, `
                            Name,Description,Status,` 
                            @{Label="StartTime"; Expression={Get-Date $_.StartTimeUtc -Format "yyyy-MM-dd HH:mm:ss"}}, `
                            @{Label="EndTime"; Expression={Get-Date $_.EndTimeUtc -Format "yyyy-MM-dd HH:mm:ss"}}
                    }
                }
            }

        }
    }
}

$root | Out-GridView -Title "The detailed progress of this Azure Stack Hub Update"

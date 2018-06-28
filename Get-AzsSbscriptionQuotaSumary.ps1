<#
.SYNOPSIS
.DESCRIPTION
.EXAMPLE
#>

Param(
  [parameter(mandatory = $true)][String]$UserSubscriptionId

)

$ErrorActionPreference = "stop"

function ShowHeader($RP) {
    Write-Output ""
    Write-Output "------------------------------------------------------------------------"
    Write-Output $RP
    Write-Output "------------------------------------------------------------------------"
}

$Sub = Get-AzsUserSubscription -SubscriptionId $UserSubscriptionId
$offer = Get-AzureRmResource -ResourceId $sub.OfferId
$AddonPlan = $offer.Properties.AddonPlans
$basePlan = Get-AzsPlan -ResourceId $offer.Properties.BasePlanIds[0]
$basePlan.QuotaIds | foreach {
    if ($_ -match "(Microsoft\.Storage\.Admin)"){
        ShowHeader($matches[1])
        (Get-AzureRmResource -ResourceId $_).Properties | fl * | Out-String -Stream | ?{$_ -ne ""}
    }

    if ($_ -match "(Microsoft\.Network\.Admin)"){
        ShowHeader($matches[1])
        (Get-AzureRmResource -ResourceId $_).Properties | Select-Object * -exclude provisioningState,migrationPhase | fl * | Out-String -Stream | ?{$_ -ne ""}
    }

    if ($_ -match "(Microsoft\.Compute\.Admin)"){
        ShowHeader($matches[1])
        (Get-AzureRmResource -ResourceId $_).Properties | fl * | Out-String -Stream | ?{$_ -ne ""}
    }

    if ($_ -match "(Microsoft\.Web\.Admin)"){
        ShowHeader($matches[1])
        (Get-AzureRmResource -ResourceId $_).Properties | Select-Object * -exclude name | fl * | Out-String -Stream | ?{$_ -ne ""}
    }

    if ($_ -match "(Microsoft\.KeyVault\.Admin)"){
        ShowHeader($matches[1])
        Write-Output "Unlimited"
    }
}

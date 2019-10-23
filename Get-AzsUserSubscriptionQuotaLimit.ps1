<#
.Synopsis
    Calculate the limit of Quotas per user subscriptions and export this limit as json file.
#>


$ErrorActionPreference = "stop"

$QuotaList = @(
    'AvailabilitySetCount',
    'CoresLimit',
    'VmScaleSetCount',
    'VirtualMachineCount',
    'StandardManagedDiskAndSnapshotSize',
    'PremiumManagedDiskAndSnapshotSize',
    'NumberOfStorageAccounts',
    'CapacityInGb',
    'MaxPublicIpsPerSubscription',
    'MaxVnetsPerSubscription',
    'MaxVirtualNetworkGatewaysPerSubscription',
    'MaxVirtualNetworkGatewayConnectionsPerSubscription',
    'MaxLoadBalancersPerSubscription',
    'MaxSecurityGroupsPerSubscription'
)


$Subscriptions = Get-AzsUserSubscription

$Subscriptions | ForEach-Object {

    $QuotaSummary = [ordered]@{}
    $QuotaList | ForEach-Object {
        $QuotaSummary[$_] = $null
    }

    $Subscription = $_

    $ResourceGroup = $Subscription.OfferId.Split('/')[4]
    $OfferName = $Subscription.OfferId.Split('/')[8]

    $Offer = Get-AzureRmResource -ResourceGroupName $ResourceGroup -Name $OfferName -ExpandProperties -ResourceType Microsoft.Subscriptions.Admin/offers

    $BasePlan = $offer.Properties.basePlanIds

    $BasePlanDetails = Get-AzsPlan -ResourceId $BasePlan[0]
    $BasePlanDetails.QuotaIds | ForEach-Object {

        $Quota = ""
        $ResourceProvider = $_.Split('/')[4]

        if ( $ResourceProvider -eq 'Microsoft.Compute.Admin' ){
            $Quota = Get-AzsComputeQuota -ResourceId $_
        }

        if ( $ResourceProvider -eq 'Microsoft.Storage.Admin' ){
            $Quota = Get-AzsStorageQuota -ResourceId $_
        }

        if ( $ResourceProvider -eq 'Microsoft.Network.Admin' ){
            $Quota = Get-AzsNetworkQuota -ResourceId $_
        }

        $QuotaList | ForEach-Object {
            if ( $Quota.$_ -ne $null ){
                $QuotaSummary[$_] += $Quota.$_
            }
        }

    }

    $AddonPlans = $null
    $AddonPlans = $offer.Properties.addonPlans
    $AddonPlans | ForEach-Object {
        $AddonPlan = $_.planId

        $AddonPlanDetails = $null
        $AddonPlanDetails = Get-AzsPlan -ResourceId $AddonPlan
        $AddonPlanDetails.QuotaIds | ForEach-Object {

            $Quota = ""
            $ResourceProvider = $_.Split('/')[4]

            if ( $ResourceProvider -eq 'Microsoft.Compute.Admin' ){
                $Quota = Get-AzsComputeQuota -ResourceId $_
            }

            if ( $ResourceProvider -eq 'Microsoft.Storage.Admin' ){
                $Quota = Get-AzsStorageQuota -ResourceId $_
            }

            if ( $ResourceProvider -eq 'Microsoft.Network.Admin' ){
                $Quota = Get-AzsNetworkQuota -ResourceId $_
            }

            $QuotaList | ForEach-Object {
                if ( $Quota.$_ -ne $null ){
                    $QuotaSummary[$_] += $Quota.$_
                }
            }

        }
    }
    
    Write-output "User Subscription Id: $($Subscription.SubscriptionId)"
    $QuotaSummary  | ft -AutoSize

    $FileName = $Subscription.SubscriptionId + "_" +"$($Subscription.Owner)" + ".json"
    $QuotaSummary | ConvertTo-Json | Out-File $FileName -Force
}

<#
.SYNOPSIS
.DESCRIPTION
.EXAMPLE
#>

Param(
  [parameter(mandatory = $true)][String]$Owner,
  [parameter(mandatory = $true)][String]$Location,
  [parameter(mandatory = $true)][String]$CustomerIdentifier,
  [parameter(mandatory = $true)][String]$CoresLimit,
  [parameter(mandatory = $true)][String]$VirtualMachineCount,
  [parameter(mandatory = $true)][String]$CapacityInGb,
  [parameter(mandatory = $true)][Int32]$NumberOfStorageAccounts,
  [parameter(mandatory = $true)][Int32]$MaxPublicIpsPerSubscription,
  [parameter(mandatory = $true)][Int32]$MaxVirtualNetworkGatewaysPerSubscription
)

$ErrorActionPreference = "stop"

# Create resource group to save Customer resources.
$rg = New-AzureRmResourceGroup -Name $CustomerIdentifier -Location $Location

# check
Try {
    Get-AzsLocation | Out-Null
} Catch {
    Write-Error "Please login Azure Stack before execute this script" 
    Break 
}

# Create quotas
$NewCQ = New-AzsComputeQuota -Name $CustomerIdentifier `
                                -CoresLimit $CoresLimit -VirtualMachineCount $VirtualMachineCount
$NewSQ = New-AzsStorageQuota -Name $CustomerIdentifier `
                                -CapacityInGb $CapacityInGb -NumberOfStorageAccounts $NumberOfStorageAccounts
$NewNQ = New-AzsNetworkQuota -Name $CustomerIdentifier `
                                -MaxPublicIpsPerSubscription $MaxPublicIpsPerSubscription `
                                -MaxVirtualNetworkGatewaysPerSubscription $MaxVirtualNetworkGatewaysPerSubscription

# Create plan
$QoutaIds = @(
    $NewCQ.Id,
    $NewSQ.Id,
    $NewNQ.Id,
    (Get-AzsKeyVaultQuota).Id
)

$NewPlan = New-AzsPlan -Name $CustomerIdentifier -DisplayName $CustomerIdentifier `
                        -QuotaIds $QoutaIds -ResourceGroupName $rg.ResourceGroupName

# Create offer
$NewOffer = New-AzsOffer -Name $CustomerIdentifier -DisplayName $CustomerIdentifier `
                            -ResourceGroupName $rg.ResourceGroupName -BasePlanIds $NewPlan.Id -Location $Location -State Private

# Get guest AAD tenant id
# https://github.com/Azure/AzureStack-Tools/blob/master/Connect/AzureStack.Connect.psm1
$regex=[regex]'@(.*)$'
$regex.Matches($Owner) | ForEach {
    $AADTenantName = $_.value.Replace("@","")
}

$ADauth = (Get-AzureRmEnvironment -Name $EnvironmentName).ActiveDirectoryAuthority
$endpt = "{0}{1}/.well-known/openid-configuration" -f $ADauth, $AADTenantName
$OauthMetadata = (Invoke-WebRequest -UseBasicParsing $endpt).Content | ConvertFrom-Json
$AADid = $OauthMetadata.Issuer.Split('/')[3]

# Create new user subscription
New-AzsUserSubscription -DisplayName $CustomerIdentifier -OfferId $NewOffer.Id -Owner $Owner -TenantId $AADid

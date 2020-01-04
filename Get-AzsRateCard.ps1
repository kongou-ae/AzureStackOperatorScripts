$ErrorActionPreference = "stop"

Param(
  [parameter(mandatory = $true)][String]$Currency
)

# Validate the input
$testedCurrency = @('JPY','USD')

if ($testedCurrency.Contains($Currency)){
  Write-Output "Started to created $Currency rate card."
} else {
  throw "$Currency is not supported. This script supports only JPY and USD"
}

# Get a token
$azContext = Get-AzureRMContext
$azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
$profileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azProfile)
$token = $profileClient.AcquireAccessToken($azContext.Tenant.TenantId)

$authHeader = "Bearer " + $token.AccessToken
$requestHeader = @{
    "Authorization" = $authHeader
}

# Get a subscription id
$subId = (Get-AzureRmSubscription)[0].SubscriptionId

# Construct the url to access rate card API
$locale = "en-us"
$RegionInfo = "JP"
$Url = "https://management.azure.com/subscriptions/" + $subId + "/providers/Microsoft.Commerce/RateCard?api-version=2015-06-01-preview&%24filter=OfferDurableId+eq+'MS-AZR-0003p'+and+Currency+eq+'" + $Currency + "'+and+Locale+eq+'" + $Locale + "'and+RegionInfo+eq+'" + $RegionInfo + "'"
$res = Invoke-RestMethod -Uri $Url -Method GET -Headers $requestHeader -ContentType "application/json"

# Create temp file
$now = Get-date -Format yyyyMMdd-hhmmss
$tmpfilename = $now + "_tmp_AllRateCard.json"
$res | out-file "$HOME\$tmpfilename"
Write-output "Created temporary file ($HOME\$tmpfilename)."

# Extract the meters for Azure Stack Hub
$result = (Get-content "$HOME\$tmpfilename" | ConvertFrom-Json).Meters | Where-Object { $_.MeterRegion -eq "Azure Stack"}
Remove-Item "$HOME\$tmpfilename"
Write-output "Removed temporary file ($HOME\$tmpfilename)."

# Create Azure Stack rate card.
$now = Get-date -Format yyyyMMdd-hhmmss
$filename = $now + "_AzsRateCard.json"
$result | ConvertTo-Json -Depth 100 | Out-File "$HOME\$filename"
Write-Output "Created $HOME\$filename."

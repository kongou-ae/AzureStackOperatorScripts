<#
.SYNOPSIS
.DESCRIPTION
.EXAMPLE
#>

$ErrorActionPreference = "stop"

# check
Try {
    Get-AzsLocation | Out-Null
} Catch {
    Write-Error "Please login Azure Stack before execute this script" 
    Break 
}

$resourceGroupName = 'azurestack-activation'
$activation = Get-AzsAzureBridgeActivation -ResourceGroupName $resourceGroupName 

Write-Output "Downloading the list about marketplace items."
$list = Get-AzsAzureBridgeProduct -ActivationName $activation.Name -ResourceGroupName $resourceGroupName
$item = $list | Select-Object DisplayName,PublisherDisplayName,GalleryItemIdentity,PayloadLength,Id | Out-GridView -PassThru

# check
$downloadedItem = Get-AzsAzureBridgeDownloadedProduct -ActivationName $activation.Name -ResourceGroupName $resourceGroupName
$downloadedItem | foreach {
    if ( $_.GalleryItemIdentity -eq $item.GalleryItemIdentity ){
        Write-Error $targetItem + " already downloaded"
        exit
    }
}

Write-Output "The following item will be downloaded. Please check marketplace after several hours."
$item

Invoke-AzsAzureBridgeProductDownload -ResourceId $item.Id -AsJob -Force | Out-Null

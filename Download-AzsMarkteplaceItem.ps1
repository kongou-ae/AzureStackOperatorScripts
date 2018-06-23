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
Write-Output "Downloading list of marketplace items."
$list = Get-AzsAzureBridgeProduct -ActivationName $activation.Name -ResourceGroupName $resourceGroupName
$item = $list | Select-Object DisplayName,PublisherDisplayName,GalleryItemIdentity,PayloadLength,Id | Out-GridView -PassThru

if($item){
    $downloadedItem = Get-AzsAzureBridgeDownloadedProduct -ActivationName $activation.Name -ResourceGroupName $resourceGroupName

    # check
    $downloadedItem | foreach {
        if ( $_.GalleryItemIdentity -eq $item.GalleryItemIdentity ){
            Write-Error "$($item.DisplayName) already downloaded"
            exit
        }
    }

    Write-Output "The following item will be downloaded. Please check marketplace after several hours."
    $item

    Invoke-AzsAzureBridgeProductDownload -ResourceId $item.Id -AsJob -Force | Out-Null
} else {
    Write-Output "Please select item."
}

$ErrorActionPreference = "Stop"
$StorageAccounts = Get-AzureRmStorageAccount | Where-Object { $_.StorageAccountName -match "health"}

foreach( $StorageAccount in  $StorageAccounts ){

    $ctx = $StorageAccount.Context
    $container = ""
    $container = Get-AzureStorageContainer -Context $ctx | Where-Object { $_.Name -eq "alerttemplates"}

    if( $container -ne $null ){
        $blobs = ""
        $blobs = Get-AzureStorageBlob -Context $ctx -Container $container.Name

        foreach($blob in $blobs){
            Write-host "## $($blob.Name)"
            $template = $blob.ICloudBlob.DownloadText()
            $template = $template.Replace("`r`n","")

            $matchText = [RegEx]::Matches($template ,'"Title":\s\{\s*"Text"\:\s(".*?")')
            $matchDesc = [RegEx]::Matches($template ,'"Description":\s\{\s*"Text"\:\s(".*?")')

            for($i=0; $i -lt $matchText.Count; $i++ ){
                Write-host "- $($matchText[$i].Groups[1].Value)"
                Write-host "  - $($matchDesc[$i].Groups[1].Value)"
            }
        }
    }
}

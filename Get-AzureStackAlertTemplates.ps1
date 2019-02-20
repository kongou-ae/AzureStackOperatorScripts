$ErrorActionPreference = "Stop"
$StorageAccounts = Get-AzureRmStorageAccount | Where-Object { $_.StorageAccountName -match "health"}

$alerts = @{}
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

            $matchText = [RegEx]::Matches($template ,'"Title":\s\{\s*"Text"\:\s"(.*?)"')
            $matchDesc = [RegEx]::Matches($template ,'"Description":\s\{\s*"Text"\:\s"(.*?)"')
            $matchSev = [RegEx]::Matches($template ,'"Severity":\s"(.*?)"')
            
            $alert = New-Object System.Collections.Generic.List[System.Object]
            for($i=0; $i -lt $matchText.Count; $i++ ){
                $tmp = @{ }
                $tmp.Add("Title",$matchText[$i].Groups[1].Value)
                $tmp.Add("Severity",$matchSev[$i].Groups[1].Value)
                $tmp.Add("Description",$matchDesc[$i].Groups[1].Value)
                $alert.Add($tmp)
            }
            $alerts.Add($blob.Name,$alert)
        }
    }
}

$alerts | ConvertTo-Json -Depth 100 | Out-File alerts.json -Force

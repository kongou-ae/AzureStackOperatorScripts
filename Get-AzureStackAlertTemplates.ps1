$ErrorActionPreference = "Stop"
$StorageAccounts = Get-AzureRmStorageAccount | Where-Object { $_.StorageAccountName -match "health"}

$mainAlerts = [ordered]@{}
foreach( $StorageAccount in  $StorageAccounts ){

    $ctx = $StorageAccount.Context
    $container = ""
    $container = Get-AzureStorageContainer -Context $ctx | Where-Object { $_.Name -eq "alerttemplates"}

    if( $container -ne $null ){
        $blobs = ""
        $blobs = Get-AzureStorageBlob -Context $ctx -Container $container.Name
        
        foreach($blob in $blobs){
            Get-AzureStorageBlobContent -Context $ctx -Container $container.Name -Blob $blob.Name -Destination "$($blob.Name).json" -Force | out-null
            $alertList = Get-Content "$($blob.Name).json" -Raw | convertFrom-Json
            
            $categoryAlerts = New-Object System.Collections.Generic.List[System.Object]
            $alertList.AlertTemplates | ForEach-Object {
                $alert = $_
                $tmp = [ordered]@{ }
                $tmp["Title"] = $alert.Title.Text
                $tmp["Severity"] = $alert.Severity
                $tmp["Description"] = $alert.Description.Text
                $tmp["Remediations"] = $alert.Remediations.Text
            
                $categoryAlerts.Add($tmp)
            }
            $mainAlerts[$blob.Name] = $categoryAlerts
        }

    }
}

$mainAlerts | ConvertTo-Json -Depth 100 | Out-File alerts.json -Force

# Thanks ERCS_AzureStackLogs.ps1

Param(
  [parameter(mandatory = $true)][String]$ercs
)

$ErrorActionPreference = "Stop" 

Write-Host (Get-date) "Confirm your credentials"
$cred = Get-Credential -Message "Please input the credential of pep"
$shareCred = Get-Credential -Message "Please input the credential of local machine"

#### Connect pepe
Write-Host (Get-date) "Connecting pep($ercs)"
$pepSession = New-PSSession -ComputerName $ercs -ConfigurationName PrivilegedEndpoint -Credential $cred

#### Execute Test-AzureStack
Write-Host (Get-date) "Execute Test-AzureStack"
$res = Invoke-Command -Session $pepSession -ScriptBlock {
    Test-AzureStack
}

#### Create file share
Write-Host (Get-date) "Create the file share for Get-AzureStackLogs"
$myname = whoami
$date = Get-Date -format MM-dd-hhmm
$foldername = "-AzureStackLogs"
$sharename = $date + $foldername
If (!(Test-Path "$($Env:SystemDrive)\$($sharename)")) {
    $folder = New-Item -Path "$($Env:SystemDrive)\$($sharename)" -ItemType directory
} 
$foldershare= New-SMBShare -Name $sharename -Path "$($Env:SystemDrive)\$($sharename)" -FullAccess $myname
$testconnect = Test-NetConnection -port 5985 -ComputerName $ercs
$hostIp = $testconnect.SourceAddress.IPAddress
$shareInfo = "\\$hostIp\$($foldershare.Name)"

#### Get-AzureStackLog
Write-Host (Get-date) "Execute Get-AzureStackLogs"
$FromDate = (get-date).AddHours(-1)
$ToData = (get-date)
$res = Invoke-Command -Session $pepSession -ScriptBlock {
    Get-AzureStackLog `
        -OutputSharePath $using:shareInfo `
        -OutputShareCredential $using:shareCred `
        -FromDate $using:FromDate -ToDate $using:ToData `
        -FilterByRole Seedring 
}

#### Get AzureStack_Validation_Summary
Write-Host (Get-date) "Extract AzureStack_Validation_Summary"
$logFilePath = Get-ChildItem -Path "$($foldershare.Path)"
Add-Type -Assembly System.IO.Compression.FileSystem
$seedringzip = Get-ChildItem -Path "$($logFilePath.FullName)" | Where {($_.Name -like "SeedRing-*.zip")} | sort -Descending -Property CreationTime | select -first 1
$zip = [IO.Compression.ZipFile]::OpenRead($seedringzip.FullName)
$Valreportdir  = $foldershare.Path + "\"
$ValidationReport = $zip.Entries | where {$_.Name -like 'AzureStack_Validation_Summary_*.HTML'} | sort -Descending -Property LastWriteTime | select -first 1
$ValidationReport | foreach {[IO.Compression.ZipFileExtensions]::ExtractToFile( $_, $Valreportdir + $_.Name) }
$zip.Dispose()

#### Cleaning
Write-Host (Get-date) "Remove file share"
Remove-SmbShare -Name $sharename -Force
Get-PSSession | Remove-PSSession

### Finish
Write-Host (Get-date) "Finished. You can get $($Valreportdir + $ValidationReport.Name)"

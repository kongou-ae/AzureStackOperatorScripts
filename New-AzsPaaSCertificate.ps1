[CmdletBinding()]
param (
    [Parameter(mandatory=$true)]
    [ValidateSet("EventHubs" , "IoTHub", "ccc")]
    [string]
    $rp,
    [Parameter(mandatory=$true)]
    [string]
    $subject,
    [Parameter(mandatory=$true)]
    [string]
    $regionName,
    [Parameter(mandatory=$true)]
    [string]
    $externalFQDN,
    [Parameter(mandatory=$true)]
    [string]
    $email,
    [Parameter(mandatory=$true)]
    [string]
    $subscriptionId,
    [Parameter(mandatory=$true)]
    [string]
    $pfxpass
)

# This script supports only EventHubs now.

#Requires -Modules Microsoft.AzureStack.ReadinessChecker
#Requires -Modules Posh-ACME
#Requires -Modules Az.Accounts
#Requires -RunAsAdministrator

$ErrorActionPreference = "stop"

Function Write-Log
{
    param(
    [string]$Message,
    [string]$Color = 'White'
    )

    $Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$Date] $Message" -ForegroundColor $Color
}

function New-AzsEventHubCertificate {
    param (
        [Parameter(mandatory=$true)]
        $reqs
    )

    $csr = ($reqs | Where-Object { $_.name -like "wildcard_eventhub_*"} | Sort-Object -Property LastWriteTime -Descending)[0]
    $result = New-PACertificate `
        -CSRPath $csr.FullName `
        -Contact $email `
        -AcceptTOS `
        -DnsPlugin Azure `
        -PluginArgs @{`
            AZSubscriptionId=$subscriptionId;`
            AZAccessToken=$token;`
        } `
        -DNSSleep 5 `
        -Verbose -force

    return $result
}

$outputDirectory = "$HOME\azscsr"

if ( (Test-Path $outputDirectory ) -eq $false ){
    $outputDirectory = "$HOME\azscsr"
    Write-Log  "$OutputDirectory doesn't exist. Create it." "Green"
    New-Item -ItemType Directory -Path $outputDirectory
} else {
    Write-Output "$OutputDirectory already exist."
}

Write-Log "Create the CSR for $rp" "Green"

switch($rp){
    "EventHubs" {
        New-AzsHubEventHubsCertificateSigningRequest -RegionName $regionName -FQDN $externalFQDN `
            -subject $subject -OutputRequestPath $outputDirectory
    }
    "IoTHub" {
        New-AzsHubIoTHubCertificateSigningRequest -RegionName $regionName -FQDN $externalFQDN `
            -subject $subject -OutputRequestPath $outputDirectory
    }
}

$reqs = Get-ChildItem "C:\Users\MatsumotoYusuke\azscsr" | Where-Object { $_.Name -like "*.req"}

Write-Log  "Get the access token to call Azure DNS" "Green"
Get-AzSubscription -subscriptionId $subscriptionId | Select-AzSubscription
$token = (Get-AzAccessToken).Token

Set-PAServer LE_STAGE

Write-Log "Sign the certificate for $rp by Let's encrypt" "Green"
switch($rp){
    "EventHubs" {
        $result = New-AzsEventHubCertificate -reqs $reqs
        $certPath = ($result.FullChainFile).Replace("\fullchain.cer","")
    }
    "IoTHub" {

    }
}

Write-Log "Export the certificate as a pfx file" "Green"
Get-ChildItem $certpath |Where-Object { $_.Name -ne "fullchain.cer"} | Rename-Item -NewName{$_.Name + ".tmp"}
$securePfxpass = ConvertTo-SecureString -String $pfxpass -Force -AsPlainText
ConvertTo-AzsPFX -Path $certPath -pfxPassword $securePfxpass -ExportPath $outputDirectory

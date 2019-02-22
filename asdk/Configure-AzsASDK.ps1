$ErrorActionPreference = "stop"
 
#######################################################################
# Azure-Stack-Tools
#######################################################################

cd  C:\Users\AzureStackAdmin

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 
invoke-webrequest `
  https://github.com/Azure/AzureStack-Tools/archive/master.zip `
  -OutFile master.zip

expand-archive master.zip `
  -DestinationPath . `
  -Force

#######################################################################
# Save Credential
#######################################################################

Write-Host "Login Azure"
$azureContext = Login-AzureRmAccount

Import-Module C:\Users\AzureStackAdmin\AzureStack-Tools-master\Connect\AzureStack.Connect.psm1

$ArmEndpoint = "https://adminmanagement.local.azurestack.external"
$AADTenantName = "aimless2.onmicrosoft.com" 

Add-AzureRMEnvironment `
  -Name "AzureStackAdmin" `
  -ArmEndpoint $ArmEndpoint

$TenantID = Get-AzsDirectoryTenantId `
  -AADTenantName $AADTenantName `
  -EnvironmentName AzureStackAdmin

$azsContext = Login-AzureRmAccount `
  -Environment AzureStackAdmin `
  -TenantId $TenantID

Get-AzureRmContext -ListAvailable | where {$_.Environment -eq "AzureStackAdmin"} | Set-AzureRmContext

#######################################################################
# Register
#######################################################################

$cred = Get-Credential -UserName "azurestack.local\azurestackadmin" -Message "Please input password of CloudAdmin"
$pep = New-PSSession -ComputerName azs-ercs01 -ConfigurationName PrivilegedEndpoint -Credential $cred
$res = Invoke-Command -Session $pep -ScriptBlock {
    Get-AzureStackStampInformation
}

$res.DeploymentID

Install-module AzureRm.Profile -Scope CurrentUser
Install-module AzureRm.Resources -Scope CurrentUser

Add-AzureRmAccount -EnvironmentName "AzureCloud"

Get-AzureRmSubscription | Out-GridView -PassThru |Select-AzureRmSubscription
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.AzureStack

Import-Module C:\Users\AzureStackAdmin\azurestack-tools-master\Registration\RegisterWithAzure.psm1 

$RegistrationName = "asdk-" + $res.DeploymentID
Set-AzsRegistration `
   -PrivilegedEndpointCredential $cred `
   -PrivilegedEndpoint azs-ercs01 `
   -BillingModel development `
   -RegistrationName $RegistrationName `
   -AzureContext $azureContext
   
#######################################################################
# Choco
#######################################################################

Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco feature enable -n allowGlobalConfirmation
choco install googlechrome
choco install vscode

#######################################################################
# PowerShell
#######################################################################

Install-Module AzureRM -RequiredVersion 2.4.0 -Scope CurrentUser
Install-Module -Name AzureStack -RequiredVersion 1.7.0 -Scope CurrentUser

#######################################################################
# User Subscription
#######################################################################

$rg = New-AzureRmResourceGroup -Name asdk -Location local
$cquota = Get-AzsComputeQuota -Name "Default Quota" -Location local
$nquota = Get-AzsNetworkQuota -Name "Default Quota" -Location local
$squota = Get-AzsStorageQuota -Name "Default Quota" -Location local
$kquota = Get-AzsKeyVaultQuota -Location local

$QuotaIds = @(
    $cquota.Id,
    $nquota.Id,
    $squota.Id,
    $kquota.Id
)

$plan = New-AzsPlan -Name asdk -ResourceGroupName $rg.ResourceGroupName -DisplayName asdk -Location local -QuotaIds $QuotaIds
$offer = New-AzsOffer -Name asdk -DisplayName asdk -ResourceGroupName $rg.ResourceGroupName -Location local -BasePlanIds $plan.Id
New-AzsUserSubscription -Owner asdk@aimless2.onmicrosoft.com -DisplayName asdk -OfferId $offer.Id -DefaultProfile $azsContext

#######################################################################
# Download Marketplace item for App Service infra
#######################################################################

$resourceGroupName = 'azurestack-activation'
$activation = Get-AzsAzureBridgeActivation -ResourceGroupName $resourceGroupName 
$list = Get-AzsAzureBridgeProduct -ActivationName $activation.Name -ResourceGroupName $resourceGroupName

$list | foreach {
    if ($_.Name -like "default/microsoft.windowsserver2016datacenter-arm-payg*"){
        # more laster value is latest.
        $win2016 = $_
    }
}

$list | foreach {
    if ($_.Name -like "default/microsoft.windowsserver2016datacenterservercore-arm-payg*"){
        $win2016core = $_
    }
}

$list | foreach {
    if ($_.Name -like "default/microsoft.dsc-arm*"){
        $psDsc = $_
    }
}

$list | foreach {
    if ($_.Name -like "default/microsoft.sqlserver2016sp2enterprisewindowsserver2016-arm*"){
        $sql2016ent = $_
    }
}

$list | foreach {
    if ($_.Name -like "default/microsoft.sqlserver2016sp2enterprisewindowsserver2016-arm*"){
        $sql2016ent = $_
    }
}

$list | foreach {
    if ($_.Name -like "default/microsoft.sqliaasextension-*"){
        $sqlextension = $_
    }
}



Invoke-AzsAzureBridgeProductDownload -ResourceId $win2016.Id -AsJob -Force | Out-Null
Invoke-AzsAzureBridgeProductDownload -ResourceId $win2016core.Id -AsJob -Force | Out-Null
Invoke-AzsAzureBridgeProductDownload -ResourceId $psDsc.Id -AsJob -Force | Out-Null
Invoke-AzsAzureBridgeProductDownload -ResourceId $sql2016ent.Id -AsJob -Force | Out-Null
Invoke-AzsAzureBridgeProductDownload -ResourceId $sqlextension.Id -AsJob -Force | Out-Null

do {
    Write-Output "Checking the progress of $($sqlextension.GalleryItemIdentity)..."
    $result = Get-AzsAzureBridgeDownloadedProduct  `
        -ResourceGroupName $resourceGroupName -ActivationName $activation.Name -Name $sqlextension.Name
    Sleep -Seconds 30
} while($result.ProvisioningState -ne "Succeeded")

do {
    Write-Output "Checking the progress of $($psDsc.GalleryItemIdentity)..."
    $result = Get-AzsAzureBridgeDownloadedProduct  `
        -ResourceGroupName $resourceGroupName -ActivationName $activation.Name -Name $psDsc.Name
    Sleep -Seconds 30
} while($result.ProvisioningState -ne "Succeeded")

do {
    Write-Output "Checking the progress of $($win2016.GalleryItemIdentity)..."
    $result = Get-AzsAzureBridgeDownloadedProduct  `
        -ResourceGroupName $resourceGroupName -ActivationName $activation.Name -Name $win2016.Name
    Sleep -Seconds 30
} while($result.ProvisioningState -ne "Succeeded")

do {
    Write-Output "Checking the progress of $($win2016core.GalleryItemIdentity)..."
    $result = Get-AzsAzureBridgeDownloadedProduct  `
        -ResourceGroupName $resourceGroupName -ActivationName $activation.Name -Name $win2016core.Name
    Sleep -Seconds 30
} while($result.ProvisioningState -ne "Succeeded")

do {
    Write-Output "Checking the progress of $($sql2016ent.GalleryItemIdentity)..."
    $result = Get-AzsAzureBridgeDownloadedProduct  `
        -ResourceGroupName $resourceGroupName -ActivationName $activation.Name -Name $sql2016ent.Name
    Sleep -Seconds 30
} while($result.ProvisioningState -ne "Succeeded")

#######################################################################
# Deploy App Service infra
#######################################################################

Invoke-WebRequest -Uri https://raw.githubusercontent.com/Azure/AzureStack-QuickStart-Templates/master/appservice-fileserver-sqlserver-ha/azuredeploy.json -OutFile appsinfra-azuredeploy.json

$appsPassword = "P@ssw0rd000000" | ConvertTo-SecureString -AsPlainText -Force

New-AzureRmResourceGroup -Name "apps-infra" -Location "local"
$result = New-AzureRmResourceGroupDeployment -ResourceGroupName apps-infra `
  -DeploymentName apps-infta `
  -TemplateUri C:\Users\AzureStackAdmin\appsinfra-azuredeploy.json `
  -adminPassword $appsPassword -fileShareOwnerPassword $appsPassword -fileShareUserPassword $appsPassword `
  -sqlServerServiceAccountPassword $appsPassword -sqlLoginPassword $appsPassword

$apsfileSharePath = $result.Outputs["fileSharePath"].Value
$apsfileShareOwner = $result.Outputs["fileShareOwner"].Value
$apsfileShareUser = $result.Outputs["fileShareUser"].Value
$apssqLserver = $result.Outputs["sqLserver"].Value
$apssqlUser = $result.Outputs["sqlUser"].Value

# PIP for SQL0

$sqlpip = New-AzureRmPublicIpAddress -Name sql0 -ResourceGroupName apps-infra -Location local -AllocationMethod Static
$sqlnic = Get-AzureRmNetworkInterface -ResourceGroupName apps-infra -Name aps-sql-0-nic
$sqlnic.IpConfigurations[0].PublicIpAddress = $sqlpip
Set-AzureRmNetworkInterface -NetworkInterface $sqlnic

# NSG for SQL0
$sqlNsg = Get-AzureRmNetworkSecurityGroup -ResourceGroupName apps-infra -Name aps-sql-Nsg

Add-AzureRmNetworkSecurityRuleConfig `
  -Name "RDP" `
  -NetworkSecurityGroup $sqlNsg `
  -Description "RDP" `
  -Protocol "TCP" `
  -SourcePortRange "*" `
  -DestinationPortRange "3389" `
  -SourceAddressPrefix "*" `
  -DestinationAddressPrefix "VirtualNetwork" `
  -Access "Allow" `
  -Priority "100" `
  -Direction "Inbound"

Set-AzureRmNetworkSecurityGroup -NetworkSecurityGroup $sqlNsg

#######################################################################
# Deploy App Service RP
#######################################################################

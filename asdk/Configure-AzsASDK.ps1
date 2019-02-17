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
   -RegistrationName $RegistrationName

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

$ArmEndpoint = "https://adminmanagement.local.azurestack.external"
$AADTenantName = "aimless2.onmicrosoft.com" 

Add-AzureRMEnvironment `
  -Name "AzureStackAdmin" `
  -ArmEndpoint $ArmEndpoint

$TenantID = Get-AzsDirectoryTenantId `
  -AADTenantName $AADTenantName `
  -EnvironmentName AzureStackAdmin

Login-AzureRmAccount `
  -Environment AzureStackAdmin `
  -TenantId $TenantID

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
New-AzsUserSubscription -Owner asdk@aimless2.onmicrosoft.com -DisplayName asdk -OfferId $offer.Id

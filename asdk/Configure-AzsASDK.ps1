$ErrorActionPreference = "stop"

$CloudAdminCredential = Get-Credential -Credential azurestack\CloudAdmin
$aadAdminCredential = Get-Credential -Message "Please input the account which you used to deplpoy ASDK"
$ArmEndpoint = "https://adminmanagement.uda.asdk.aimless.jp"
$AADTenantName = "aimless2.onmicrosoft.com" 

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
Install-module AzureRm.Profile -Scope CurrentUser -Force
Install-module AzureRm.Resources -Scope CurrentUser -Force
$azureContext = Login-AzureRmAccount

Import-Module C:\Users\AzureStackAdmin\AzureStack-Tools-master\Connect\AzureStack.Connect.psm1

Add-AzureRMEnvironment `
  -Name "AzureStackAdmin" `
  -ArmEndpoint $ArmEndpoint

$TenantID = Get-AzsDirectoryTenantId `
  -AADTenantName $AADTenantName `
  -EnvironmentName AzureStackAdmin

$azsContext = Login-AzureRmAccount `
  -Environment AzureStackAdmin `
  -TenantId $TenantID

#######################################################################
# Register
#######################################################################

$pep = New-PSSession -ComputerName azs-ercs01 -ConfigurationName PrivilegedEndpoint -Credential $CloudAdminCredential
$res = Invoke-Command -Session $pep -ScriptBlock {
    Get-AzureStackStampInformation
}

Get-AzureRmContext -ListAvailable | Where-Object { $_.Environment.Name -eq "AzureCloud"} | Select-AzureRmContext

Get-AzureRmSubscription | Out-GridView -PassThru |Select-AzureRmSubscription
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.AzureStack

Import-Module C:\Users\AzureStackAdmin\azurestack-tools-master\Registration\RegisterWithAzure.psm1 

$RegistrationName = "asdk-" + $res.DeploymentID
Set-AzsRegistration `
   -PrivilegedEndpointCredential $CloudAdminCredential `
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

$list | foreach {
    if ($_.Name -like "default/microsoft.customscriptextension-arm-1.9.1*"){
        $customscript = $_
    }
}



Invoke-AzsAzureBridgeProductDownload -ResourceId $win2016.Id -AsJob -Force | Out-Null
Invoke-AzsAzureBridgeProductDownload -ResourceId $win2016core.Id -AsJob -Force | Out-Null
Invoke-AzsAzureBridgeProductDownload -ResourceId $psDsc.Id -AsJob -Force | Out-Null
Invoke-AzsAzureBridgeProductDownload -ResourceId $sql2016ent.Id -AsJob -Force | Out-Null
Invoke-AzsAzureBridgeProductDownload -ResourceId $sqlextension.Id -AsJob -Force | Out-Null
Invoke-AzsAzureBridgeProductDownload -ResourceId $customscript.Id -AsJob -Force | Out-Null

do {
    Write-Output "Checking the progress of $($sqlextension.GalleryItemIdentity)..."
    $result = Get-AzsAzureBridgeDownloadedProduct  `
        -ResourceGroupName $resourceGroupName -ActivationName $activation.Name -Name $sqlextension.Name
    Sleep -Seconds 30
} while($result.ProvisioningState -ne "Succeeded")

do {
    Write-Output "Checking the progress of $($customscript.GalleryItemIdentity)..."
    $result = Get-AzsAzureBridgeDownloadedProduct  `
        -ResourceGroupName $resourceGroupName -ActivationName $activation.Name -Name $customscript.Name
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

Get-AzureRmContext -ListAvailable | where {$_.Environment -like "AzureStackAdmin*"} | Set-AzureRmContext

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

Add-AzureRmNetworkSecurityRuleConfig `
-Name "winrm" `
-NetworkSecurityGroup $sqlNsg `
-Description "winrm" `
-Protocol "TCP" `
-SourcePortRange "*" `
-DestinationPortRange "5985" `
-SourceAddressPrefix "*" `
-DestinationAddressPrefix "VirtualNetwork" `
-Access "Allow" `
-Priority "110" `
-Direction "Inbound"

Set-AzureRmNetworkSecurityGroup -NetworkSecurityGroup $sqlNsg

#######################################################################
# Deploy App Service RP
#######################################################################

# Get certs
Invoke-WebRequest -Uri https://aka.ms/appsvconmashelpers -OutFile AppServiceHelperScripts.zip
Expand-Archive .\AppServiceHelperScripts.zip

.\AppServiceHelperScripts\Get-AzureStackRootCert.ps1 `
    -PrivilegedEndpoint azs-ercs01 -CloudAdminCredential $CloudAdminCredential

$certPass = ConvertTo-SecureString -String "P@ssw0rdP@ssw0rd" -AsPlainText -Force
.\AppServiceHelperScripts\Create-AppServiceCerts.ps1 -DomainName local.azurestack.external `
    -PfxPassword $certPass

$result = .\AppServiceHelperScripts\Create-AADIdentityApp.ps1 -DirectoryTenantName $AADTenantName `
    -AdminArmEndpoint adminmanagement.local.azurestack.external `
    -TenantArmEndpoint management.local.azurestack.external `
    -CertificateFilePath C:\Users\AzureStackAdmin\AppServiceHelperScripts\sso.appservice.local.azurestack.external.pfx `
    -Environment AzureCloud `
    -CertificatePassword $certPass `
    -AzureStackAdminCredential $aadAdminCredential

# Add grant to aad app
$apsSSOappId = $result[1] 
$tenantId = $azurecontext.Context.Tenant.Id
$azureContext.Context.TokenCache.ReadItems() | Where-Object { $_.Resource -eq "https://graph.windows.net/"} 
$refreshToken = ($azureContext.Context.TokenCache.ReadItems() | Where-Object { $_.Resource -eq "https://graph.windows.net/"}).refreshToken
$body = "grant_type=refresh_token&refresh_token=$($refreshToken)&resource=74658136-14ec-4630-ad9b-26e160ff0fc6"
$apiToken = Invoke-RestMethod "https://login.windows.net/$tenantId/oauth2/token" -Method POST -Body $body -ContentType 'application/x-www-form-urlencoded'
$header = @{
    'Authorization' = 'Bearer ' + $apiToken.access_token
    'X-Requested-With'= 'XMLHttpRequest'
    'x-ms-client-request-id'= [guid]::NewGuid()
    'x-ms-correlation-id' = [guid]::NewGuid()
}

$url = "https://main.iam.ad.ext.azure.com/api/RegisteredApplications/$apsSSOappId/Consent?onBehalfOfAll=true"
Invoke-RestMethod –Uri $url –Headers $header –Method POST -ErrorAction Stop

# install App Service PR
$cred = New-Object System.Management.Automation.PSCredential "appsvcadmin",$appsPassword 
$sqlsession = New-PSSession 192.168.102.39 -Credential $cred -Port 5985

Invoke-WebRequest -Uri https://raw.githubusercontent.com/kongou-ae/AzureStackOperatorScripts/master/asdk/AppServiceDeploymentSettings.json -OutFile C:\Users\AzureStackAdmin\AppServiceDeploymentSettings.json
$appconfig = Get-Content C:\Users\AzureStackAdmin\AppServiceDeploymentSettings.json
$appconfig = $appconfig.Replace("<<IdentityApplicationId>>", $apsSSOappId)
Out-File -FilePath C:\Users\AzureStackAdmin\AppServiceDeploymentSettings.json -InputObject $appconfig

Copy-Item C:\Users\AzureStackAdmin\AppServiceHelperScripts\sso.appservice.local.azurestack.external.pfx C:\Users\appsvcadmin.APS-SQL-0\Documents\ -ToSession $sqlsession
Copy-Item C:\Users\AzureStackAdmin\AppServiceHelperScripts\api.appservice.local.azurestack.external.pfx C:\Users\appsvcadmin.APS-SQL-0\Documents\ -ToSession $sqlsession
Copy-Item C:\Users\AzureStackAdmin\AppServiceHelperScripts\ftp.appservice.local.azurestack.external.pfx C:\Users\appsvcadmin.APS-SQL-0\Documents\ -ToSession $sqlsession
Copy-Item C:\Users\AzureStackAdmin\AppServiceHelperScripts\_.appservice.local.azurestack.external.pfx C:\Users\appsvcadmin.APS-SQL-0\Documents\ -ToSession $sqlsession
Copy-Item C:\Users\AzureStackAdmin\AppServiceHelperScripts\AzureStackCertificationAuthority.cer C:\Users\appsvcadmin.APS-SQL-0\Documents\ -ToSession $sqlsession
Copy-Item C:\Users\AzureStackAdmin\AppServiceDeploymentSettings.json C:\Users\appsvcadmin.APS-SQL-0\Documents\ -ToSession $sqlsession

$res = Invoke-Command -Session $sqlsession -ScriptBlock {
    Invoke-WebRequest -Uri https://aka.ms/appsvconmasinstaller -OutFile C:\Users\appsvcadmin.APS-SQL-0\Documents\AppService.exe
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Using:aadAdminCredential.Password)
    $aadUnsecurePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    .\AppService.exe /quiet /log C:\Users\appsvcadmin.APS-SQL-0\Documents\appsinstall.txt Deploy UserName=$($Using:aadAdminCredential.UserName) Password=$aadUnsecurePassword ParamFile=C:\Users\appsvcadmin.APS-SQL-0\Documents\AppServiceDeploymentSettings.json
}

do{
    Write-Output "Checking the progress of installing App Service..."
    $progress = Invoke-Command -Session $sqlsession -ScriptBlock {
        Get-Content C:\Users\appsvcadmin.APS-SQL-0\Documents\appsinstall.txt -Tail 1
    }
    sleep -s 300
} while($progress -notlike "*Exit code:*")

if ($progress -like "*Exit code: 0x0,*"){
    Write-Output "The installation of App Service was successful."
} else {
    Write-Output "The installation of App Service was failed."
}

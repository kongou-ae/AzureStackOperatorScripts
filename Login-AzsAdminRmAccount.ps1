<#
.SYNOPSIS
.DESCRIPTION
.EXAMPLE
#>

Param(
  [parameter(mandatory = $true)][String]$fqdn
)

# initialize context
Try {
    Get-AzureRmContext -ListAvailable | Logout-AzureRmAccount | Out-Null
}
catch {
        
}

Write-Output "Installing modules"
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted 
Install-Module -Name AzureRm.BootStrapper -Scope CurrentUser -AllowClobber
Use-AzureRmProfile -Profile 2017-03-09-profile -Force -Scope CurrentUser 
Install-Module -Name AzureStack -RequiredVersion 1.3.0 -Scope CurrentUser -AllowClobber

Write-Output "Please input your account to login Azure Stack Admin Portal"
$cred = Get-Credential
$ArmEndpoint = "https://adminmanagement." + $fqdn

# Register an AzureRM environment that targets your Azure Stack instance
Add-AzureRMEnvironment `
  -Name "AzureStackAdmin" `
  -ArmEndpoint $ArmEndpoint

# Sign in to your environment
Login-AzureRmAccount `
  -EnvironmentName "AzureStackAdmin" `
  -Credential $cred

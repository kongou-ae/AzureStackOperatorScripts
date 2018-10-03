<#
.SYNOPSIS
.DESCRIPTION
.EXAMPLE
#>

Param(
  [parameter(mandatory = $true)][String]$fqdn
)

$ErrorActionPreference = "stop"

Write-Output "Installing modules"
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted 
Install-Module -Name AzureRm.BootStrapper -Scope CurrentUser -AllowClobber
Use-AzureRmProfile -Profile 2018-03-01-hybrid -Force -Scope CurrentUser 
Install-Module -Name AzureStack -Scope CurrentUser -AllowClobber

$ArmEndpoint = "https://adminmanagement." + $fqdn

# Register an AzureRM environment that targets your Azure Stack instance
Add-AzureRMEnvironment `
  -Name "AzureStackAdmin" `
  -ArmEndpoint $ArmEndpoint

Write-Output "Try login to $ArmEndpoint. Please input your account to login Azure Stack Admin Portal"
# Sign in to your environment
login-AzureRmAccount `
  -EnvironmentName "AzureStackAdmin"

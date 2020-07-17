<#
.SYNOPSIS
.DESCRIPTION
.EXAMPLE
#>

Param(
  [parameter(mandatory = $true)][String]$fqdn,
  [parameter(mandatory = $false)][String]$tenant
)

$ErrorActionPreference = "stop"

Write-Output "Installing modules"

$modules = Get-module

Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
if ($null -eq ($modules | Where-Object { $_.Name -eq "Az.BootStrapper"})){
  write-output "Try to install Az.BootStrapper"
  Install-Module -Name Az.BootStrapper -Force -AllowPrerelease -Scope CurrentUser
} else {
  write-output "Az.BootStrapper is already installed"
}

write-output "Install-AzProfile -Profile 2019-03-01-hybrid -Force"
Install-AzProfile -Profile 2019-03-01-hybrid -Force

if ($null -eq ($modules | Where-Object { $_.Name -eq "AzureStack"})){
  write-output "Try to install AzureStack"
  Install-Module -Name AzureStack -AllowPrerelease -Scope CurrentUser
} else {
  write-output "AzureStack is already installed"
}

$ArmEndpoint = "https://adminmanagement." + $fqdn

# Register an AzureRM environment that targets your Azure Stack instance
Add-AzEnvironment `
  -Name "AzureStackAdmin" `
  -ArmEndpoint $ArmEndpoint

Write-Output "Try login to $ArmEndpoint. Please input your account to login Azure Stack Admin Portal"
# Sign in to your environment
if ($tenant -ne $Null){
  Login-AzAccount -EnvironmentName "AzureStackAdmin" -Tenant
} else {
  Login-AzAccount -EnvironmentName "AzureStackAdmin" -Tenant "$tenant.onmicrosoft.com"
}

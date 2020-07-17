$ErrorActionPreference = "stop"

Try {
    Get-AzsLocation | Out-Null
} Catch {
    Write-Error "Please login Azure Stack before you execute this script" 
    Break 
}

$instances = Get-AzsInfrastructureRoleInstance
$instances | 
    Select-Object Name, `
        State, `
        @{Label="Cores"; Expression={$_.NumberOfCores}}, `
        @{Label="MemoryGb"; Expression={$_.SizeMemoryInGB}}, `
        @{Label="ScaleUnit"; Expression={[regex]::Match($_.ScaleUnit,"scaleUnits/(.*)").Groups[1].value}}, `
        @{Label="ScaleUnitNode"; Expression={[regex]::Match($_.ScaleUnitNode,"scaleUnitNodes/(.*)").Groups[1].value}}

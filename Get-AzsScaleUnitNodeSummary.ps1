$ErrorActionPreference = "stop"

Try {
    Get-AzsLocation | Out-Null
} Catch {
    Write-Error "Please login Azure Stack before you execute this script" 
    Break 
}

$nodes = Get-AzsScaleUnitNode
$nodes |
    Select-Object Name, ScaleUnitName, ScaleUnitNodeStatus, PowerState, `
        @{Label="Cores"; Expression={$_.CapacityOfCores}}, `
        @{Label="MemoryGb"; Expression={$_.CapacityOfMemoryInGB}}, `
        Vendor,Model,SerialNumber,BiosVersion,BmcAddress

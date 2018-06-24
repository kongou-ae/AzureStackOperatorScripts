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
        @{Label="Cores"; Expression={$_.Capacity.Cores}}, `
        @{Label="MemoryGb"; Expression={$_.Capacity.MemoryGb}}, `
        Vendor,Model,SerialNumber,BiosVersion,BmcAddress

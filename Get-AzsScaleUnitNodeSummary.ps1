$ErrorActionPreference = "stop"
$nodes = Get-AzsScaleUnitNode
$nodes |
    Select-Object Name, ScaleUnitName, ScaleUnitNodeStatus, PowerState, `
        @{Label="Cores"; Expression={$_.Capacity.Cores}}, `
        @{Label="MemoryGb"; Expression={$_.Capacity.MemoryGb}}, `
        Vendor,Model,SerialNumber,BiosVersion,BmcAddress

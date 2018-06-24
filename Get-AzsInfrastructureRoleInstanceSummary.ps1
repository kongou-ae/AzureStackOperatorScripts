$ErrorActionPreference = "stop"
$instances = Get-AzsInfrastructureRoleInstance
$instances | 
    Select-Object Name, `
        State, `
        @{Label="Cores"; Expression={$_.Size.Cores}}, `
        @{Label="MemoryGb"; Expression={$_.Size.MemoryGb}}, `
        @{Label="ScaleUnit"; Expression={[regex]::Match($_.ScaleUnit,"scaleUnits/(.*)").Groups[1].value}}, `
        @{Label="ScaleUnitNode"; Expression={[regex]::Match($_.ScaleUnitNode,"scaleUnitNodes/(.*)").Groups[1].value}}
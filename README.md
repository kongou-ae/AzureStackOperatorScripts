# AzureStackOperatorScripts

These scripts will help Azure Stack operator in when they operate Azure Stack.

## Get-AzsScaleUnitNodeSummary.ps1

```
PS> Get-AzsScaleUnitNodeSummary.ps1 | ft *
[D] Do not run  [R] Run once  [S] Suspend  [?] Help (default is "D"): R

Name                  ScaleUnitName   ScaleUnitNodeStatus PowerState Cores   MemoryGb Vendor Model SerialNumber BiosVersion BmcAddress
----                  -------------   ------------------- ---------- -----   -------- ------ ----- ------------ ----------- ----------
local/WIN-xxxxxxxxxxx local/s-cluster RequiresRemediation Running       32 511.898438
```

## Get-AzsInfrastructureRoleInstanceSummary.ps1

```
PS> .\Get-AzsInfrastructureRoleInstanceSummary.ps1 | ft *

Name               State   Cores MemoryGb ScaleUnit ScaleUnitNode
----               -----   ----- -------- --------- -------------
local/AzS-ACS01    Running     2        8 s-cluster WIN-xxxxxxxxxxx
local/AzS-ADFS01   Running     2        2 s-cluster WIN-xxxxxxxxxxx
local/AzS-BGPNAT01 Running     2        2 s-cluster WIN-xxxxxxxxxxx
local/AzS-CA01     Running     2        1 s-cluster WIN-xxxxxxxxxxx
local/AzS-Gwy01    Running     4        2 s-cluster WIN-xxxxxxxxxxx
local/AzS-NC01     Running     2        4 s-cluster WIN-xxxxxxxxxxx
local/AzS-SLB01    Running     4        2 s-cluster WIN-xxxxxxxxxxx
local/AzS-Sql01    Running     2        4 s-cluster WIN-xxxxxxxxxxx
local/AzS-WAS01    Running     2        4 s-cluster WIN-xxxxxxxxxxx
local/AzS-WASP01   Running     2        8 s-cluster WIN-xxxxxxxxxxx
local/AzS-Xrp01    Running     4        8 s-cluster WIN-xxxxxxxxxxx
```

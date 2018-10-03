# AzureStackOperatorScripts

These scripts help Azure Stack operator in when they operate Azure Stack.

## Download-AzsMarkteplaceItem.ps1

Download the marletplace item by PowerShell.

## Get-AzsScaleUnitNodeSummary.ps1

show the status of nodes simply

```
PS> .\Get-AzsScaleUnitNodeSummary.ps1 | ft *

Name                  ScaleUnitName   ScaleUnitNodeStatus PowerState Cores   MemoryGb Vendor Model SerialNumber BiosVersion BmcAddress
----                  -------------   ------------------- ---------- -----   -------- ------ ----- ------------ ----------- ----------
local/WIN-xxxxxxxxxxx local/s-cluster RequiresRemediation Running       32 511.898438
```

## Get-AzsInfrastructureRoleInstanceSummary.ps1

show the status of infrastructure role instances simply


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

## Get-AzsUpdateProgress.ps1

Show the status of update as GridView.

## Get-AzsValidationSummary.ps1

Download the latest AzureStack_Validation_Summary.html.

## Login-AzsAdminRmAccount.ps1

Install powershell modules and login your Azure Stack stamp.

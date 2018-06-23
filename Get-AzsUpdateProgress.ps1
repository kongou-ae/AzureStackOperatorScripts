Param(
  [parameter(mandatory = $true)][String]$ercs,
  [parameter(mandatory = $true)][String]$Username
)

$ErrorActionPreference = "Stop" 

$cred = Get-Credential -UserName $Username -Message "Please input password"

$pepSession = New-PSSession -ComputerName $ercs -ConfigurationName PrivilegedEndpoint -Credential $cred
[xml]$update = Invoke-Command -Session $pepSession -ScriptBlock { Get-AzureStackUpdateStatus }

$root = @()
$update.Action.Steps.Step | foreach{
    $1stStep = $_ 
    if($1stStep){
        $root += $1stStep | Select-Object FullStepIndex,Name,Description,Status,` 
                            @{Label="StartTime"; Expression={Get-Date $_.StartTimeUtc -Format "yyyy-MM-dd HH:mm:ss"}}, `
                            @{Label="EndTime"; Expression={Get-Date $_.EndTimeUtc -Format "yyyy-MM-dd HH:mm:ss"}}
    }
    $1stStep.Task.Action.Steps.Step | foreach {
        $2ndStep = $_
        if ($2ndStep){
            $root += $2ndStep | Select-Object FullStepIndex,Name,Description,Status,`
                                @{Label="StartTime"; Expression={Get-Date $_.StartTimeUtc -Format "yyyy-MM-dd HH:mm:ss"}}, `
                                @{Label="EndTime"; Expression={Get-Date $_.EndTimeUtc -Format "yyyy-MM-dd HH:mm:ss"}}
        }
        $2ndStep.Task.Action.Steps.Step | foreach {
            $3rdStep = $_
            if ($3rdStep){
                $root += $3rdStep | Select-Object FullStepIndex,Name,Description,Status, `
                                    @{Label="StartTime"; Expression={Get-Date $_.StartTimeUtc -Format "yyyy-MM-dd HH:mm:ss"}}, `
                                    @{Label="EndTime"; Expression={Get-Date $_.EndTimeUtc -Format "yyyy-MM-dd HH:mm:ss"}}
            }
        }
    }
}

$root | Out-GridView
Get-PSSession | Remove-PSSession

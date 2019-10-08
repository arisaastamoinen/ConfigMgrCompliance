Import-Module SQLPS


$sql = @"
SELECT DISTINCT 
    ComputerName 
FROM  
	vNonCompliantWorkstations
WHERE 
    LastScanTime > '2019-10-01'
"@

$computername = Invoke-Sqlcmd -ServerInstance localhost -Database '<ConfigMgr Database>' -Query $sql 

foreach ($x in $computername) {
    $dev = Get-CMDevice -Name $x.ComputerName -Fast -Verbose
    # Official Documentation would be nice
    Invoke-CMClientAction -Device $dev -ActionType ClientNotificationRequestMachinePolicyNow -Verbose
    Invoke-CMClientAction -Device $dev -ActionType ClientNotificationRequestHWInvNow -Verbose
    Invoke-CMClientAction -Device $dev -ActionType ClientNotificationSUMDeplEvalNow -Verbose
}

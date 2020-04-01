# Site details 
$SiteServer = 'ConfigMgrServer'
$SiteCode = 'AB1'

# Collection for Non-Compliant computers
$nonCompliant = 'Software Updates - Compliance Repairs'

Function Update-CMDeviceCollection { 
    <#  CREDITS:
        Ronni Pedersen 
        https://www.ronnipedersen.com/
    #>
 
    [CmdletBinding()] 
    [OutputType([int])] 
    Param ( 
        [Parameter(Mandatory=$true, 
            ValueFromPipelineByPropertyName=$true, 
            Position=0)] 
        $DeviceCollectionName
    ) 
 
    Begin { 
        Write-Verbose "$($DeviceCollectionName): Update Started" 
    } 
    Process { 
        $Collection = Get-CMDeviceCollection -Name $DeviceCollectionName 
        $null = Invoke-WmiMethod `
            -Path "ROOT\SMS\Site_$($SiteCode):SMS_Collection.CollectionId='$($Collection.CollectionId)'" `
            -Name RequestRefresh -ComputerName $SiteServer
    } 
    End { 
        While($(Get-CMDeviceCollection -Name $DeviceCollectionName | Select -ExpandProperty CurrentStatus) -eq 5) { 
            Write-Verbose "$($DeviceCollectionName): Updating..." 
            Start-Sleep -Seconds 5 
        } 
        Write-Verbose "$($DeviceCollectionName): Update Complete!" 
    } 
} 

# SQL Server PowerShell module is required
Import-Module SqlServer

# Query for non-compliant computers
$sql = @"
SELECT DISTINCT 
    ResourceID  
FROM  
	dbo.vNonCompliantWorkstations
"@

# Run SQL, string array of ResourceID's
$ResourceID = (Invoke-Sqlcmd -ServerInstance $SiteServer -Database CM_NE1 -Query $sql) | Select-Object -ExpandProperty ResourceID
Write-Output "Number of Non-Compliant workstations: $($ResourceID.Count)"

# Connect to SCCM drive
Set-Location "$($SiteCode):"

Write-Output "Clear the collection"
$member = Get-CMCollectionMember -CollectionName $nonCompliant 
Remove-CMCollectionDirectMembershipRule -CollectionName $nonCompliant -Resource $member -Confirm:$false -Force

Write-Output "Refresh collection"
Update-CMDeviceCollection -DeviceCollectionName $nonCompliant

Write-Output "Add new resources to the collection"
# Throw in the string array converting it to Int32 on the fly
# Couldn't get this working without ErrorAction parameter
Add-CMDeviceCollectionDirectMembershipRule -CollectionName $nonCompliant -ResourceId $ResourceID.ToInt32($null) -ErrorAction Continue

Write-Output "Refresh collection"
Update-CMDeviceCollection -DeviceCollectionName $nonCompliant

Write-Output "Invoke CMClientActions on collection"
Invoke-CMClientAction -CollectionName $nonCompliant -ActionType ClientNotificationRequestMachinePolicyNow # -Verbose
Invoke-CMClientAction -CollectionName $nonCompliant -ActionType ClientNotificationRequestHWInvNow # -Verbose
Invoke-CMClientAction -CollectionName $nonCompliant -ActionType ClientNotificationSUMDeplEvalNow # -Verbose
    
Write-Output "Done!"
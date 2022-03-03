## Define variables
$upn = "user's upn"
$roles = @("User Administrator", 
           "Global Reader")
$tenantID = ""
$reason = "Removing Azure AD roles from Corp account and adding them to ADM account."

$objectId = (Get-AzureADUser -SearchString $upn).objectId

## Start and End Date/Time of PIM Assignment
$schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
$schedule.Type = "Once"
$schedule.StartDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
$schedule.endDateTime = "2021-12-15T20:49:11.770Z"

foreach ($roleName in $roles) {

    $roleDefinition = Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $tenantID -Filter "DisplayName eq '$roleName'"
    Write-Output "Adding $($roleDefinition.DisplayName) role to user $upn."
    Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId 'aadRoles' -ResourceId $tenantID -RoleDefinitionId $($roleDefinition.Id) -SubjectId $objectId -Type 'adminAdd' -AssignmentState 'Active' -schedule $schedule -reason $reason
}
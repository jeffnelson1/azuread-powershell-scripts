## Define variables
$standardUpn = "standard upn"
$admUpn = "adm upn"
$tenantID = ""
$roles =@()
$objectId = (Get-AzureADUser -SearchString $standardUpn).objectId
$roleDefinitionIds = (Get-AzureADMSPrivilegedRoleAssignment -ProviderId "aadRoles" -ResourceId $tenantID -Filter "subjectId eq '$objectId'").RoleDefinitionId

foreach ($roleId in $roleDefinitionIds) {
    
    $roleName = (Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $tenantID -Filter "Id eq '$roleId'").DisplayName
    $roles += $roleName
}
Write-Output "Roles for $upn..."
Write-Output "Roles that will be assigned - $roles"

$reason = "Removing Azure AD roles from Corp account and adding them to ADM account."
$objectId = (Get-AzureADUser -SearchString $admUpn).objectId

## Start and End Date/Time of PIM Assignment
$schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
$schedule.Type = "Once"
$schedule.StartDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
$schedule.endDateTime = "2021-12-25T20:49:11.770Z"

foreach ($roleName in $roles) {

    $roleDefinition = Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $tenantID -Filter "DisplayName eq '$roleName'"
    Write-Output "Adding $($roleDefinition.DisplayName) role to user $admUpn."
    Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId 'aadRoles' -ResourceId $tenantID -RoleDefinitionId $($roleDefinition.Id) -SubjectId $objectId -Type 'adminAdd' -AssignmentState 'Active' -schedule $schedule -reason $reason
}
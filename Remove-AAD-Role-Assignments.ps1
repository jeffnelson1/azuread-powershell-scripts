## Define variables
$upn = "user's upn"
$tenantID = ""

$objectId = (Get-AzureADUser -SearchString $upn).objectId
$roleAssignments = Get-AzureADMSPrivilegedRoleAssignment -ProviderId "aadRoles" -ResourceId $tenantID -Filter "subjectId eq '$objectId'"
foreach ($assignment in $roleAssignments) {
    
    $roleName = Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $tenantID -Filter "Id eq '$($assignment.RoleDefinitionId)'"
    Write-Output "Removing $($roleName.DisplayName) role assignment for $($upn)"
    Remove-AzureADMSRoleAssignment -ID $assignment.Id
}
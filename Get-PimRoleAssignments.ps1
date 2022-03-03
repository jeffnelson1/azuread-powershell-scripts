## Define variables
$upn = "user's upn"
$tenantID = ""
$roles =@()
$objectId = (Get-AzureADUser -SearchString $upn).objectId
$roleDefinitionIds = (Get-AzureADMSPrivilegedRoleAssignment -ProviderId "aadRoles" -ResourceId $tenantID -Filter "subjectId eq '$objectId'").RoleDefinitionId

foreach ($roleId in $roleDefinitionIds) {
    
    $roleName = (Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $tenantID -Filter "Id eq '$roleId'").DisplayName
    $roles += $roleName
}
Write-Output "Roles for $upn..."
$roles
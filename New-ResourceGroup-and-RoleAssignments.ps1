## Defining parameters

param (
    [Parameter(Mandatory)][string]$resourceGroupNames,
    [Parameter(Mandatory)][string]$tag_EmployeeId,
    [Parameter(Mandatory)][string]$securityPrincipals,
    [Parameter(Mandatory)][string]$tenantID,
    [Parameter(Mandatory)][string]$subscriptionId,
    [Parameter(Mandatory)][string]$azureSpId,
    [Parameter(Mandatory)][string]$azureSpSec,
    [Parameter(Mandatory)][string]$azureRole,
    [Parameter(Mandatory)][string]$primaryRegion
)

## Importing PowerShell Modules
Import-Module AzureAD
Import-Module Az.Accounts
Import-Module Az.Compute

## Parse resourceGroupName variable into array
$resourceGroupNameArray = $resourceGroupNames.Split(",")

## Parse resourceGroupName variable into array
$securityPrincipalArray = $securityPrincipals.Split(",")

## Creating a hashtable to store tags for the resource groups
$tags = @{
    'Employee ID'         = $tag_EmployeeId
}

## Disabling autosaving of Azure credentials
Disable-AzContextAutoSave

## Defining credentials for the Azure Service Principal
$azureSpPass = ConvertTo-SecureString $azureSpSec -AsPlainText -Force
$azureSpCreds = New-Object System.Management.Automation.PSCredential ($azureSpId, $azureSpPass)

## Authenticate to Azure with service principal
Write-Output "Connecting to Azure..."
Connect-AzAccount -ServicePrincipal -Credential $azureSpCreds -Tenant $tenantID

## Set Azure context to point to a specific subscription
Set-AzContext -SubscriptionId $subscriptionId

## Get current Azure context
$context = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile.DefaultContext

## Get an Azure AD token
$aadToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id.ToString(), `
$null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, "https://graph.windows.net").AccessToken

## Connect to Azure AD with token
Write-Output "Connecting to Azure AD..."
Connect-AzureAD -AadAccessToken $aadToken -AccountId $context.Account.Id -TenantId $tenantID

## Checking if the resource group exists in the primary region.  If not, it will create the resource group.

foreach ($resourceGroupName in $resourceGroupNameArray) {
    
    Write-Output "[Checking if $resourceGroupName currently exists.]"
    Get-AzResourceGroup -Name $resourceGroupName -ErrorVariable notPresent -ErrorAction SilentlyContinue

    if ($notPresent) {
        Write-Output "[Resource Group $resourceGroupName was not found.  Creating new Resource Group now.]"
        New-AzResourceGroup -Name $resourceGroupName -Location $primaryRegion -Tags $tags
    }
    else {
        Write-Output "[Resource Group $resourceGroupName already exists.  Proceeding with deployment.]"
    }

## This foreach loop will assign all the Azure roles assignments that were defined in the parameters section
    Write-Output "Assigning permissions..."

    foreach ($securityPrincipal in $securityPrincipalArray) {
        
        $azureAdUserObId = (Get-AzureADUser -SearchString $securityPrincipal).ObjectId
        $azureAdGroupObId = (Get-AzureADGroup -SearchString $securityPrincipal).ObjectId
        $azureAdSpObId = (Get-AzureADServicePrincipal -SearchString $securityPrincipal | Where-Object AppDisplayName -EQ $securityPrincipal).ObjectId

        if ($null -ne $azureAdUserObId ) {
       
            Write-Output "$securityPrincipal is a user.  Assigning the $azureRole role to resource group $resourceGroupName."
            New-AzRoleAssignment -ObjectId $azureAdUserObId -ResourceGroupName $resourceGroupName -RoleDefinitionName $azureRole
        }
        elseif ($null -ne $azureAdGroupObId) {
        
            Write-Output "$securityPrincipal is a group.  Assigning the $azureRole role to resource group $resourceGroupName."
            New-AzRoleAssignment -ObjectId $azureAdGroupObId -ResourceGroupName $resourceGroupName -RoleDefinitionName $azureRole
        }
        elseif ($null -ne $azureAdSpObId) {
        
            Write-Output "$securityPrincipal is a security principal.  Assigning the $azureRole role to resource group $resourceGroupName."
            New-AzRoleAssignment -ObjectId $azureAdSpObId -ResourceGroupName $resourceGroupName -RoleDefinitionName $azureRole
        }
        else {

            Write-Output "$securityPrincipal is not found in Azure AD.  Please investigate."
        }
    }
}
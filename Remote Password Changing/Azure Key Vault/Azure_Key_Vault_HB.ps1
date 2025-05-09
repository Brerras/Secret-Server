<#
.SYNOPSIS 
Validates whether the current value of a secret in Azure Key Vault matches the current password using the latest version of the secret.

.DESCRIPTION
The script:
1. Authenticates to Azure using client credentials to obtain an OAuth 2.0 token.
2. Fetches all versions of a specified secret from Azure Key Vault.
3. Identifies the latest version and retrieves its value.
4. Validates the retrieved secret value against the provided current password.
5. Introduces a sleep delay to allow Azure Key Vault to propagate changes before validation.
6. Throws an error for failures or completes without error for successful validation.

.PARAMETERS
$args[0] - Client ID: The Azure AD application/client ID for authentication.
$args[1] - Client Secret: The client secret associated with the Azure AD application.
$args[2] - Tenant ID: The Azure AD tenant ID for authentication.
$args[3] - Vault Name: The name of the Azure Key Vault containing the secret.
$args[4] - Secret Name: The name of the secret to validate.
$args[5] - Current Password: The current password to validate against the Azure Key Vault secret.

.EXAMPLE
.\Validate-AzureKeyVaultSecret.ps1 `
    $client-id `
    $client-secret `
    $tenant-id `
    $vault `
    $username `
    $password
#>

# Read arguments
$clientID = $args[0]        # Azure AD application/client ID
$clientSecret = $args[1]    # Azure AD application client secret
$tenantID = $args[2]        # Azure AD tenant ID
$AKVaultName = $args[3]     # Azure Key Vault name
$secretName = $args[4]      # Secret name to validate
$currentPassword = $args[5] # Current password to validate

# Construct request body for token retrieval
$ReqTokenBody = @{
    Grant_Type    = "client_credentials"
    Scope         = "https://vault.azure.net/.default"
    client_Id     = $clientID
    Client_Secret = $clientSecret
}

# Fetch OAuth token
try {
    $TokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantID/oauth2/v2.0/token" -Method POST -Body $ReqTokenBody
} catch {
    throw "Token retrieval failed: $_"
}

# Prepare headers for API requests
$headers = @{
    Authorization = "Bearer $($TokenResponse.access_token)"
    "Content-Type" = "application/json"
}

# Add a sleep delay to allow Azure Key Vault to propagate changes
Start-Sleep -Seconds 5

# Fetch all versions of the secret
$versionsURL = "https://$AKVaultName.vault.azure.net/secrets/$secretName/versions?api-version=7.2"

try {
    $VersionsResponse = Invoke-RestMethod -Headers $headers -Uri $versionsURL -Method GET
    $LatestVersion = $VersionsResponse.value | Sort-Object { $_.attributes.updated } -Descending | Select-Object -First 1
    $LatestVersionID = ($LatestVersion.id -split '/')[-1]  # Extract only the version ID
} catch {
    throw "Failed to fetch secret versions: $_"
}

# Construct the URL for the latest version of the secret
$latestSecretURL = "https://$AKVaultName.vault.azure.net/secrets/$secretName/$LatestVersionID/?api-version=7.2"

# Fetch the value of the latest version
try {
    $LatestSecretResponse = Invoke-RestMethod -Headers $headers -Uri $latestSecretURL -Method GET
    $SecretValue = $LatestSecretResponse.value.Trim()
} catch {
    throw "Failed to fetch the latest version of the secret: $_"
}

# Explicitly validate the retrieved value
$SecretValueTrimmed = [string]$SecretValue.Trim()
$currentPasswordTrimmed = [string]$currentPassword.Trim()

if ($SecretValueTrimmed -ceq $currentPasswordTrimmed) {
    # Validation successful
    Write-Output "Validation successful: Secret matches the provided password."
} else {
    throw "Validation failed: Secret does not match the provided password."
}

# Completion
Write-Output "Validation script completed successfully."

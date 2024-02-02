# this script isnt working right and i cant figure out why... it only processes half the pages???
# make a PR and fix it, maybe
# Cloudflare API credentials
$apiKey = "<CF_API_KEY>"
$email = "<CF_EMAIIL>"

# Function to delete access rule by ID
function DeleteAccessRule($ruleId) {
    $deleteEndpoint = "https://api.cloudflare.com/client/v4/user/firewall/access_rules/rules/$ruleId"
    $deleteResponse = Invoke-RestMethod -UseBasicParsing -Uri $deleteEndpoint -Headers $headers -Method Delete

    # Check if the delete request was successful
    if ($deleteResponse.success -eq $true) {
        Write-Host "Access rule with ID $ruleId deleted successfully."
    } else {
        Write-Host "Failed to delete access rule with ID $ruleId. Error: $($deleteResponse.errors[0].message)"
    }
}

# Function to handle paginated response
function ProcessPaginatedResponse($response) {
    # Log the number of rules on the current page
    Write-Host "Processing page $($response.result_info.page) with $($response.result_info.count) access rules."

    # Loop through current page
    foreach ($rule in $response.result) {
        DeleteAccessRule $rule.id
    }

    # Check if there are more pages
    if ($response.result_info.page -lt $response.result_info.total_pages) {
        $nextPage = $response.result_info.page + 1

        try {
            # Retrieve next page
            $nextPageResponse = Invoke-RestMethod -UseBasicParsing -Uri "https://api.cloudflare.com/client/v4/user/firewall/access_rules/rules?page=$nextPage" -Headers $headers -Method Get
        } catch {
            Write-Host "Failed to retrieve next page. Error: $_"
            return
        }

        # Recursively process the next page
        ProcessPaginatedResponse $nextPageResponse
    }
}

# Headers for API request
$headers = @{
    "X-Auth-Email" = $email
    "X-Auth-Key" = $apiKey
    "Content-Type" = "application/json"
}

# Get initial page of access rules
$response = Invoke-RestMethod -UseBasicParsing -Uri "https://api.cloudflare.com/client/v4/user/firewall/access_rules/rules" -Headers $headers -Method Get
Write-Host $response.result_info.total_pages
# Check if the request was successful
if ($response.success -eq $true) {
    ProcessPaginatedResponse $response
} else {
    Write-Host "Failed to retrieve access rules. Error: $($response.errors[0].message)"
}
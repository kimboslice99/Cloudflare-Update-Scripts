$email = "<EMAIL>"
$ApiKey = "<API_KEY>"
$ZoneID = "<ZONEID>"
$certificateCN = "CN=*.example.com"

$response = Invoke-RestMethod -UseBasicParsing -Uri "https://api.cloudflare.com/client/v4/zones/$ZoneID/dns_records?type=TLSA" -Method GET -Headers @{'Accept'='application/json';'X-Auth-Email'="$email";'X-Auth-Key'="$apikey"} -ContentType "application/json" 

$cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Subject -eq $certificateCN }
if ($cert) {
    $sha256 = $cert.GetCertHash('SHA256')
    $Thumbprint = [System.BitConverter]::ToString($sha256) -replace '-'
} else {
    exit 1;
}
foreach($result in $response.result){
    $body = @{
        "type"="TLSA"
        "name"=$result.name
        "data"=@{
            "usage"=$result.data.usage
            "selector"=$result.data.selector
            "matching_type"=$result.data.matching_type
            "certificate"=$Thumbprint
        }
    } | ConvertTo-Json

    Invoke-RestMethod -UseBasicParsing -Uri "https://api.cloudflare.com/client/v4/zones/$ZoneID/dns_records/$($result.id)" -Method Put `
        -Headers @{"X-Auth-Email"="$email";"X-Auth-Key"="$ApiKey";'Accept'='application/json';} -ContentType 'application/json' -Body $body
}

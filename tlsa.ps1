$email = "<CF_EMAIL>"
$ApiKey = "<CF_APIKEY>"
$ZoneID = "<ZONEID>"
$certificatePath = "<PATH_TO_CERTIFICATE>"

if((Test-Path -Path $certificatePath) -eq $false){
    throw "Certificate not found or readable"
}

if ((Get-Command "openssl" -ErrorAction SilentlyContinue) -eq $null) {
    throw "openssl not found"
}

$cloudflareResponse = Invoke-RestMethod -UseBasicParsing -Uri "https://api.cloudflare.com/client/v4/zones/$ZoneID/dns_records?type=TLSA" -Method GET `
        -Headers @{'Accept'='application/json';'X-Auth-Email'="$email";'X-Auth-Key'="$apikey"} -ContentType "application/json"
        
# usage 3 selector 1 type 1
# this is the most secure configuration and the most stable provided you reuse your private key
$opensslResponse = openssl x509 -in $certificatePath -pubkey -noout | openssl ec -pubin -outform der | openssl dgst -sha256
$thumbprint = $opensslResponse.Split(' ')[1]

# loop over each TLSA record
foreach($result in $cloudflareResponse.result){
    if($result.data.certificate -eq $thumbprint){
        Write-Host "No change, update not required $($result.name)"
        continue
    }
    $body = @{
        "type"="TLSA"
        "name"=$result.name
        "data"=@{
            "usage"=$result.data.usage
            "selector"=$result.data.selector
            "matching_type"=$result.data.matching_type
            "certificate"=$thumbprint
        }
    } | ConvertTo-Json

    Invoke-RestMethod -UseBasicParsing -Uri "https://api.cloudflare.com/client/v4/zones/$ZoneID/dns_records/$($result.id)" -Method Put `
        -Headers @{"X-Auth-Email"="$email";"X-Auth-Key"="$ApiKey";'Accept'='application/json';} -ContentType 'application/json' -Body $body
}

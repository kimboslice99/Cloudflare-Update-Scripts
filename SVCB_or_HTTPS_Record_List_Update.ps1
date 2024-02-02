$type = "SVCB" # or HTTPS
$email = "<CF_EMAIL>"
$apikey = "<CF_API_KEY>"
$ZoneID = "<CF_ZONE_ID>"
$iplink = "https://ipv4.seeip.org"
$ipV6link = "https://ipv6.seeip.org"
$date = get-date -format yyyy-MM-ddTHH-mm-ss-ff
#list all records of $type
$response = Invoke-RestMethod -UseBasicParsing -Uri "https://api.cloudflare.com/client/v4/zones/$ZoneID/dns_records?type=$type" -Method GET -Headers @{'Accept'='application/json';'X-Auth-Email'="$email";'X-Auth-Key'="$apikey"} -ContentType "application/json" 

#get ip address
Try {
    $CurrentIP=Invoke-RestMethod -UseBasicParsing -Uri "$iplink"
    $CurrentIPV6=Invoke-RestMethod -UseBasicParsing -Uri "$ipV6link"
} Catch {
    $message = "$date No connection! quitting"
    $message | Out-File $PSScriptRoot/logfile.$ZoneID.$type.txt -Encoding utf8 -Append
    Exit
}
if(!$CurrentIP -or !$CurrentIPv6){
    $message = "$date API Error! quitting"
    $message | Out-File $PSScriptRoot/logfile.$ZoneID.$type.txt -Encoding utf8 -Append
    Exit
}

$result = $response.result
foreach($r in $result){
    $data = @{
        "type"=$type;
        "name"=$r.name;
        "data"=@{
            "priority"=[int]$r.data.priority;
            "target"=$r.data.target;
            "value"="alpn=`"h3,h2,http/1.1`" ipv4hint=`"$CurrentIP`" ipv6hint=`"$CurrentIPv6`"";
        }
    } | ConvertTo-Json
    Invoke-RestMethod -UseBasicParsing -Uri "https://api.cloudflare.com/client/v4/zones/$ZoneID/dns_records/$($r.id)" -Method PUT  -Headers @{'Accept'='application/json';'X-Auth-Email'="$email";'X-Auth-Key'="$apikey"} -ContentType 'application/json' -Body $data
    
    $message = "$date Updated $($r.name) with $data"
    $message | Out-File $PSScriptRoot/logfile.$ZoneID.$type.txt -Encoding utf8 -Append
}
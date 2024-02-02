$type = "A" # this can be A or AAAA
$email = "<CF_EMAIL>"
$apikey = "<CF_API_KEY>"
$ZoneID = "<CF_ZONE_ID>"
$iplink = "https://ipv4.seeip.org"
$date = get-date -format yyyy-MM-ddTHH-mm-ss-ff
#list all records of $type
$response = Invoke-RestMethod -UseBasicParsing -Uri "https://api.cloudflare.com/client/v4/zones/$ZoneID/dns_records?type=$type" -Method GET -Headers @{'Accept'='application/json';'X-Auth-Email'="$email";'X-Auth-Key'="$apikey"} -ContentType "application/json" 

#get ip address
Try {
	$CurrentIP=Invoke-RestMethod -UseBasicParsing -Uri "$iplink"
} Catch {
	$message = "$date No connection! quitting"
	Write-Output $message | Out-File $PSScriptRoot/logfile.$ZoneID.$type.txt -Encoding utf8 -Append
	Exit
}
if(!$CurrentIP){
	$message = "$date API Error! quitting"
	Write-Output $message | Out-File $PSScriptRoot/logfile.$ZoneID.$type.txt -Encoding utf8 -Append
	Exit
}
# loop through and check each to see if ip differs
$result = $response.result
foreach($r in $result){
    If ($CurrentIP -eq $r.content) {
	    $message = "$date $($r.name) IP Same! (CurrentIP=$CurrentIP Record content=$($r.content))"
	    $message | Out-File $PSScriptRoot/logfile.$ZoneID.$type.txt -Encoding utf8 -Append
	    Continue # on to the next
    } Else {
	    $message = "$date $($r.name) IP Changed! (CurrentIP=$CurrentIP Record content=$($r.content))"
	    $message | Out-File $PSScriptRoot/logfile.$ZoneID.$type.txt -Encoding utf8 -Append
    }
	# this works without explicitly converting to json
    # i suspect invoke-restmethod converts it automatically
    $body = @{
        "content"=$CurrentIP
        "name"=$r.name
        "proxied"=[bool]$r.proxied
        "type"=$type
        "ttl"=[int]$r.ttl
    } | ConvertTo-Json # but we'll convert anyways
	
	Invoke-RestMethod -UseBasicParsing -Uri "https://api.cloudflare.com/client/v4/zones/$ZoneID/dns_records/$($r.id)" -Method PUT  -Headers @{'Accept'='application/json';'X-Auth-Email'="$email";'X-Auth-Key'="$apikey"} -ContentType 'application/json' -Body $body

}
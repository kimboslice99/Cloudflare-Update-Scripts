# Cloudflare block IP
$ip=$args[0] # the first arg? 
$date=Get-Date
$logdate=Get-Date -format yyyy-MM-dd
$logfile="$PSScriptRoot\Ban_IP_AccountLevel-$logdate.log"
# Replace API key & Email address
$email="<CF_EMAIL>"
$apikey="<CF_API_KEY>"
Write-Output "$date Ban task started" >> $logfile
# Check for IP arg
if (!$args[0]) {
    Write-Output "$date Missing IP" >> $logfile
    Write-Output "$date Quitting..." >> $logfile
    exit
}
Write-Output "$date Attempting to block $ip" >> $logfile
# Check if IP is IPv4 or IPv6
if($ip -like '*:*:*') { $ipv="ip6" }
	else { $ipv="ip" }

$Body = @{
    'configuration' = @{
        'target'=$ipv
        'value'=$ip
    }
	'mode' = 'block'
    'notes' = "IPBan $date"
} | ConvertTo-Json
# Actual ban operation
Try {
    Invoke-WebRequest -UseBasicParsing -Uri "https://api.cloudflare.com/client/v4/user/firewall/access_rules/rules" -Method 'POST' -Body $Body -ContentType "application/json" -Headers @{'Accept'='application/json';'X-Auth-Email'="$email";'X-Auth-Key'="$apikey"}
} catch {
    Write-Output "$date $_" >> $logfile
    Write-Output "$date Cloudflare API ERROR, Quitting..." >> $logfile
    exit
}

Write-Output "$date Task Finished Blocked $ipv $ip" >> $logfile
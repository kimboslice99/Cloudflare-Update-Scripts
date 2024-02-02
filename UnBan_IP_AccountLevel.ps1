# Cloudflare unblock.ps1 
$ip=$args[0]
$date=Get-Date
$logdate=get-date -format yyyy-MM-dd
$logfile="$PSScriptRoot\UnBan_IP_AccountLevel-$logdate.log"
# Replace API key, Email address (AbuseIPDB API key not required)
$email="<CF_EMAIL>"
$cfapikey="<CF_API_KEY>"
$abuseipdbapikey="<ABUSEIPDB_API_KEY>"
$score = 20
Write-Output "$date Unblock task started..." >> $logfile
# Check for IP arg
if (!$args[0]) {
	Write-Output "$date Missing IP, Quitting..." >> $logfile
	exit
}
# Check against AbuseIPDB, Helpful so as not to unban known abusive IPs, Remove "<#" and "#>" to use this
<#
Write-Output "$date Checking AbuseIPDB Score of $ip" >> $logfile
Try {
	$confidence=Invoke-RestMethod -UseBasicParsing -Uri "https://api.abuseipdb.com/api/v2/check?ipAddress=$ip&maxAgeInDays=90" -Method 'GET' -Headers @{'Accept'='application/json';'Key'="$abuseipdbapikey"} |
        % {$_.data.abuseConfidenceScore }
} Catch {
	Write-Output "$date $_" >> $logfile
	Write-Output "$date AbuseIPDB API ERROR" >> $logfile
}
Write-Output "$date Confidence: $confidence" >> $logfile
If ($score –lt $confidence) {
	Write-Output "$date confidence above threshold, will not remove ban" >> $logfile
	exit
} Else {
	Write-Output "$date confidence below threshold, will remove ban" >> $logfile
}
#>
# Get ID of Cloudflare block rule
Try {
	$id=Invoke-RestMethod -UseBasicParsing -Uri "https://api.cloudflare.com/client/v4/user/firewall/access_rules/rules?page=1&per_page=20&mode=block&configuration.target=ip&configuration.value=$ip&match=all&order=mode&direction=desc" -Method 'GET' -Headers @{'Accept'='application/json';'X-Auth-Email'="$email";'X-Auth-Key'="$cfapikey"} |
              % {$_.result.id}
} catch {
	$message = $_
	Write-Output "$date $message" >> $logfile
	Write-Output "$date Cloudflare API ERROR, unable to get ID of block rule, Quitting..." >> $logfile
	exit
}
Write-Output "$date block rule id: $id" >> $logfile
# Remove ban
Try {
    Invoke-WebRequest -Uri "https://api.cloudflare.com/client/v4/user/firewall/access_rules/rules/$id" -Method 'DELETE' -Headers @{'Accept'='application/json';'X-Auth-Email'="$email";'X-Auth-Key'="$cfapikey"}
} catch {
    $message = $_
    Write-Output "$date $message" >> $logfile
    Write-Output "$date Cloudflare API ERROR, Quitting..." >> $logfile
    exit
}
Write-Output "$date Task Finished Unbanned $ip" >> $logfile
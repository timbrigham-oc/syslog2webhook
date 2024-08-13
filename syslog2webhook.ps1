# This is a script that listens for incoming syslog messages on UDP 514 and fowards them in raw format to a webhook.

# First create a syslog listener 
$listener = New-Object System.Net.Sockets.UdpClient
# This binds to loopback by default, switch to [System.Net.IPAddress]::Any if inbound access is needed
$listener.Client.Bind([System.Net.IPEndPoint]::new([System.Net.IPAddress]::Loopback, 514))
$endpoint = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)

# Create a webhook to send data to SIEM. 
$webhook = "https://xxxxxx/xxxxxxx/xxxx"
if ( $env:SIEMWebhookAuthToken -eq $null ) {
    Throw "SIEM webhook Auth Token not set, force quit."
}

# Read the webhook auth token from the environment
$webHookAuthToken = $env:SIEMWebhookAuthToken
# Create a header with the webhook auth token
$Headers = @{ Authorization = "Bearer $webHookAuthToken" }

# Listen for incoming syslog messages ad infinitum
while ($true) {
    $message = $listener.Receive([ref]$endpoint)
    # Decode the message to ascii text 
    $decodedMessage = [System.Text.Encoding]::ASCII.GetString($message)
    # Now forward the message to the webhook
    Invoke-RestMethod -Uri $webhook -Method Post -Body $decodedMessage -ContentType "application/json" -Headers $Headers 
    # And copy to the console
    Write-Host "$decodedMessage"
}
